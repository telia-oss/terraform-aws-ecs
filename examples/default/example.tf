provider "aws" {
  region = "eu-west-1"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = "${data.aws_vpc.main.id}"
}

data "aws_region" "current" {}

module "alb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "0.1.0"

  name_prefix = "example"
  vpc_id      = "${data.aws_vpc.main.id}"
  subnet_ids  = ["${data.aws_subnet_ids.main.ids}"]
  type        = "application"

  tags {
    environment = "prod"
    terraform   = "True"
  }
}

# ------------------------------------------------------------------------------
# ecs/cluster
# ------------------------------------------------------------------------------
module "cluster" {
  source = "../../modules/cluster"

  name_prefix  = "example"
  vpc_id       = "${data.aws_vpc.main.id}"
  subnet_ids   = ["${data.aws_subnet_ids.main.ids}"]
  instance_ami = "<ecs-optimizied>"

  tags {
    environment = "prod"
    terraform   = "True"
  }
}

# ------------------------------------------------------------------------------
# ecs/service: Create a service which responds with 404 as the default target
# ------------------------------------------------------------------------------
module "four_o_four" {
  source = "../../modules/service"

  name_prefix                        = "example-bouncer"
  vpc_id                             = "${data.aws_vpc.main.id}"
  cluster_id                         = "${module.cluster.id}"
  cluster_role_name                  = "${module.cluster.role_name}"
  desired_count                      = "1"
  task_definition_cpu                = "256"
  task_definition_memory_reservation = "512"
  task_definition_image              = "crccheck/hello-world:latest"

  target {
    protocol      = "HTTP"
    port          = "8000"
    load_balancer = "${module.alb.arn}"
  }

  health {
    port    = "traffic-port"
    path    = "/"
    matcher = "200"
  }

  tags {
    environment = "prod"
    terraform   = "True"
  }
}

# ------------------------------------------------------------------------------
# Create a default listener and open ingress on port 80 (target group from above)
# ------------------------------------------------------------------------------
resource "aws_lb_listener" "main" {
  load_balancer_arn = "${module.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${module.four_o_four.target_group_arn}"
    type             = "forward"
  }
}

resource "aws_security_group_rule" "ingress_80" {
  security_group_id = "${module.alb.security_group_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ------------------------------------------------------------------------------
# ecs/microservice: Creates a listener rule, target group and ECS service
# (any request to example.com/app/* will be sent to this service)
# ------------------------------------------------------------------------------
module "application" {
  source = "../../modules/microservice"

  name_prefix                        = "example-app"
  vpc_id                             = "${data.aws_vpc.main.id}"
  cluster_id                         = "${module.cluster.id}"
  cluster_role_name                  = "${module.cluster.role_name}"
  desired_count                      = "1"
  task_definition_image              = "crccheck/hello-world:latest"
  task_definition_cpu                = "256"
  task_definition_memory_reservation = "512"
  task_definition_command            = []

  task_definition_environment = {
    "TEST" = "VALUE"
  }

  listener_rule {
    listener_arn = "${aws_lb_listener.main.arn}"
    priority     = 90
    pattern      = "path"
    values       = "/app/*"
  }

  target {
    protocol      = "HTTP"
    port          = "8000"
    load_balancer = "${module.alb.arn}"
  }

  health {
    port    = "traffic-port"
    path    = "/"
    matcher = "200"
  }

  tags {
    environment = "prod"
    terraform   = "True"
  }
}

resource "aws_iam_role_policy" "task" {
  name   = "example-task-privileges"
  role   = "${module.application.task_role_name}"
  policy = "${data.aws_iam_policy_document.privileges.json}"
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
