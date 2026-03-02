resource "aws_ecs_service" "litellm_service" {
  name              = "litellm-service"
  cluster           = aws_ecs_cluster.litellm_cluster.id
  task_definition   = aws_ecs_task_definition.litellm_task.arn
  desired_count     = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = [
      aws_subnet.private_az1.id,
      aws_subnet.private_az2.id,
      aws_subnet.private_az3.id
    ]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false  # Private subnet - no public IP needed
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.litellm_tg.arn
    container_name   = "litellm_task"
    container_port   = 4000
  }

  enable_execute_command = true

  health_check_grace_period_seconds = 300

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = [
    aws_iam_role_policy_attachment.litellm_task_execution_role_policy,
    aws_iam_role_policy.litellm_bedrock_permissions,
    aws_db_instance.litellm_db,
    aws_elasticache_cluster.litellm_redis,
    aws_nat_gateway.main  # Ensure NAT Gateway is ready for private subnet connectivity
  ]

  tags = {
    Name = "litellm-service"
  }
}