resource "aws_ecs_task_definition" "litellm_task" {
  family                   = "litellm_task"
  requires_compatibilities = ["FARGATE"] #EC2
  network_mode            = "awsvpc"
  cpu                     = var.ecs_cpu
  memory                  = var.ecs_memory
  execution_role_arn      = aws_iam_role.litellm_task_execution_role.arn
  task_role_arn           = aws_iam_role.litellm_task_role.arn

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
    "memory": ${var.ecs_memory},
    "cpu": ${var.ecs_cpu},
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/litellm",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    },
    "environment": [
      {
        "name": "LITELLM_SALT_KEY",
        "value": "sk-${random_id.litellm_salt_key.hex}"
      },
      {
        "name": "LITELLM_MASTER_KEY",
        "value": "sk-${random_id.litellm_master_key.hex}"
      },
      {
        "name": "DATABASE_URL",
        "value": "postgresql://${aws_db_instance.litellm_db.username}:${urlencode(random_password.db_password.result)}@${aws_db_instance.litellm_db.endpoint}/${aws_db_instance.litellm_db.db_name}"
      },
      {
        "name": "REDIS_HOST",
        "value": "${aws_elasticache_cluster.litellm_redis.cache_nodes[0].address}"
      },
      {
        "name": "REDIS_PORT",
        "value": "${aws_elasticache_cluster.litellm_redis.port}"
      },
      {
        "name": "REDIS_URL",
        "value": "redis://${aws_elasticache_cluster.litellm_redis.cache_nodes[0].address}:${aws_elasticache_cluster.litellm_redis.port}"
      },
      {
        "name": "UI_USERNAME",
        "value": "admin"
      },
      {
        "name": "UI_PASSWORD",
        "value": "${random_password.ui_password.result}"
      },
      {
        "name": "STORE_MODEL_IN_DB",
        "value": "True"
      }
    ],
    "secrets": [
      {
        "name": "BEDROCK_API_KEY_1",
        "valueFrom": "${aws_secretsmanager_secret.bedrock_api_key_1.arn}"
      },
      {
        "name": "BEDROCK_API_KEY_2",
        "valueFrom": "${aws_secretsmanager_secret.bedrock_api_key_2.arn}"
      },
      {
        "name": "BEDROCK_API_KEY_3",
        "valueFrom": "${aws_secretsmanager_secret.bedrock_api_key_3.arn}"
      }
    ]
  }
]
  DEFINITION
}