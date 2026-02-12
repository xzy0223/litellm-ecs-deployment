# Changes Summary

This fork adds managed database and caching infrastructure to the LiteLLM ECS deployment.

## New Infrastructure Components

### 1. RDS PostgreSQL Database (`rds.tf`)
- **Instance**: db.t3.micro with PostgreSQL 16.4
- **Storage**: 20GB GP3 with auto-scaling up to 100GB
- **Security**: Encrypted at rest, password stored in Secrets Manager
- **Networking**: Deployed in private subnets across 3 AZs
- **Backups**: 7-day retention, automated daily backups
- **Access**: Only accessible from ECS tasks via security group

### 2. ElastiCache Redis (`redis.tf`)
- **Node Type**: cache.t3.micro
- **Engine**: Redis 7.1
- **Caching**: Configured for LiteLLM response caching (10-minute TTL)
- **Networking**: Deployed in private subnets across 3 AZs
- **Backups**: 5-day snapshot retention
- **Access**: Only accessible from ECS tasks via security group

### 3. Security Groups (`security_groups.tf`)
- **ECS Tasks**: Allows inbound HTTP on port 4000 from anywhere
- **RDS**: Allows PostgreSQL (5432) from ECS tasks only
- **Redis**: Allows Redis (6379) from ECS tasks only

## Modified Components

### Task Definition (`taskdefinition.tf`)
Added environment variables:
```terraform
DATABASE_URL    # Auto-generated PostgreSQL connection string
REDIS_HOST      # Redis endpoint from ElastiCache
REDIS_PORT      # Redis port (6379)
REDIS_URL       # Full Redis connection string
```

### LiteLLM Configuration (`config.yaml`)
Enabled Redis caching:
```yaml
litellm_settings:
  cache: true
  cache_params:
    type: "redis"
    host: os.environ/REDIS_HOST
    port: os.environ/REDIS_PORT
    ttl: 600  # 10 minutes
```

### ECS Service (`service.tf`)
- Added security group attachment
- Added dependencies on RDS and Redis resources
- Ensures database and cache are ready before starting containers

### Terraform Providers (`provider.tf`)
- Added `hashicorp/random` provider for secure password generation

### CloudWatch Logs (`cloudwatch.tf`)
- Fixed resource naming (from `/ecs/litellm` to `litellm_ecs_logs`)

## Benefits

✅ **Persistent Storage**: All LiteLLM data stored in managed PostgreSQL
✅ **Improved Performance**: Redis caching reduces API calls and latency
✅ **Cost Optimization**: Caching reduces API costs for repeated requests
✅ **Security**: Database credentials managed by AWS Secrets Manager
✅ **High Availability**: Resources deployed across multiple AZs
✅ **Automated Backups**: Built-in backup retention for both RDS and Redis
✅ **Scalability**: Easy to upgrade instance sizes as needed

## Deployment Notes

1. First `terraform apply` will take 10-15 minutes (RDS creation is slow)
2. Database and Redis endpoints are automatically configured
3. No manual connection string configuration required
4. All resources in us-east-1 by default (configurable in `provider.tf`)

## Cost Estimate (us-east-1)

| Component | Instance Type | Estimated Monthly Cost |
|-----------|---------------|------------------------|
| RDS PostgreSQL | db.t3.micro | $15-20 |
| ElastiCache Redis | cache.t3.micro | $12-15 |
| ECS Fargate | 4 vCPU, 8GB RAM | $90 (24/7) |
| **Total** | | **~$120-130/month** |

*Note: Costs vary by region and usage. Add data transfer and storage costs.*

## Customization

### Scaling RDS
Edit `rds.tf`:
```terraform
instance_class = "db.t3.small"  # Upgrade to small
allocated_storage = 50          # Increase initial storage
```

### Scaling Redis
Edit `redis.tf`:
```terraform
node_type = "cache.t3.small"    # Upgrade to small
num_cache_nodes = 2             # Add read replica
```

### Adjusting Cache TTL
Edit `config.yaml`:
```yaml
cache_params:
  ttl: 1800  # 30 minutes instead of 10
```

## Security Considerations

- Database password is randomly generated and stored in Secrets Manager
- All resources are in private subnets (except ECS tasks with public IPs)
- Security groups enforce least-privilege access
- Consider enabling RDS encryption at rest for production
- Consider enabling SSL for Redis connections in production
- Update LITELLM_MASTER_KEY and LITELLM_SALT_KEY before production deployment
