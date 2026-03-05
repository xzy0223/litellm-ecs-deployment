# Application Load Balancer
resource "aws_lb" "litellm_alb" {
  name               = "litellm-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id,
    aws_subnet.public_az3.id
  ]

  enable_deletion_protection = false
  idle_timeout               = 660

  tags = {
    Name = "litellm-alb"
  }
}

# Target Group for ECS Service
resource "aws_lb_target_group" "litellm_tg" {
  name        = "litellm-tg"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health/readiness"
    matcher             = "200,401"  # Accept both 200 and 401 - 401 means app is responding
  }

  tags = {
    Name = "litellm-target-group"
  }
}

# ALB Listener (HTTP)
resource "aws_lb_listener" "litellm_http" {
  load_balancer_arn = aws_lb.litellm_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.litellm_tg.arn
  }
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "litellm-alb-sg"
  description = "Security group for LiteLLM ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP from allowed IPs"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.allowed_cidr_blocks
    ipv6_cidr_blocks = var.allowed_ipv6_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "litellm-alb-sg"
  }
}

# Update ECS security group to allow traffic from ALB
resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 4000
  to_port                  = 4000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Allow traffic from ALB"
}

# Output ALB DNS name
output "alb_dns_name" {
  value       = aws_lb.litellm_alb.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "alb_url" {
  value       = "http://${aws_lb.litellm_alb.dns_name}"
  description = "Full URL to access LiteLLM"
}
