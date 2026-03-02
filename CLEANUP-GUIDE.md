# 清理和销毁指南

## 问题背景

在执行 `terraform destroy` 时，如果ECR仓库中包含镜像，销毁会失败并报错：
```
Error: ECR Repository (litellm-dev) not empty, consider using force_delete
```

## 解决方案

### 方案1：使用 `force_delete` 参数（推荐）✅

**优点**：自动化，无需手动干预
**实施**：已在 `ecr.tf` 中添加 `force_delete = true`

```hcl
resource "aws_ecr_repository" "litellm_dev" {
  name         = "litellm-dev"
  force_delete = true  # 自动删除镜像

  tags = {
    Name = "latest_ecr"
  }
}
```

使用此配置后，直接运行：
```bash
terraform destroy -auto-approve
```

Terraform会自动删除ECR中的所有镜像，然后删除仓库。

---

### 方案2：使用自动化清理脚本

**优点**：完整的清理流程，包括中间文件
**使用**：

```bash
./cleanup.sh
```

脚本会自动执行：
1. 清空ECR镜像
2. 运行 `terraform destroy`
3. 删除所有Terraform中间文件

---

### 方案3：手动清空ECR（备选）

如果方案1和方案2都不可用，手动清空：

```bash
# 删除所有镜像
aws ecr batch-delete-image \
  --repository-name litellm-dev \
  --region us-east-1 \
  --image-ids "$(aws ecr list-images \
    --repository-name litellm-dev \
    --region us-east-1 \
    --query 'imageIds[*]' \
    --output json)"

# 然后执行销毁
terraform destroy -auto-approve
```

---

## 生命周期策略优化（可选）

如果希望自动清理旧镜像，可以在 `ecr.tf` 中添加生命周期策略：

```hcl
resource "aws_ecr_lifecycle_policy" "litellm_dev_policy" {
  repository = aws_ecr_repository.litellm_dev.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
```

这会自动保留最新的5个镜像，删除更早的镜像。

---

## 快速清理命令

```bash
# 完整清理（推荐）
./cleanup.sh

# 或手动步骤
terraform destroy -auto-approve && \
rm -rf .terraform terraform.tfstate* .terraform.lock.hcl tfplan
```

---

## 清理验证

清理完成后验证：

```bash
# 检查ECR仓库是否删除
aws ecr describe-repositories --region us-east-1 | grep litellm-dev

# 检查ECS集群是否删除
aws ecs list-clusters --region us-east-1 | grep litellm

# 检查本地文件
ls -la | grep -E "terraform|tfstate|tfplan"
```

如果所有命令都没有输出，说明清理成功！

---

## 常见问题

### Q: `force_delete` 是否会删除正在使用的镜像？
A: 是的。使用前请确保：
- 所有ECS任务已停止
- 没有其他服务依赖这些镜像
- 已备份需要保留的镜像

### Q: 如何备份ECR镜像？
A: 在销毁前拉取到本地：
```bash
# 登录ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 935206693453.dkr.ecr.us-east-1.amazonaws.com

# 拉取镜像
docker pull 935206693453.dkr.ecr.us-east-1.amazonaws.com/litellm-dev:latest

# 保存为tar文件
docker save -o litellm-backup.tar 935206693453.dkr.ecr.us-east-1.amazonaws.com/litellm-dev:latest
```

### Q: 销毁需要多长时间？
A: 通常2-5分钟，主要时间消耗在：
- RDS数据库删除（~2分钟）
- ElastiCache Redis删除（~2分钟）
- NAT Gateway删除（~1分钟）

---

## 最佳实践

1. **开发环境**：使用 `force_delete = true`，快速迭代
2. **生产环境**：不使用 `force_delete`，避免误删，手动清理确保安全
3. **CI/CD**：使用自动化脚本 `cleanup.sh`，集成到pipeline
4. **定期清理**：使用ECR生命周期策略自动删除旧镜像

---

## 更新记录

- 2026-02-13: 添加 `force_delete` 参数到 `ecr.tf`
- 2026-02-13: 创建 `cleanup.sh` 自动化脚本
