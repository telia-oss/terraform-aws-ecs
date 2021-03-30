
resource "aws_appautoscaling_target" "ecs_target" {
  for_each = { for i, z in var.containers_definitions : i => z if lookup(z, "scaling_enable", false) == true }

  max_capacity       = lookup(var.containers_definitions[each.key], "scaling_max_capacity", 4)
  min_capacity       = lookup(var.containers_definitions[each.key], "scaling_min_capacity", 1)
  resource_id        = "service/${var.cluster_name}/${each.key}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_scaling_policy" {
  for_each = { for i, z in var.containers_definitions : i => z if lookup(z, "scaling_enable", false) == true }

  name               = "${each.key}:${lookup(var.containers_definitions[each.key], "scaling_metric", "ECSServiceAverageCPUUtilization")}:${aws_appautoscaling_target.ecs_target[each.key].resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = lookup(var.containers_definitions[each.key], "scaling_metric", "ECSServiceAverageCPUUtilization")
    }

    target_value = lookup(var.containers_definitions[each.key], "scaling_target_value", 70)
  }
}
