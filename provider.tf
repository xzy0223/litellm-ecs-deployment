terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
      random = {
        source = "hashicorp/random"
        version = "~> 3.0"
      }
    }
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use. Leave empty to use environment variables (AWS_ACCESS_KEY_ID, etc.) or instance role."
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "IPv4 CIDR blocks allowed to access the ALB. Defaults to open (not recommended for production)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ipv6_cidr_blocks" {
  description = "IPv6 CIDR blocks allowed to access the ALB."
  type        = list(string)
  default     = []
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}
