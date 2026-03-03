# AWS Secrets Manager for API keys and sensitive data

# Bedrock API Keys for LiteLLM load balancing
# After applying, set actual values via AWS Console or CLI:
#   aws secretsmanager put-secret-value --secret-id litellm/bedrock-api-key-1 --secret-string "your-key"
resource "aws_secretsmanager_secret" "bedrock_api_key_1" {
  name        = "litellm/bedrock-api-key-1"
  description = "Bedrock API Key 1 for LiteLLM load balancing"
}

resource "aws_secretsmanager_secret_version" "bedrock_api_key_1" {
  secret_id     = aws_secretsmanager_secret.bedrock_api_key_1.id
  secret_string = var.bedrock_api_key_1
}

resource "aws_secretsmanager_secret" "bedrock_api_key_2" {
  name        = "litellm/bedrock-api-key-2"
  description = "Bedrock API Key 2 for LiteLLM load balancing"
}

resource "aws_secretsmanager_secret_version" "bedrock_api_key_2" {
  secret_id     = aws_secretsmanager_secret.bedrock_api_key_2.id
  secret_string = var.bedrock_api_key_2
}

resource "aws_secretsmanager_secret" "bedrock_api_key_3" {
  name        = "litellm/bedrock-api-key-3"
  description = "Bedrock API Key 3 for LiteLLM load balancing"
}

resource "aws_secretsmanager_secret_version" "bedrock_api_key_3" {
  secret_id     = aws_secretsmanager_secret.bedrock_api_key_3.id
  secret_string = var.bedrock_api_key_3
}

# Dynamically generated LiteLLM keys (regenerated on each fresh deploy)
resource "random_id" "litellm_master_key" {
  byte_length = 32
}

resource "random_id" "litellm_salt_key" {
  byte_length = 32
}

resource "random_password" "ui_password" {
  length           = 16
  special          = true
  override_special = "!@#%^&*"
}

# Output credentials after deployment
output "litellm_master_key" {
  description = "LiteLLM Master Key (use this as Bearer token for API calls)"
  value       = "sk-${random_id.litellm_master_key.hex}"
  sensitive   = true
}

output "ui_password" {
  description = "LiteLLM UI admin password"
  value       = random_password.ui_password.result
  sensitive   = true
}
