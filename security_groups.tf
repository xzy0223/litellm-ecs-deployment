# Security Groups for LiteLLM ECS deployment

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "litellm-ecs-tasks-sg"
  description = "Security group for LiteLLM ECS tasks"
  vpc_id      = aws_vpc.main.id

  # No ingress rules here - only allow traffic from ALB via aws_security_group_rule.ecs_from_alb in alb.tf

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "litellm-ecs-tasks-sg"
  }
}
