# ------------------------------------------------------------------------------
# AWS
# ------------------------------------------------------------------------------
data "aws_region" "current" {}

# ------------------------------------------------------------------------------
# IAM - Task execution role, needed to pull ECR images etc.
# ------------------------------------------------------------------------------
resource "aws_iam_role" "execution" {
  name               = "${var.name_prefix}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
}

resource "aws_iam_role_policy" "task_execution" {
  name   = "${var.name_prefix}-task-execution"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.task_execution_permissions.json
}

resource "aws_iam_role_policy" "read_repository_credentials" {
  count  = length(var.repository_credentials) != 0 ? 1 : 0
  name   = "${var.name_prefix}-read-repository-credentials"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_repository_credentials.json
}

# ------------------------------------------------------------------------------
# Security groups
# ------------------------------------------------------------------------------
resource "aws_security_group" "ecs_service" {
  vpc_id      = var.vpc_id
  name        = "${var.name_prefix}-ecs-service-sg"
  description = "Fargate service security group"
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-sg"
    },
  )
}

resource "aws_security_group_rule" "egress_service" {
  security_group_id = aws_security_group.ecs_service.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "ingress_service" {
  security_group_id = aws_security_group.ecs_service.id
  type              = "ingress"
  protocol          = "-1"
  from_port         = var.task_container_port
  to_port           = var.task_container_port
  cidr_blocks       = var.allowed_subnets
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = var.lb_arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Default fixed response content"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn == "" ? 0 : 1
  load_balancer_arn = var.lb_arn
  port              = 443
  protocol          = "HTTPS"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Default fixed response content"
      status_code  = "200"
    }
  }
  certificate_arn = var.certificate_arn
}

resource "aws_lb_listener_rule" "routing_https" {
  count        = var.certificate_arn == "" ? 0 : 1
  listener_arn = join("", aws_lb_listener.https.*.arn)

  depends_on = [null_resource.lb_exists]

  action {
    type             = "forward"
    target_group_arn = module.service.target_group_arn
  }

  dynamic "condition" {
    for_each = var.service_listner_rules
    content {
      field  = condition.value.field
      values = condition.value.values
    }
  }
}

resource "aws_lb_listener_rule" "routing_http" {
  listener_arn = aws_lb_listener.http.arn

  depends_on = [null_resource.lb_exists]

  action {
    type             = "forward"
    target_group_arn = module.service.target_group_arn
  }

  dynamic "condition" {
    for_each = var.service_listner_rules
    content {
      field  = condition.value.field
      values = condition.value.values
    }
  }
}

# ------------------------------------------------------------------------------
# ECS Task/Service
# ------------------------------------------------------------------------------
module "service" {
  source = "../../service"

  cluster_id = var.cluster_id
  cluster_role_name = module.service.task_role_name
  health_check = var.health_check
  name_prefix = var.name_prefix
  service_launch_type = "FARGATE"
  security_groups_ecs_id = aws_security_group.ecs_service.id
  task_container_assign_public_ip = var.task_container_assign_public_ip
  subnet_ids = var.private_subnet_ids
  target = {
    protocol      = "HTTP"
    port          = var.task_container_port
    load_balancer = var.lb_arn
  }
  task_container_image = var.task_container_image
  vpc_id = var.vpc_id
  task_container_environment = var.task_container_environment
}

# HACK: The workaround used in ecs/service does not work for some reason in this module, this fixes the following error:
# "The target group with targetGroupArn arn:aws:elasticloadbalancing:... does not have an associated load balancer."
# see https://github.com/hashicorp/terraform/issues/12634.
# Service depends on this resources which prevents it from being created until the LB is ready
resource "null_resource" "lb_exists" {
  triggers = {
    alb_name = var.lb_arn
  }
}
