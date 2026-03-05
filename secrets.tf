# AWS Secrets Manager for API keys and sensitive data

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
