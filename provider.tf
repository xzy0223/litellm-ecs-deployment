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

variable "ecs_cpu" {
  description = "ECS task CPU units (1024 = 1 vCPU)"
  type        = number
  default     = 4096
}

variable "ecs_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 8192
}

variable "rds_instance_class" {
  description = "RDS PostgreSQL instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "elasticache_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
}
