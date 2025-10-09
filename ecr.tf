resource "aws_ecr_repository" "litellm_dev" {
  name = "litellm-dev"
  tags = {
    Name = "latest_ecr"
  }
}