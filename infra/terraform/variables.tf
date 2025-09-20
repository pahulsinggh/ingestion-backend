variable "region" {
  type    = string
  default = "us-east-1"
  description = "AWS region"
}

variable "aws_profile" {
  type    = string
  default = "pahul-dev"
  description = "Local AWS CLI/Terraform profile"
}

variable "proj" {
  type    = string
  default = "pahul-ingest-123"
  description = "Project name/prefix used for resource names"
}

# Leave empty for now; we'll fill with your backend URL later
variable "backend_url" {
  type        = string
  default     = ""
  description = "Lambda BACKEND_URL; set to App Runner /ingest/dry-run later"
}

# --- App Runner (source mode) vars ---
# Defaults added so terraform doesn't prompt during targeted plans.
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
  default     = "" # when empty, source-build App Runner is skipped via count = 0
  description = "CodeStar connection ARN (set only if using source-build App Runner)"
}

variable "subdir" {
  type        = string
  default     = ""
  description = "Optional subdirectory in the repo for source-build App Runner"
}
