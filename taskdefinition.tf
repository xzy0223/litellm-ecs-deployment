resource "aws_ecs_task_definition" "litellm_task" {
  family                   = "litellm_task"
  requires_compatibilities = ["FARGATE"] #EC2
  network_mode            = "awsvpc"
  cpu                     = 4096
  memory                  = 8192
  execution_role_arn      = aws_iam_role.litellm_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "litellm_task",
    "image": "${aws_ecr_repository.litellm_dev.repository_url}:latest",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 4000,
        "hostPort": 4000,
        "protocol": "tcp"
      }
    ],
    "memory": 8192,
    "cpu": 4096,
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/litellm",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "environment": [
      {
        "name": "LITELLM_SALT_KEY",
        "value": "sk-21341412"
      },
      {
        "name": "LITELLM_MASTER_KEY",
        "value": "sk-1234"
      },
      {
        "name": "DATABASE_URL",
        "value": "your-postgres-db-url"
      }
    ],
    "secrets": [
      {
        "name": "AWS_ACCESS_KEY_ID",
        "valueFrom": "${aws_secretsmanager_secret.aws_credentials.arn}:AWS_ACCESS_KEY_ID::"
      },
      {
        "name": "AWS_SECRET_ACCESS_KEY",
        "valueFrom": "${aws_secretsmanager_secret.aws_credentials.arn}:AWS_SECRET_ACCESS_KEY::"
      },
      {
        "name": "OPENAI_API_KEY",
        "valueFrom": "${aws_secretsmanager_secret.openai_key.arn}:OPENAI_API_KEY::"
      },
      {
        "name": "ANTHROPIC_API_KEY",
        "valueFrom": "${aws_secretsmanager_secret.anthropic_key.arn}:ANTHROPIC_API_KEY::"
      },
      {
        "name": "AZURE_API_KEY",
        "valueFrom": "${aws_secretsmanager_secret.azure_key.arn}:AZURE_API_KEY::"
      },
      {
        "name": "GEMINI_API_KEY",
        "valueFrom": "${aws_secretsmanager_secret.gemini_key.arn}:GEMINI_API_KEY::"
      }
    ]
  }
]
  DEFINITION
}