resource "aws_ecs_service" "litellm_service" {
  name              = "litellm-service"
  cluster           = aws_ecs_cluster.litellm_cluster.id
  task_definition   = aws_ecs_task_definition.litellm_task.arn
  desired_count     = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = [
      aws_default_subnet.ecs_az1.id,
      aws_default_subnet.ecs_az2.id,
      aws_default_subnet.ecs_az3.id
    ]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  health_check_grace_period_seconds = 300

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  depends_on = [
    aws_iam_role_policy_attachment.litellm_task_execution_role_policy,
    aws_db_instance.litellm_db,
    aws_elasticache_cluster.litellm_redis
  ]

  tags = {
    Name = "litellm-service"
  }
}