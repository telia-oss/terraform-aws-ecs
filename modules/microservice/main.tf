# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
module "service" {
  source = "../service"

  name_prefix                               = "${var.name_prefix}"
  vpc_id                                    = "${var.vpc_id}"
  cluster_id                                = "${var.cluster_id}"
  cluster_role_name                         = "${var.cluster_role_name}"
  desired_count                             = "${var.desired_count}"
  task_definition_cpu                       = "${var.task_definition_cpu}"
  task_definition_memory_reservation        = "${var.task_definition_memory_reservation}"
  task_definition_image                     = "${var.task_definition_image}"
  task_definition_command                   = "${var.task_definition_command}"
  task_definition_environment               = "${var.task_definition_environment}"
  task_definition_health_check_grace_period = "${var.task_definition_health_check_grace_period}"
  health                                    = "${var.health}"

  target {
    protocol      = "${var.target["protocol"]}"
    port          = "${var.target["port"]}"
    load_balancer = "${var.target["load_balancer"]}"
  }

  tags = "${var.tags}"
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = "${var.listener_rule["listener_arn"]}"
  priority     = "${lookup(var.listener_rule, "priority", 100)}"

  action {
    type             = "forward"
    target_group_arn = "${module.service.target_group_arn}"
  }

  condition {
    field  = "${var.listener_rule["pattern"]}-pattern"
    values = ["${var.listener_rule["values"]}"]
  }
}
