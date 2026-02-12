# Security Groups for LiteLLM ECS deployment

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "litellm-ecs-tasks-sg"
  description = "Security group for LiteLLM ECS tasks"
  vpc_id      = aws_default_vpc.ecs-vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
