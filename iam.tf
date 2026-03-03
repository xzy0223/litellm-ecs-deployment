# ECS Task Execution Role (for ECS to pull images, write logs, etc.)
resource "aws_iam_role" "litellm_task_execution_role" {
  name               = "litellmTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "litellm_task_execution_role_policy" {
  role       = aws_iam_role.litellm_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "litellm_secrets_policy" {
  name = "LiteLLMSecretsPolicy"
  role = aws_iam_role.litellm_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.bedrock_api_key_1.arn,
          aws_secretsmanager_secret.bedrock_api_key_2.arn,
          aws_secretsmanager_secret.bedrock_api_key_3.arn,
        ]
      }
    ]
  })
}

# ECS Task Role (for application to access AWS services like Bedrock)
resource "aws_iam_role" "litellm_task_role" {
  name               = "litellmTaskRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy" "litellm_bedrock_permissions" {
  name = "LiteLLMBedrockPermissionsPolicy"
  role = aws_iam_role.litellm_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Bedrock permissions for Claude models
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
      # CloudWatch permissions for application logging and metrics
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
      # SSM permissions for ECS Exec
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
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