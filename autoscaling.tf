# ECS Service Auto Scaling Configuration

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 10  # Maximum number of tasks
  min_capacity       = 1   # Minimum number of tasks
  resource_id        = "service/${aws_ecs_cluster.litellm_cluster.name}/${aws_ecs_service.litellm_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.litellm_service]
}

# Auto Scaling Policy - CPU Utilization
resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "litellm-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70.0  # Target 70% CPU utilization
    scale_in_cooldown  = 300   # 5 minutes cooldown before scale in
    scale_out_cooldown = 60    # 1 minute cooldown before scale out
  }
}

# Auto Scaling Policy - Memory Utilization
resource "aws_appautoscaling_policy" "ecs_memory_policy" {
  name               = "litellm-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80.0  # Target 80% memory utilization
    scale_in_cooldown  = 300   # 5 minutes cooldown before scale in
    scale_out_cooldown = 60    # 1 minute cooldown before scale out
  }
}

# Auto Scaling Policy - ALB Request Count per Target
resource "aws_appautoscaling_policy" "ecs_alb_request_count_policy" {
  name               = "litellm-alb-request-count-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.litellm_alb.arn_suffix}/${aws_lb_target_group.litellm_tg.arn_suffix}"
    }

    target_value       = 1000  # Target 1000 requests per task per minute
    scale_in_cooldown  = 300   # 5 minutes cooldown before scale in
    scale_out_cooldown = 60    # 1 minute cooldown before scale out
  }
}

# Outputs
output "autoscaling_target_id" {
  description = "Auto Scaling target resource ID"
  value       = aws_appautoscaling_target.ecs_target.id
}

output "autoscaling_min_capacity" {
  description = "Minimum number of tasks"
  value       = aws_appautoscaling_target.ecs_target.min_capacity
}

output "autoscaling_max_capacity" {
  description = "Maximum number of tasks"
  value       = aws_appautoscaling_target.ecs_target.max_capacity
}
