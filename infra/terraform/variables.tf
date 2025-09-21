variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  default     = "pahul-dev"
  description = "Local AWS CLI/Terraform profile"
}

variable "proj" {
  type        = string
  default     = "pahul-ingest-123"
  description = "Project name/prefix used for resource names"
}

# Lambda's backend URL (what the worker POSTs to)
variable "backend_url" {
  type        = string
  default     = "https://xmbng3n2jp.us-east-1.awsapprunner.com/ingest/dry-run"
  description = "Lambda will call this URL; later we'll switch to /ingest"
}

# --- App Runner (source mode) vars (kept for reference; not used in image mode) ---
variable "repo_url" {
  type        = string
  default     = "https://github.com/pahulsinggh/ingestion-backend"
  description = "GitHub repo URL for source-build App Runner (kept for reference)"
}

variable "repo_branch" {
  type        = string
  default     = "main"
  description = "Git branch for source-build App Runner (kept for reference)"
}

variable "gh_conn_arn" {
  type        = string
  default     = ""
  description = "CodeStar connection ARN (only if using source-build App Runner)"
}

variable "subdir" {
  type        = string
  default     = ""
  description = "Optional subdirectory in the repo (source-build App Runner)"
}

# --- Kafka (Confluent Cloud) ---
variable "spring_kafka_bootstrap_servers" {
  type        = string
  default     = ""
  description = "Confluent bootstrap servers, e.g. pkc-619z3.us-east1.gcp.confluent.cloud:9092"
}

variable "kafka_api_key" {
  type        = string
  default     = ""
  description = "Confluent Cloud API Key (username)"
}

variable "kafka_api_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Confluent Cloud API Secret (password)"
}

variable "ingest_topic" {
  type        = string
  default     = "ingestion-events"
  description = "Kafka topic to publish ingest events"
}
