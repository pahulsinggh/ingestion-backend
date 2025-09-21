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

# 3) App Runner service (IMAGE mode) — uses ECR image :latest
resource "aws_apprunner_service" "backend_image" {
  service_name = "${var.proj}-backend-image"

  source_configuration {
    auto_deployments_enabled = true

    authentication_configuration {
      # Role we created in Step I for ECR pulls
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }

    image_repository {
      image_repository_type = "ECR"
      # Always pull the :latest image we push from GitHub Actions
      image_identifier      = "${aws_ecr_repository.backend.repository_url}:latest"

      image_configuration {
        port = "8080"

        # --- Inject Spring Kafka (Confluent Cloud) settings as env vars ---
        # Spring maps these automatically to spring.kafka.* properties.
        runtime_environment_variables = {
          # App basics
          SERVER_PORT = "8080"

          # Spring Kafka to Confluent Cloud
          SPRING_KAFKA_BOOTSTRAP_SERVERS            = var.spring_kafka_bootstrap_servers
          SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL = "SASL_SSL"
          SPRING_KAFKA_PROPERTIES_SASL_MECHANISM    = "PLAIN"
          # JAAS: username = API key, password = API secret (single line)
          SPRING_KAFKA_PROPERTIES_SASL_JAAS_CONFIG  = "org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${var.kafka_api_key}\" password=\"${var.kafka_api_secret}\";"

          # Your topic (overrides ingest.topic property)
          INGEST_TOPIC = var.ingest_topic
        }
      }
    }
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/actuator/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }
}

# Outputs
output "ecr_repo_url" {
  value = aws_ecr_repository.backend.repository_url
}

output "apprunner_ecr_access_role_arn" {
  value = aws_iam_role.apprunner_ecr_access.arn
}

output "apprunner_image_url" {
  value       = aws_apprunner_service.backend_image.service_url
  description = "Public URL for the App Runner service (image mode)"
}
