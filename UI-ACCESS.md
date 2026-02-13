# LiteLLM Web管理界面访问指南

## 🌐 访问信息

**URL**: http://litellm-alb-1512972369.us-east-1.elb.amazonaws.com/ui

**当前登录凭据**:
- 用户名: `admin`
- 密码: `admin123`

⚠️ **警告**: 这是默认密码，请在生产环境中立即修改！

## 🔐 修改UI密码

### 方法1: 修改taskdefinition.tf（推荐）

编辑 `taskdefinition.tf`:
```terraform
{
  "name": "LITELLM_UI_PASSWORD",
  "value": "your-secure-password-here"
}
```

然后应用更改:
```bash
cd ~/litellm-ecs-deployment
terraform apply
./build.sh  # 重新部署
```

### 方法2: 使用AWS Secrets Manager（更安全）

1. 创建密钥:
```bash
aws secretsmanager create-secret \
  --name litellm/ui-password \
  --secret-string '{"LITELLM_UI_PASSWORD":"your-secure-password"}' \
  --region us-east-1
```

2. 修改taskdefinition.tf，将环境变量改为secret:
```terraform
"secrets": [
  # ... 其他secrets
  {
    "name": "LITELLM_UI_PASSWORD",
    "valueFrom": "${aws_secretsmanager_secret.ui_password.arn}:LITELLM_UI_PASSWORD::"
  }
]
```

3. 添加secrets资源到secrets.tf:
```terraform
resource "aws_secretsmanager_secret" "ui_password" {
  name = "litellm/ui-password"
}
```

## 📊 Web界面功能

### 1. 仪表板 (Dashboard)
- **实时统计**: 查看当前API使用情况
- **请求监控**: 跟踪每分钟/小时请求数
- **成本追踪**: 监控API调用成本
- **模型性能**: 查看各模型响应时间和成功率

### 2. API密钥管理 (Keys)
- **创建密钥**: 生成新的API密钥
- **设置限制**:
  - 每日/每月请求限制
  - 预算上限
  - 模型访问权限
- **密钥统计**: 查看每个密钥的使用情况
- **禁用/删除**: 管理密钥生命周期

### 3. 模型管理 (Models)
- **模型列表**: 查看所有配置的模型
- **测试模型**: 直接在UI中测试模型调用
- **使用统计**: 每个模型的调用次数、成功率、平均延迟
- **成本分析**: 每个模型的使用成本

### 4. 用户管理 (Users)
- **创建用户**: 添加新用户账户
- **分配权限**: 设置不同级别的访问权限
- **团队管理**: 创建和管理团队
- **使用配额**: 为用户/团队设置使用限制

### 5. 日志和调试 (Logs)
- **请求日志**: 查看所有API请求详情
- **错误日志**: 追踪失败的请求
- **过滤和搜索**: 按时间、用户、模型等过滤
- **导出数据**: 下载日志用于分析

### 6. 设置 (Settings)
- **通用设置**: 修改代理配置
- **回调配置**: 设置webhook和日志回调
- **缓存设置**: 配置Redis缓存参数
- **安全设置**: 更新密码和访问控制

## 🔧 API测试示例

在UI中测试后，您可以在终端使用：

### 使用Master Key
```bash
curl -X POST http://litellm-alb-1512972369.us-east-1.elb.amazonaws.com/v1/chat/completions \
  -H "Authorization: Bearer sk-1234" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-latest",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### 使用UI创建的API Key
```bash
# 在UI中创建新密钥后
curl -X POST http://litellm-alb-1512972369.us-east-1.elb.amazonaws.com/v1/chat/completions \
  -H "Authorization: Bearer your-generated-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-5-sonnet-latest",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

## 🛡️ 安全最佳实践

1. **立即修改默认密码**
   - 使用强密码（至少16个字符）
   - 包含大小写字母、数字和特殊字符

2. **限制IP访问**（可选）
   修改alb.tf中的ALB安全组:
   ```terraform
   ingress {
     description = "HTTP from specific IP"
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
     cidr_blocks = ["YOUR_IP/32"]  # 替换为您的IP
   }
   ```

3. **启用HTTPS**
   - 获取SSL证书（AWS Certificate Manager）
   - 配置HTTPS监听器
   - 详见DEPLOYMENT-COMPLETE.md

4. **定期轮换密钥**
   - 定期更新Master Key
   - 定期更新UI密码
   - 定期更新API密钥

5. **监控和告警**
   - 在UI中设置使用预算告警
   - 配置CloudWatch告警
   - 监控异常访问模式

## 📱 移动访问

Web UI是响应式设计，可以在移动设备上访问：
- 在浏览器中访问相同的URL
- 登录使用相同的凭据
- 功能与桌面版相同

## 🔄 更新配置

修改config.yaml后需要重新部署：

```bash
cd ~/litellm-ecs-deployment
vim config.yaml  # 编辑配置
./build.sh       # 重新构建和部署
```

等待约2-3分钟让新容器启动。

## 📚 更多资源

- [LiteLLM UI文档](https://docs.litellm.ai/docs/proxy/ui)
- [API密钥管理](https://docs.litellm.ai/docs/proxy/virtual_keys)
- [用户管理](https://docs.litellm.ai/docs/proxy/users)
- [预算和限制](https://docs.litellm.ai/docs/proxy/budget_alerts)

---

**首次访问**: 2026-02-13
**默认凭据**: admin / admin123
**⚠️ 请立即修改密码！**
