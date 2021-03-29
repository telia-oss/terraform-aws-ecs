# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
data "aws_region" "current" {}

# HACK: This is the latest hack to work around this error:
# "The target group with targetGroupArn arn:aws:elasticloadbalancing:... does not have an associated load balancer."
# (See https://github.com/hashicorp/terraform/issues/12634.)
# Create a target group that references the real one and then depend on it in the aws_ecs_service definintion
data "aws_lb_target_group" "default" {
  arn = aws_lb_target_group.main.arn
}

resource "aws_lb_target_group" "main" {
  vpc_id      = var.vpc_id
  protocol    = var.target["protocol"]
  port        = var.target["port"]
  target_type = var.service_launch_type == "FARGATE" ? "ip" : "instance"

  health_check {
    enabled             = lookup(var.health_check, "enabled", null)
    interval            = lookup(var.health_check, "interval", null)
    path                = lookup(var.health_check, "path", null)
    port                = lookup(var.health_check, "port", null)
    protocol            = lookup(var.health_check, "protocol", null)
    timeout             = lookup(var.health_check, "timeout", null)
    healthy_threshold   = lookup(var.health_check, "healthy_threshold", null)
    unhealthy_threshold = lookup(var.health_check, "unhealthy_threshold", null)
    matcher             = lookup(var.health_check, "matcher", null)
  }

  # NOTE: TF is unable to destroy a target group while a listener is attached,
  # therefor we have to create a new one before destroying the old. This also means
  # we have to let it have a random name, and then tag it with the desired name.
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, map("Name", "${var.name_prefix}-target-${var.target["port"]}"))
}

resource "aws_ecs_service" "main" {

  depends_on                        = [data.aws_lb_target_group.default, aws_iam_role_policy.service_permissions]
  name                              = var.name_prefix
  cluster                           = var.cluster_id
  task_definition                   = aws_ecs_task_definition.main.arn
  desired_count                     = var.desired_count
  iam_role                          = var.service_launch_type == "FARGATE" ? null : aws_iam_role.service.arn
  health_check_grace_period_seconds = var.health_check_grace_period
  launch_type                       = var.service_launch_type

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  dynamic "network_configuration" {
    for_each = var.service_launch_type == "FARGATE" ? [1] : []
    content {
      subnets          = var.subnet_ids
      security_groups  = [var.security_groups_ecs_id]
      assign_public_ip = var.task_container_assign_public_ip
    }
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = var.name_prefix
    container_port   = var.target["port"]
  }


  dynamic "placement_constraints" {
    for_each = var.placement_constraint == "" ? [] : [1]
    content {
      type = var.placement_constraint
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = var.service_launch_type == "FARGATE" ? [] : [1]
    content {
      type  = "spread"
      field = "instanceId"
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registry_arn == "" ? [] : [1]
    content {
      registry_arn   = var.service_registry_arn
      container_port = var.target["port"]
      container_name = var.name_prefix
    }
  }
}


# NOTE: Takes a map of KEY = value and turns it into a list of: { name: KEY, value: value }.
locals {
  environment = [
    for k, v in var.task_container_environment :
    {
      name  = k
      value = v
    }
  ]
}


# NOTE: HostPort must be 0 to use dynamic port mapping when ec2 using.
resource "aws_ecs_task_definition" "main" {
  family                   = var.name_prefix
  task_role_arn            = aws_iam_role.task.arn
  cpu                      = var.service_launch_type == "FARGATE" ? var.task_container_cpu : null
  memory                   = var.service_launch_type == "FARGATE" ? var.task_container_memory_reservation : null
  execution_role_arn       = var.service_launch_type == "FARGATE" ? aws_iam_role.task.arn : null
  network_mode             = var.service_launch_type == "FARGATE" ? "awsvpc" : null
  requires_compatibilities = var.service_launch_type == "FARGATE" ? ["FARGATE"] : null
  container_definitions    = <<EOF
[{
    "name": "${var.name_prefix}",
    "image": "${var.task_container_image}",
    "cpu": ${var.task_container_cpu},
    "memoryReservation": ${var.task_container_memory_reservation},
    "essential": true,
    "portMappings": [{
      "HostPort": ${var.service_launch_type == "FARGATE" ? var.target["port"] : 0},
      "ContainerPort": ${var.target["port"]}
    }],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.main.name}",
            "awslogs-region": "${data.aws_region.current.name}",
            "awslogs-stream-prefix": "container"
        }
    },
    "stopTimeout": ${var.stop_timeout},
    "command": ${jsonencode(var.task_container_command)},
    "environment": ${jsonencode(local.environment)}
}]
EOF
}

# Logging group for the ECS agent
resource "aws_cloudwatch_log_group" "main" {
  name = var.name_prefix
}

resource "aws_iam_role" "service" {
  name               = "${var.name_prefix}-service-role"
  assume_role_policy = data.aws_iam_policy_document.service_assume.json
}

resource "aws_iam_role_policy" "service_permissions" {
  name   = "${var.name_prefix}-service-permissions"
  role   = aws_iam_role.service.id
  policy = data.aws_iam_policy_document.service_permissions.json
}

resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
}

resource "aws_iam_role_policy" "log_agent" {
  name   = "${var.name_prefix}-log-permissions"
  role   = var.cluster_role_name
  policy = data.aws_iam_policy_document.task_log.json
}
