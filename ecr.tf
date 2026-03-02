resource "aws_ecr_repository" "litellm_dev" {
  name         = "litellm-dev"
  force_delete = true  # Automatically delete images when destroying repository

  tags = {
    Name = "latest_ecr"
  }
}