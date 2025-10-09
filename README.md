# Deploy LiteLLM on AWS ECS

This project sets up [LiteLLM](https://github.com/BerriAI/litellm) on AWS ECS using Fargate

## 🎥 Videos

### Deployment Demo
[![Deployment Demo](https://img.youtube.com/vi/AmNYbFSP6t0/0.jpg)](https://youtu.be/AmNYbFSP6t0)

### Tutorial
[Watch the full tutorial on Screen Studio](https://screen.studio/share/9JRqlF0h)

## 🚀 Quick Start

1. **Clone and Setup**
   ```bash
   git clone <your-repo-url>
   cd litellm_ecs_tf
   ```

2. **Configure AWS**
   - Install AWS CLI and configure your credentials
   - Ensure you have permissions for ECS, ECR, IAM roles, VPC, etc.

3. **Deploy**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ./build.sh  # Builds and deploys your custom LiteLLM image
   ```

your cluster should run the task definition in AWS console

### prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- [Terraform](https://www.terraform.io/) v1.0+
- [Docker](https://www.docker.com/) with buildx support
- AWS account with:
  - ECS, ECR, IAM, VPC, ELB permissions
  - Default VPC in us-east-1 region

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


### configuration

#### litellm config
Edit `config.yaml` to configure your LLM providers and settings.

### Environment Variables & Secrets

required env variables in [taskdefinition](taskdefintion.tf):

```bash
DATABASE_URL=<postgres://>
LITELLM_MASTER_KEY="sk-1234" # should start with sk
LITELLM_SALT_KEY="secure-hash-key" # store creds in your db
```

store api keys in AWS Secrets Manager [secrets.tf](secrets.tf) and also add them in [taskdefinition](taskdefinition.tf)

### AWS Region & Profile
Modify `provider.tf` if using different region/profile.

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
   This builds your Docker image on linux/amd64, pushes to ECR and triggers ECS deployment.

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

- **Scaling**: Adjust `desired_count` in `service.tf`
- **Resources**: Modify CPU/memory in `taskdefinition.tf`
- **Networking**: Update VPC/subnets in `vpc.tf`
- **Health Checks**: Configure in ALB target group
