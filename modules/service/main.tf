# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
data "aws_region" "current" {}

# HACK: This is the latest hack to work around this error:
# "The target group with targetGroupArn arn:aws:elasticloadbalancing:... does not have an associated load balancer."
# (See https://github.com/hashicorp/terraform/issues/12634.)
# Create a target group that references the real one and then depend on it in the aws_ecs_service definintion
data "aws_lb_target_group" "default" {
  arn = "${aws_lb_target_group.main.arn}"
}

resource "aws_lb_target_group" "main" {
  vpc_id       = "${var.vpc_id}"
  protocol     = "${var.target["protocol"]}"
  port         = "${var.target["port"]}"
  health_check = ["${var.health_check}"]

  # NOTE: TF is unable to destroy a target group while a listener is attached,
  # therefor we have to create a new one before destroying the old. This also means
  # we have to let it have a random name, and then tag it with the desired name.
  lifecycle {
    create_before_destroy = true
  }

  tags = "${merge(var.tags, map("Name", "${var.name_prefix}-target-${var.target["port"]}"))}"
}

resource "aws_ecs_service" "main" {
  depends_on                        = ["data.aws_lb_target_group.default", "aws_iam_role_policy.service_permissions"]
  name                              = "${var.name_prefix}"
  cluster                           = "${var.cluster_id}"
  task_definition                   = "${aws_ecs_task_definition.main.arn}"
  desired_count                     = "${var.desired_count}"
  iam_role                          = "${aws_iam_role.service.arn}"
  health_check_grace_period_seconds = "${var.health_check_grace_period}"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  load_balancer {
    target_group_arn = "${aws_lb_target_group.main.arn}"
    container_name   = "${var.name_prefix}"
    container_port   = "${var.target["port"]}"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
}

# NOTE: Takes a map of KEY = value and turns it into a list of: { name: KEY, value: value }.
data "null_data_source" "environment" {
  count = "${var.task_container_environment_count}"

  inputs = {
    name  = "${element(keys(var.task_container_environment), count.index)}"
    value = "${element(values(var.task_container_environment), count.index)}"
  }
}

# NOTE: HostPort must be 0 to use dynamic port mapping.
resource "aws_ecs_task_definition" "main" {
  family        = "${var.name_prefix}"
  task_role_arn = "${aws_iam_role.task.arn}"

  container_definitions = <<EOF
[{
    "name": "${var.name_prefix}",
    "image": "${var.task_container_image}",
    "cpu": ${var.task_container_cpu},
    "memoryReservation": ${var.task_container_memory_reservation},
    "networkMode" : "${var.networkMode}""
    "essential": true,
    "portMappings": [{
      "HostPort": 0,
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
    "command": ${jsonencode(var.task_container_command)},
    "environment": ${jsonencode(data.null_data_source.environment.*.outputs)}
}]
EOF
}

# Logging group for the ECS agent
resource "aws_cloudwatch_log_group" "main" {
  name = "${var.name_prefix}"
}

resource "aws_iam_role" "service" {
  name               = "${var.name_prefix}-service-role"
  assume_role_policy = "${data.aws_iam_policy_document.service_assume.json}"
}

resource "aws_iam_role_policy" "service_permissions" {
  name   = "${var.name_prefix}-service-permissions"
  role   = "${aws_iam_role.service.id}"
  policy = "${data.aws_iam_policy_document.service_permissions.json}"
}

resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-task-role"
  assume_role_policy = "${data.aws_iam_policy_document.task_assume.json}"
}

resource "aws_iam_role_policy" "log_agent" {
  name   = "${var.name_prefix}-log-permissions"
  role   = "${var.cluster_role_name}"
  policy = "${data.aws_iam_policy_document.task_log.json}"
}
