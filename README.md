# Deploy LiteLLM on AWS ECS

This project sets up [LiteLLM](https://github.com/BerriAI/litellm) on AWS ECS using Fargate

### Tutorial

[🎥 Watch the demo here](https://screen.studio/share/9JRqlF0h)

### Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- [Terraform](https://www.terraform.io/) v1.0+
- [Docker](https://www.docker.com/) with buildx support
- AWS account with:
  - ECS, ECR, IAM, VPC, RDS, ElastiCache, Secrets Manager permissions


## 🚀 Quick Start

1. **Clone and Setup**
   ```bash
   git clone <your-repo-url>
   cd litellm_ecs-deployment
   ```

2. **Configure AWS**
   - Install AWS CLI and configure your credentials
   - Ensure you have permissions for ECS, ECR, IAM roles, VPC, etc

your cluster should run the task definition in AWS console

### how it works

Simply put, ECS runs litellm this way:

Cluster -> Service -> Task

you can have multiple task definitions / services under one cluster (prod, staging, dev environments)

- use ECS Fargate for serverless container execution (use EC2 if you prefer manual control)
- build your own docker image and push it to ECR (Elastic Container Registry)
- store api keys in aws secret manager
- host on a VPC across different subnets (public / private ip)
- add an application load balancer (optional)
- use cloud watch for monitoring container logs

### Infrastructure Components

This deployment includes:

**Database (RDS PostgreSQL)**
- Managed PostgreSQL database for LiteLLM persistence
- Automatic backups with 7-day retention
- Encrypted storage with GP3 volumes
- Credentials stored in AWS Secrets Manager
- Connection URL automatically configured in ECS task

**Cache (ElastiCache Redis)**
- Redis cluster for LiteLLM response caching
- Reduces latency and API costs by caching repeated requests
- Automatic failover and backups
- Connection details automatically configured in task environment

**Security Groups**
- ECS tasks security group: allows inbound HTTP on port 4000
- RDS security group: allows PostgreSQL (5432) from ECS tasks only
- Redis security group: allows Redis (6379) from ECS tasks only


### configuration

#### litellm config
Edit `config.yaml` to configure your LLM providers and settings.

**Redis Caching** is enabled by default with a 10-minute TTL. The configuration in `config.yaml` includes:
```yaml
litellm_settings:
  cache: true
  cache_params:
    type: "redis"
    host: os.environ/REDIS_HOST
    port: os.environ/REDIS_PORT
    ttl: 600  # cache for 10 minutes
```

Adjust the `ttl` value to change cache duration (in seconds).

### Environment Variables & Secrets

Environment variables automatically configured in [taskdefinition.tf](taskdefinition.tf):

**Database:**
- `DATABASE_URL` - PostgreSQL connection string (automatically generated from RDS)

**Redis Cache:**
- `REDIS_HOST` - Redis endpoint (automatically generated from ElastiCache)
- `REDIS_PORT` - Redis port (automatically generated from ElastiCache)
- `REDIS_URL` - Full Redis connection string (automatically generated)

**LiteLLM:**
- `LITELLM_MASTER_KEY` - Master API key (update with your own secure key)
- `LITELLM_SALT_KEY` - Salt for credential encryption (update with your own secure key)

**API Keys:**
Store API keys in AWS Secrets Manager via [secrets.tf](secrets.tf). Required secrets:
- AWS credentials (access key & secret)
- OpenAI API key
- Anthropic API key
- Azure API key
- Gemini API key

These are automatically injected into the container from Secrets Manager.

### AWS Region & Profile
Modify `provider.tf` if using different region/profile.

### Cost Considerations

**Default Configuration (us-east-1):**
- RDS PostgreSQL (db.t3.micro): ~$15-20/month
- ElastiCache Redis (cache.t3.micro): ~$12-15/month
- ECS Fargate (4 vCPU, 8GB): ~$0.12/hour (~$90/month for 24/7)
- Data transfer and storage costs vary by usage

**Cost Optimization:**
- Adjust RDS instance size in `rds.tf` (instance_class)
- Adjust Redis node type in `redis.tf` (node_type)
- Reduce ECS task CPU/memory in `taskdefinition.tf`
- Use scheduled scaling for non-production environments
- Enable RDS Multi-AZ for production (increases cost but adds availability)

### build your own image

## 🚀 Deployment Steps

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Plan Deployment**
   ```bash
   terraform plan
   ```

3. **Apply Infrastructure**
   ```bash
   terraform apply
   ```

4. **Build & Deploy Application**
   ```bash
   ./build.sh
   ```
   This builds your Docker image on linux/amd64, pushes to ECR and triggers ECS deployment. you can use this command to force an update to ECS service

## 🔍 Monitoring

create a new directory in AWS Cloudwatch and add it to [taskdefinition.tf](taskdefinition.tf)

example: "awslogs-group": "/ecs/litellm",

view logs in cloudwatch 
- **Service Status**: Check ECS console or use AWS CLI
- **Load Balancer**: Monitor ALB metrics in CloudWatch

## 🛠️ Troubleshooting

### Terraform Issues
- Run `terraform validate` to check syntax
- Use `terraform state list` to inspect resources

### Prod

- API keys are stored in AWS Secrets Manager
- For production: Add SSL certificate, restrict IP ranges, use WAF

## Scaling

- **Scaling**:
	- Adjust `desired_count` in `service.tf`
	- Set cpu = num_workers
	- Don't use static memory limits when you configure CPUs to scale

- **Resources**: Modify CPU/memory in `taskdefinition.tf`
- **Networking**: Update VPC/subnets in `vpc.tf`
- **Health Checks**: Configure in ALB target group

## Infrastructure Files

### New Files (added in this fork)
- `rds.tf` - RDS PostgreSQL database configuration
- `redis.tf` - ElastiCache Redis cluster configuration
- `security_groups.tf` - Security groups for ECS, RDS, and Redis

### Modified Files
- `taskdefinition.tf` - Added DATABASE_URL, REDIS_HOST, REDIS_PORT, REDIS_URL environment variables
- `config.yaml` - Added Redis caching configuration
- `service.tf` - Added security group and dependencies on RDS/Redis
- `provider.tf` - Added random provider for password generation
- `cloudwatch.tf` - Fixed resource name syntax

### Key Features Added
✅ **Managed PostgreSQL Database**: Automatic provisioning, backups, and secure connection
✅ **Redis Caching**: Response caching to reduce latency and API costs
✅ **Security Groups**: Proper network isolation between components
✅ **Secrets Management**: Database credentials stored in AWS Secrets Manager
✅ **Auto Configuration**: Database and Redis connection details automatically injected into containers
