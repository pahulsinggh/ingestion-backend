locals {
  backend_repo_name = "${var.proj}-backend"
}

# 1) ECR repo to host the backend container image
resource "aws_ecr_repository" "backend" {
  name                 = local.backend_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 2) IAM role that App Runner will assume to pull private images from ECR
resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.proj}-apprunner-ecr-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "build.apprunner.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach the managed policy that gives ECR access to App Runner
resource "aws_iam_role_policy_attachment" "apprunner_ecr_access_attach" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# (We will add aws_apprunner_service for IMAGE mode in Step III after we push an image)
output "ecr_repo_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "apprunner_ecr_access_role_arn" {
  value = aws_iam_role.apprunner_ecr_access.arn
}