# LiteLLM on AWS ECS Fargate

基于 Terraform 将 [LiteLLM](https://github.com/BerriAI/litellm) 部署到 AWS ECS Fargate，提供统一的 LLM API 代理网关，支持 Bedrock、OpenAI、Anthropic 等多种模型。

## 架构

```
Internet → ALB (80) → ECS Fargate (4vCPU / 8GB)
                           ├── RDS PostgreSQL  (配置/密钥/用量存储)
                           └── ElastiCache Redis (响应缓存)
```

**基础设施组件：**

| 组件 | 规格 | 用途 |
|------|------|------|
| ECS Fargate | 4 vCPU / 8 GB | 运行 LiteLLM 容器 |
| RDS PostgreSQL | db.t3.micro | 存储模型配置、虚拟密钥、用量记录 |
| ElastiCache Redis | cache.t3.micro | 缓存 LLM 响应，降低延迟和成本 |
| ALB | - | 负载均衡，Auto Scaling 入口 |
| ECR | - | 存储 Docker 镜像 |
| CloudWatch | - | 容器日志与监控指标 |

---

## 前置条件

- [AWS CLI](https://aws.amazon.com/cli/) 已配置（`aws configure`）
- [Terraform](https://www.terraform.io/) v1.0+
- [Docker](https://www.docker.com/) with buildx 支持
- AWS 账号具备以下服务权限：ECS、ECR、IAM、VPC、RDS、ElastiCache、Secrets Manager、CloudWatch

---

## 部署流程

### 第一步：初始化 Terraform

```bash
git clone <your-repo-url>
cd litellm-ecs-deployment

terraform init
```

Terraform 按以下顺序自动查找 AWS 凭证，无需额外配置：

1. **环境变量**（适合 CI/CD）
   ```bash
   export AWS_ACCESS_KEY_ID=...
   export AWS_SECRET_ACCESS_KEY=...
   export AWS_DEFAULT_REGION=us-west-2
   terraform plan
   ```

2. **EC2 / ECS Instance Role**（在 AWS 环境中运行 Terraform 时推荐）
   为运行 Terraform 的 EC2 实例附加具有足够权限的 IAM Role，直接执行即可：
   ```bash
   terraform plan
   ```

3. **本地 AWS CLI Profile**（本地开发）
   ```bash
   terraform plan -var="aws_profile=my-profile"
   # 或创建 terraform.tfvars（已在 .gitignore 中，不会提交）
   # aws_profile = "my-profile"
   ```

如需切换 region：
```bash
terraform plan -var="aws_region=us-west-2"
```

### 第二步：（可选）限制访问 IP

编辑 `alb.tf`，在 ALB 安全组的 `ingress` 中替换为你的 IP：

```hcl
cidr_blocks = ["your.ip.address/32"]
```

### 第三步：创建基础设施

```bash
terraform plan   # 预览将要创建的资源
terraform apply  # 确认后输入 yes
```

> 首次部署约需 10-15 分钟，RDS 启动较慢。

部署完成后查看访问凭证：

```bash
# 获取 ALB 访问地址
terraform output alb_dns_name

# 获取 Master Key（API 调用凭证）
terraform output litellm_master_key

# 获取 UI 管理密码
terraform output ui_password
```

### 第四步：构建并推送 Docker 镜像

```bash
./build.sh
# 或指定 region 和 profile
./build.sh us-east-1 your-profile
```

此脚本会：
1. 构建 `linux/amd64` 平台镜像
2. 推送到 ECR
3. 触发 ECS 强制重新部署

等待约 2-3 分钟，ECS 任务启动完成后即可访问。

### 第五步：开通 Bedrock 模型访问（如使用 Bedrock）

```
AWS Console → Amazon Bedrock → 模型访问 → 申请开通 Claude 系列模型
```

---

## 使用流程

### 访问 Web UI

```
http://<alb-dns-name>/ui
```

使用账号 `admin`，密码通过以下命令获取：

```bash
terraform output ui_password
```

### 通过 UI 添加模型

**方式一：Bedrock 模型（推荐，无需 API Key）**

Web UI → Models → Add Model：
- Model Name：自定义（如 `claude-sonnet`）
- LiteLLM Model：选择 Bedrock provider
- Model ID：`bedrock/anthropic.claude-3-7-sonnet-20250219`
- AWS Region：`us-east-1` 或 `us-west-2`
- Authentication：**留空**（自动使用 ECS Task IAM Role）

**方式二：OpenAI / Anthropic / Azure**

Web UI → Models → Add Model，填入对应 API Key 即可。

模型添加后**无需重新部署**，立即生效。

### API 调用

```bash
# 获取 Master Key
MASTER_KEY=$(terraform output -raw litellm_master_key)
ALB_DNS=$(terraform output -raw alb_dns_name)

# 发起请求
curl -X POST http://$ALB_DNS/chat/completions \
  -H "Authorization: Bearer $MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-sonnet",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### 创建虚拟密钥（多用户/团队）

Web UI → Keys → Generate Key，可配置：
- 可访问的模型范围
- 每分钟请求限制
- 消费预算上限

建议对外分发虚拟密钥，Master Key 仅管理员使用。

### 查看日志

```bash
aws logs tail /ecs/litellm --follow --region us-east-1
```

---

## 弹性伸缩

Auto Scaling 已默认配置，无需手动干预：

| 指标 | 触发扩容阈值 | 触发缩容 |
|------|-------------|---------|
| CPU | > 70% 持续 1 分钟 | < 70% 持续 5 分钟 |
| 内存 | > 80% 持续 1 分钟 | < 80% 持续 5 分钟 |
| 请求数 | > 1000 次/任务/分钟 | 回落后 5 分钟 |

- 最小任务数：1，最大任务数：10
- 扩容冷却：60 秒，缩容冷却：300 秒

如需调整，编辑 `autoscaling.tf` 后执行 `terraform apply`。

---

## 更新镜像

修改 `Dockerfile` 或 `config.yaml` 后，重新构建推送：

```bash
./build.sh
```

ECS 会自动滚动更新，无停机时间。

---

## 销毁流程

> **警告：** 销毁操作不可逆，数据库数据将永久删除。

```bash
terraform destroy
```

确认输入 `yes` 后，约 10-20 分钟完成所有资源删除。

销毁完成后清理本地 Terraform 文件：

```bash
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
```

---

## 费用参考（us-east-1）

| 资源 | 规格 | 月费用（约） |
|------|------|------------|
| ECS Fargate（1 任务） | 4 vCPU / 8 GB | ~$32 |
| RDS PostgreSQL | db.t3.micro | ~$15 |
| ElastiCache Redis | cache.t3.micro | ~$12 |
| ALB | - | ~$20 |
| **合计（最低）** | | **~$79/月** |

Auto Scaling 最多 10 个任务时，ECS 费用可达 ~$324/月。建议非生产环境使用完及时销毁。

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `provider.tf` | AWS Provider 配置（region、profile） |
| `vpc.tf` / `vpc_private.tf` | VPC 与子网 |
| `security_groups.tf` | 安全组（ECS / RDS / Redis） |
| `ecr.tf` | ECR 镜像仓库 |
| `ecs.tf` | ECS 集群 |
| `taskdefinition.tf` | ECS Task 定义与环境变量 |
| `service.tf` | ECS Service |
| `alb.tf` | Application Load Balancer |
| `rds.tf` | RDS PostgreSQL |
| `redis.tf` | ElastiCache Redis |
| `iam.tf` | IAM 角色与权限（含 Bedrock 访问） |
| `autoscaling.tf` | Auto Scaling 策略 |
| `secrets.tf` | 动态生成的密钥资源 |
| `cloudwatch.tf` | CloudWatch 日志组 |
| `config.yaml` | LiteLLM 配置（缓存等） |
| `Dockerfile` | 自定义镜像 |
| `build.sh` | 构建并部署镜像脚本 |

---

## 参考链接

- [LiteLLM 文档](https://docs.litellm.ai/)
- [Bedrock 模型 ID 列表](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)
- [LiteLLM 支持的模型](https://docs.litellm.ai/docs/providers)
