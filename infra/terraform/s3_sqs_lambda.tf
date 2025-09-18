########################
# S3 bucket (incoming) #
########################
resource "aws_s3_bucket" "incoming" {
  bucket = "${var.proj}-partner-incoming"  # must be globally unique
}

resource "aws_s3_bucket_versioning" "incoming" {
  bucket = aws_s3_bucket.incoming.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "incoming" {
  bucket                  = aws_s3_bucket.incoming.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################
# SQS main + DLQ       #
########################
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.proj}-ingest-dlq"
  message_retention_seconds = 1209600  # 14 days
}

resource "aws_sqs_queue" "main" {
  name                             = "${var.proj}-ingest"
  visibility_timeout_seconds       = 180
  message_retention_seconds        = 345600
  receive_wait_time_seconds        = 10
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn,
    maxReceiveCount     = 5
  })
}

# allow S3 to send to SQS
resource "aws_sqs_queue_policy" "s3_to_sqs" {
  queue_url = aws_sqs_queue.main.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid      = "AllowS3Send",
      Effect   = "Allow",
      Principal = { Service = "s3.amazonaws.com" },
      Action   = "sqs:SendMessage",
      Resource = aws_sqs_queue.main.arn,
      Condition = { ArnEquals = { "aws:SourceArn" = aws_s3_bucket.incoming.arn } }
    }]
  })
}

# S3 -> SQS notifications on new objects
resource "aws_s3_bucket_notification" "incoming_notify" {
  bucket = aws_s3_bucket.incoming.id
  queue {
    queue_arn = aws_sqs_queue.main.arn
    events    = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_sqs_queue_policy.s3_to_sqs]
}

########################
# Lambda + permissions #
########################
resource "aws_iam_role" "lambda_role" {
  name = "${var.proj}-ingest-worker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect="Allow", Principal={ Service="lambda.amazonaws.com" }, Action="sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "sqs_access" {
  name = "${var.proj}-lambda-sqs"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version="2012-10-17",
    Statement=[{
      Effect  = "Allow",
      Action  = ["sqs:ReceiveMessage","sqs:DeleteMessage","sqs:GetQueueAttributes","sqs:ChangeMessageVisibility"],
      Resource= [aws_sqs_queue.main.arn]
    }]
  })
}

# Lambda code zip will be created in Step 4 as lambda.zip
resource "aws_lambda_function" "worker" {
  function_name = "${var.proj}-ingest-worker"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  filename      = "${path.module}/lambda.zip"
  timeout       = 30
  memory_size   = 512
  environment {
    variables = {
      BACKEND_URL = var.backend_url
    }
  }
}

# SQS trigger with partial batch failure handling
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn                   = aws_sqs_queue.main.arn
  function_name                      = aws_lambda_function.worker.arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 2
  function_response_types            = ["ReportBatchItemFailures"]
}

########################
# Outputs              #
########################
output "bucket_name" { value = aws_s3_bucket.incoming.bucket }
output "queue_url"   { value = aws_sqs_queue.main.id }
output "lambda_name" { value = aws_lambda_function.worker.function_name }
