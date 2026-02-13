# LiteLLM Configuration Guide

## Overview

This deployment uses a **dynamic configuration approach** - no models are pre-configured in `config.yaml`. Instead, all models are configured through the Web UI, allowing flexible management without redeployment.

## Accessing the Web UI

After deployment, access the LiteLLM Web UI:

```
http://<alb-dns-name>/ui?master_key=<your-master-key>
```

Default master key: `sk-1234` (change in `taskdefinition.tf` → `LITELLM_MASTER_KEY`)

## Adding Models via Web UI

### Option 1: Bedrock Models (Recommended)

**Advantages:**
- ✅ Uses ECS Task IAM Role (no API keys needed)
- ✅ Automatic credential rotation
- ✅ Best security practices
- ✅ Supports Computer Use for Claude 3.7 Sonnet

**Steps:**
1. Go to Web UI → Models → Add Model
2. Configure:
   - **Model Name**: `claude-bedrock` (or any name)
   - **LiteLLM Model**: Select Bedrock provider
   - **Model ID**:
     - `bedrock/anthropic.claude-3-7-sonnet-20250219` (latest with Computer Use)
     - `bedrock/anthropic.claude-3-5-sonnet-20241022-v2:0`
     - `bedrock/anthropic.claude-3-opus-20240229-v1:0`
     - `bedrock/anthropic.claude-3-haiku-20240307-v1:0`
   - **AWS Region**: `us-west-2`, `us-east-1`, or other Bedrock-enabled regions
   - **Authentication**: Leave empty (uses IAM role automatically)

3. Save the model

**Important:** Ensure Bedrock model access is enabled in AWS Console:
```
AWS Console → Bedrock → Model access → Request access for Claude models
```

### Option 2: OpenAI Models

**Steps:**
1. Go to Web UI → Models → Add Model
2. Configure:
   - **Model Name**: `gpt-4` (or any name)
   - **LiteLLM Model**: `openai/gpt-4`
   - **API Key**: Your OpenAI API key
3. Save the model

### Option 3: Anthropic Direct API

**Steps:**
1. Go to Web UI → Models → Add Model
2. Configure:
   - **Model Name**: `claude-direct` (or any name)
   - **LiteLLM Model**: `anthropic/claude-3-5-sonnet-latest`
   - **API Key**: Your Anthropic API key
3. Save the model

### Option 4: Azure OpenAI

**Steps:**
1. Go to Web UI → Models → Add Model
2. Configure:
   - **Model Name**: `gpt-4-azure` (or any name)
   - **LiteLLM Model**: `azure/<deployment-name>`
   - **API Key**: Your Azure API key
   - **API Base**: Your Azure endpoint
   - **API Version**: `2024-02-15-preview`
3. Save the model

## Testing Models

After adding a model, test it via API:

```bash
curl -X POST http://<alb-dns-name>/chat/completions \
  -H "Authorization: Bearer sk-1234" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-bedrock",
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ]
  }'
```

## Model Management

### Viewing Models
- Web UI → Models → View all configured models
- API: `GET /model/info`

### Updating Models
- Web UI → Models → Edit model → Update settings
- Changes take effect immediately (no redeployment needed)

### Deleting Models
- Web UI → Models → Delete model

### Setting Default Model
- Web UI → Settings → Default Model

## Load Balancing & Fallbacks

Configure in Web UI → Router Settings:

1. **Simple Shuffle**: Randomly select from available models
2. **Round Robin**: Distribute requests evenly
3. **Fallbacks**: Define fallback models if primary fails

Example fallback configuration:
```yaml
fallbacks:
  - {"claude-bedrock": ["gpt-4", "claude-direct"]}
```

## Authentication & Keys

### Master Key
- Set in `taskdefinition.tf` → `LITELLM_MASTER_KEY`
- Used for admin access and API authentication
- Change before production deployment

### Virtual Keys (Recommended for Production)
Create virtual keys for different teams/users via Web UI:

1. Go to Web UI → Keys → Generate Key
2. Configure:
   - **Key Name**: `team-a-key`
   - **Budget**: Optional spending limit
   - **Models**: Restrict to specific models
   - **Rate Limit**: Requests per minute
3. Use generated key instead of master key

## Redis Cache

Configured automatically with:
- **Host**: RDS endpoint (from Terraform)
- **Port**: 6379
- **TTL**: 600 seconds (10 minutes)
- **Purpose**: Cache LLM responses to reduce costs and latency

View cache statistics in Web UI → Cache

## Database

PostgreSQL database stores:
- Model configurations
- Virtual keys
- Usage logs
- Spend tracking
- Team/user data

**Connection**: Automatic via `DATABASE_URL` environment variable

## Monitoring

### CloudWatch Logs
View application logs:
```bash
aws logs tail /ecs/litellm --follow --region us-east-1
```

### Metrics (via Web UI)
- Request count by model
- Latency percentiles
- Error rates
- Token usage
- Spend tracking

## Security Best Practices

1. **Change Master Key**: Replace default `sk-1234` before production
2. **Use Virtual Keys**: Don't share master key with end users
3. **Enable Rate Limiting**: Prevent abuse
4. **Set Budgets**: Control costs per key/team
5. **Monitor Logs**: Watch for suspicious activity
6. **Rotate Keys**: Regularly rotate virtual keys

## Troubleshooting

### Model Not Working

**Bedrock Models:**
- Check IAM role has `bedrock:InvokeModel` permission
- Verify model access enabled in Bedrock console
- Check AWS region matches model availability
- Review CloudWatch logs for errors

**API Key Models:**
- Verify API key is valid
- Check API key has sufficient quota
- Ensure correct model ID format

### UI Not Accessible

- Verify ALB DNS resolves
- Check ECS service is running
- Ensure security groups allow traffic
- Verify master key is correct

### Cache Not Working

- Check Redis endpoint is accessible
- Verify Redis security group allows ECS connection
- Review CloudWatch logs for Redis errors

## Example: Complete Bedrock Setup

1. **Enable Bedrock Access** (AWS Console)
   ```
   Bedrock → Model access → Enable Claude 3.7 Sonnet
   ```

2. **Access UI**
   ```
   http://litellm-alb-xxx.elb.amazonaws.com/ui?master_key=sk-1234
   ```

3. **Add Model** (UI)
   - Model Name: `claude-3-7-sonnet`
   - Model ID: `bedrock/anthropic.claude-3-7-sonnet-20250219`
   - Region: `us-west-2`
   - Authentication: (leave empty)

4. **Test**
   ```bash
   curl -X POST http://litellm-alb-xxx.elb.amazonaws.com/chat/completions \
     -H "Authorization: Bearer sk-1234" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "claude-3-7-sonnet",
       "messages": [{"role": "user", "content": "Hi!"}]
     }'
   ```

## Benefits of Dynamic Configuration

✅ **No Redeployment**: Add/remove models without rebuilding containers
✅ **Flexible**: Mix Bedrock, OpenAI, Anthropic, Azure models
✅ **Secure**: Bedrock uses IAM roles, API keys stored encrypted
✅ **Cost Control**: Set budgets per key/team
✅ **Monitoring**: Track usage, spend, errors per model
✅ **Multi-tenant**: Different keys for different teams

## References

- [LiteLLM Documentation](https://docs.litellm.ai/)
- [Bedrock Model IDs](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)
- [LiteLLM Supported Models](https://docs.litellm.ai/docs/providers)
