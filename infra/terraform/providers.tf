# terraform {
#   required_version = ">= 1.5.0"
#   required_providers {
#     aws = { source = "hashicorp/aws", version = "~> 5.0" }
#   }
# }
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile   # <- uses the profile you configured with aws configure
}
