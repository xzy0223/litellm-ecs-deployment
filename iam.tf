resource "aws_iam_role" "litellm_task_execution_role" {
  name               = "litellmTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "litellm_task_execution_role_policy" {
  role       = aws_iam_role.litellm_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "litellm_permissions" {
  name = "LiteLLMPermissionsPolicy"
  role = aws_iam_role.litellm_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # permissions for bedrock models
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:ListFoundationModels",
          "bedrock:GetFoundationModel"
        ]
        Resource = "*"
      },
      # s3 permissions for storage
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::litellm-very-cool-bucket",
          "arn:aws:s3:::litellm-very-cool-bucket/*"
        ]
      },
      # cloud watch permissions for logging and metrics
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      },
      # ecr permissions
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      # secrets manager permissions for api keys
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "${aws_secretsmanager_secret.aws_credentials.arn}",
          "${aws_secretsmanager_secret.openai_key.arn}",
          "${aws_secretsmanager_secret.anthropic_key.arn}",
          "${aws_secretsmanager_secret.azure_key.arn}",
          "${aws_secretsmanager_secret.gemini_key.arn}"
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}