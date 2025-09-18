variable "region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "pahul-dev"
}

variable "proj" {
  type    = string
  default = "pahul-ingest-123"
}

# Leave empty for now; we'll fill with your backend URL later
variable "backend_url" {
  type    = string
  default = ""
}
