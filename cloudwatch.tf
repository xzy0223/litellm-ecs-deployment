resource "aws_cloudwatch_log_group" "/ecs/litellm" {
  name              = "/ecs/litellm" # create this directory in aws cloudwatch
  retention_in_days = 30

  tags = {
    Name = "litellm-ecs-logs"
  }
}