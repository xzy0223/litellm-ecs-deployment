# ECS Fargate Auto Scaling Configuration

## Overview

This deployment includes comprehensive auto scaling configuration for the LiteLLM ECS service, automatically adjusting the number of running tasks based on demand.

## Scaling Configuration

### Capacity Limits

```terraform
Min Capacity: 1 task
Max Capacity: 10 tasks
```

**Adjusting Capacity:**
- Edit `autoscaling.tf` → `aws_appautoscaling_target.ecs_target`
- Modify `min_capacity` and `max_capacity` values
- Run `terraform apply`

**Recommendations:**
- **Dev/Test**: min=1, max=3
- **Production**: min=2, max=10 (for high availability)
- **High Traffic**: min=3, max=20

## Scaling Policies

### 1. CPU-Based Scaling

**Target**: 70% average CPU utilization

**How it works:**
- Scales OUT when CPU > 70% for 1 minute
- Scales IN when CPU < 70% for 5 minutes
- Each task has 4096 CPU units (4 vCPU)

**Tuning:**
```terraform
target_value = 70.0  # Lower = more aggressive scaling
```

**Use case:** CPU-intensive workloads, model inference

### 2. Memory-Based Scaling

**Target**: 80% average memory utilization

**How it works:**
- Scales OUT when memory > 80% for 1 minute
- Scales IN when memory < 80% for 5 minutes
- Each task has 8192 MB (8 GB) memory

**Tuning:**
```terraform
target_value = 80.0  # Lower = more aggressive scaling
```

**Use case:** Large model context windows, caching

### 3. Request Count-Based Scaling

**Target**: 1000 requests per task per minute

**How it works:**
- Scales OUT when requests/task > 1000/min for 1 minute
- Scales IN when requests/task < 1000/min for 5 minutes
- Based on ALB target group metrics

**Tuning:**
```terraform
target_value = 1000  # Lower = more tasks, lower latency
```

**Use case:** High request volume, predictable traffic patterns

## Cooldown Periods

### Scale Out Cooldown: 60 seconds
- Minimum time between successive scale-out actions
- Prevents rapid scaling oscillations
- Allows new tasks to stabilize before next scale

### Scale In Cooldown: 300 seconds (5 minutes)
- Minimum time between successive scale-in actions
- Prevents premature termination of tasks
- Allows traffic to settle before removing capacity

**Tuning cooldowns:**
```terraform
scale_out_cooldown = 60   # Faster response to load spikes
scale_in_cooldown  = 300  # Prevent aggressive scale-in
```

## Scaling Behavior

### Scale Out (Adding Tasks)

**Triggers:**
- CPU > 70% for 1 minute OR
- Memory > 80% for 1 minute OR
- Requests > 1000/task/min for 1 minute

**Process:**
1. CloudWatch detects metric breach
2. Auto Scaling adds 1-2 tasks
3. New tasks start within 2-3 minutes
4. ALB begins routing traffic to new tasks
5. Waits 60 seconds before next scale-out

**Time to scale:** ~2-3 minutes (Fargate task startup)

### Scale In (Removing Tasks)

**Triggers:**
- ALL metrics below target for 5 minutes

**Process:**
1. CloudWatch confirms sustained low utilization
2. Auto Scaling removes 1 task
3. ALB drains connections (300 seconds)
4. Task gracefully shuts down
5. Waits 5 minutes before next scale-in

**Time to scale:** ~5-6 minutes (drain + cooldown)

## Monitoring

### CloudWatch Metrics

**Service Metrics:**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=litellm-service \
              Name=ClusterName,Value=litellm-ecs-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region us-east-1
```

**Key Metrics:**
- `ECSServiceAverageCPUUtilization`
- `ECSServiceAverageMemoryUtilization`
- `ALBRequestCountPerTarget`
- `TargetResponseTime` (ALB)

### Auto Scaling Activity

**View scaling activities:**
```bash
aws application-autoscaling describe-scaling-activities \
  --service-namespace ecs \
  --resource-id service/litellm-ecs-cluster/litellm-service \
  --region us-east-1
```

**Check current capacity:**
```bash
aws ecs describe-services \
  --cluster litellm-ecs-cluster \
  --services litellm-service \
  --query 'services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount}' \
  --region us-east-1
```

## Cost Implications

### Scaling Costs

**Per Task (Fargate):**
- CPU: 4096 units (4 vCPU) = $0.04048/hour
- Memory: 8192 MB (8 GB) = $0.004445/hour
- **Total per task**: ~$0.045/hour = ~$32.40/month

**Scaling Scenarios:**

| Scenario | Tasks | Monthly Cost |
|----------|-------|--------------|
| Minimum (1 task) | 1 | $32.40 |
| Average (3 tasks) | 3 | $97.20 |
| Peak (10 tasks) | 10 | $324.00 |

**Cost Optimization:**
- Set appropriate min/max based on traffic patterns
- Use aggressive scale-in (longer cooldown) to reduce idle capacity
- Monitor and adjust target values to avoid over-provisioning

## Configuration Examples

### Conservative Scaling (Cost-Optimized)

```terraform
# autoscaling.tf
resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity = 1
  max_capacity = 5
}

resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  target_tracking_scaling_policy_configuration {
    target_value       = 80.0  # Higher threshold
    scale_in_cooldown  = 600   # Longer cooldown (10 min)
    scale_out_cooldown = 120   # Moderate scale-out
  }
}
```

**Benefits:** Lower costs, fewer tasks
**Drawbacks:** Slower response to load spikes

### Aggressive Scaling (Performance-Optimized)

```terraform
# autoscaling.tf
resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity = 2   # High availability
  max_capacity = 20  # Handle traffic spikes
}

resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  target_tracking_scaling_policy_configuration {
    target_value       = 50.0  # Lower threshold
    scale_in_cooldown  = 600   # Conservative scale-in
    scale_out_cooldown = 30    # Fast scale-out
  }
}
```

**Benefits:** Better performance, lower latency
**Drawbacks:** Higher costs, more idle capacity

### Balanced Scaling (Recommended)

```terraform
# Current configuration (default)
resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity = 1
  max_capacity = 10
}

resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  target_tracking_scaling_policy_configuration {
    target_value       = 70.0  # Balanced threshold
    scale_in_cooldown  = 300   # 5 minutes
    scale_out_cooldown = 60    # 1 minute
  }
}
```

**Benefits:** Good balance of cost and performance
**Drawbacks:** None for typical workloads

## Scheduled Scaling (Optional)

For predictable traffic patterns, add scheduled scaling:

```terraform
# Add to autoscaling.tf

# Scale up during business hours (9 AM - 6 PM EST)
resource "aws_appautoscaling_scheduled_action" "scale_up_business_hours" {
  name               = "scale-up-business-hours"
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  schedule           = "cron(0 9 ? * MON-FRI *)"  # 9 AM EST, Mon-Fri
  timezone           = "America/New_York"

  scalable_target_action {
    min_capacity = 3
    max_capacity = 10
  }
}

# Scale down during off-hours
resource "aws_appautoscaling_scheduled_action" "scale_down_off_hours" {
  name               = "scale-down-off-hours"
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  schedule           = "cron(0 18 ? * MON-FRI *)"  # 6 PM EST, Mon-Fri
  timezone           = "America/New_York"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 5
  }
}
```

## Troubleshooting

### Tasks Not Scaling Out

**Check:**
1. Verify metrics breach threshold:
   ```bash
   aws cloudwatch get-metric-statistics --namespace AWS/ECS ...
   ```
2. Check scaling activities for errors:
   ```bash
   aws application-autoscaling describe-scaling-activities ...
   ```
3. Verify IAM permissions for ECS Auto Scaling
4. Check if max capacity reached

### Tasks Not Scaling In

**Check:**
1. Verify all metrics below target for 5 minutes
2. Check if min capacity reached
3. Review ALB connection draining (300 seconds)
4. Verify scale-in cooldown period hasn't blocked action

### Rapid Scaling Oscillations

**Solution:**
- Increase cooldown periods
- Adjust target values (higher for less aggressive)
- Use multiple metrics (all must trigger)

## Best Practices

1. **Start Conservative**: Begin with min=1, max=3, monitor, then adjust
2. **Monitor First Week**: Watch metrics and scaling activities closely
3. **Set Alarms**: CloudWatch alarms for capacity limits reached
4. **Test Load**: Use load testing to verify scaling behavior
5. **Review Monthly**: Adjust based on actual usage patterns
6. **Cost Tracking**: Tag resources and track scaling costs

## CloudWatch Alarms (Recommended)

Add alarms for scaling events:

```terraform
# Add to autoscaling.tf

resource "aws_cloudwatch_metric_alarm" "ecs_max_capacity_reached" {
  alarm_name          = "litellm-max-capacity-reached"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DesiredCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 10  # Max capacity
  alarm_description   = "Alert when ECS service reaches max capacity"

  dimensions = {
    ServiceName = aws_ecs_service.litellm_service.name
    ClusterName = aws_ecs_cluster.litellm_cluster.name
  }
}
```

## Summary

**Current Configuration:**
- Min: 1 task, Max: 10 tasks
- CPU target: 70%
- Memory target: 80%
- Request target: 1000/task/min
- Scale-out: 60s cooldown
- Scale-in: 300s cooldown

**Monthly Cost Range:**
- Minimum (1 task): $32.40
- Average (3 tasks): $97.20
- Maximum (10 tasks): $324.00

**Recommended Actions:**
1. Deploy with current settings
2. Monitor for 1 week
3. Adjust based on traffic patterns
4. Set CloudWatch alarms
5. Review monthly costs

For questions or adjustments, modify `autoscaling.tf` and run `terraform apply`.
