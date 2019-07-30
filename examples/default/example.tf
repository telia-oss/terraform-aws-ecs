provider "aws" {
  version = ">= 1.33.0"
  region  = "eu-west-1"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

data "aws_region" "current" {}

module "alb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "v2.0.0"

  name_prefix = "example"
  vpc_id      = data.aws_vpc.main.id
  subnet_ids  = data.aws_subnet_ids.main.ids
  type        = "application"

  tags = {
    environment = "prod"
    terraform   = "True"
  }
}

# ------------------------------------------------------------------------------
# ecs/cluster
# ------------------------------------------------------------------------------
data "aws_ami" "ecs" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["amzn-ami*amazon-ecs-optimized"]
  }
}

module "cluster" {
  source = "./terraform-aws-ecs/modules/cluster"

  name_prefix         = "example"
  vpc_id              = data.aws_vpc.main.id
  subnet_ids          = data.aws_subnet_ids.main.ids
  instance_ami        = data.aws_ami.ecs.id
  load_balancers      = [module.alb.security_group_id]
  load_balancer_count = 1

  tags = {
    environment = "prod"
    terraform   = "True"
  }
}

# ------------------------------------------------------------------------------
# Create a default listener and open ingress on port 80 (target group from above)
# ------------------------------------------------------------------------------
resource "aws_lb_listener" "main" {
  load_balancer_arn = module.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "not found"
      status_code  = "404"
    }
  }
}

resource "aws_security_group_rule" "ingress_80" {
  security_group_id = module.alb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ------------------------------------------------------------------------------
# ecs/service: Creates the ECS service and target group, listener rule has to be
# added. (any request to example.com/app/* will be sent to this service)
# ------------------------------------------------------------------------------
module "application" {
  source = "../../modules/service"

  name_prefix                       = "example-app"
  vpc_id                            = data.aws_vpc.main.id
  cluster_id                        = module.cluster.id
  cluster_role_name                 = module.cluster.role_namr
  desired_count                     = 1
  task_container_image              = "crccheck/hello-world:latest"
  task_container_cpu                = 128
  task_container_memory_reservation = 256
  task_container_command            = []
  task_container_environment_count  = 1

  task_container_environment = {
    "TEST" = "VALUE"
  }

  target {
    protocol      = "HTTP"
    port          = 8000
    load_balancer = module.alb.arn
  }

  health_check = [{
    port    = "traffic-port"
    path    = "/"
    matcher = "200"

    healthy_threshold   = null
    interval            = null
    protocol            = null
    timeout             = null
    unhealthy_threshold = null
  }]

  tags = {
    environment = "prod"
    terraform   = "True"
  }
}

resource "aws_lb_listener_rule" "application" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 90

  action {
    type             = "forward"
    target_group_arn = module.application.target_group_arn
  }

  condition {
    field  = "path-pattern"
    values = ["/app/*"]
  }
}

resource "aws_iam_role_policy" "task" {
  name   = "example-task-privileges"
  role   = module.application.task_role_name
  policy = data.aws_iam_policy_document.privileges.json
}

data "aws_iam_policy_document" "privileges" {
  statement {
    effect = "Deny"

    not_actions = [
      "*",
    ]

    not_resources = [
      "*",
    ]
  }
}
