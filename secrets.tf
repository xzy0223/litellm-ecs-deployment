# AWS Secrets Manager for API keys and sensitive data
resource "aws_secretsmanager_secret" "aws_credentials" {
  name = "litellm/aws-credentials"
  description = "AWS credentials for LiteLLM Bedrock access"
}

resource "aws_secretsmanager_secret_version" "aws_credentials" {
  secret_id = aws_secretsmanager_secret.aws_credentials.id
  secret_string = jsonencode({
    AWS_ACCESS_KEY_ID     = "access key id"
    AWS_SECRET_ACCESS_KEY = "secret access key"
  })
}

resource "aws_secretsmanager_secret" "openai_key" {
  name = "litellm/openai-api-key"
  description = "OpenAI API key for LiteLLM"
}

resource "aws_secretsmanager_secret_version" "openai_key" {
  secret_id = aws_secretsmanager_secret.openai_key.id
  secret_string = jsonencode({
    OPENAI_API_KEY = "sk-..."
  })
}

resource "aws_secretsmanager_secret" "anthropic_key" {
  name = "litellm/anthropic-api-key"
  description = "Anthropic API key for LiteLLM"
}

resource "aws_secretsmanager_secret_version" "anthropic_key" {
  secret_id = aws_secretsmanager_secret.anthropic_key.id
  secret_string = jsonencode({
    ANTHROPIC_API_KEY = "sk-..."
  })
}

resource "aws_secretsmanager_secret" "azure_key" {
  name = "litellm/azure-api-key"
  description = "Azure OpenAI API key for LiteLLM"
}

resource "aws_secretsmanager_secret_version" "azure_key" {
  secret_id = aws_secretsmanager_secret.azure_key.id
  secret_string = jsonencode({
    AZURE_API_KEY = "azure-key-..."
  })
}

resource "aws_secretsmanager_secret" "gemini_key" {
  name = "litellm/gemini-api-key"
  description = "Google Gemini API key for LiteLLM"
}

resource "aws_secretsmanager_secret_version" "gemini_key" {
  secret_id = aws_secretsmanager_secret.gemini_key.id
  secret_string = jsonencode({
    GEMINI_API_KEY = "gemini-key-..."
  })
}