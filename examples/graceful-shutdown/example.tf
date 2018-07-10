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

  name_prefix          = "example"
  vpc_id               = "${data.aws_vpc.main.id}"
  subnet_ids           = ["${data.aws_subnet_ids.main.ids}"]
  instance_ami         = "ami-c91624b0"
  instance_volume_size = "10"
  docker_volume_size   = "30"
  load_balancers       = ["${module.alb.security_group_id}"]
  load_balancer_count  = 1

  tags {
    environment = "prod"
    terraform   = "True"
  }
}

module "graceful-shutdown" {
  source = "github.com/itsdalmo/tf_aws_ecs_instance_draining_on_scale_in.git?ref=b87f60f"

  name_prefix            = "example"
  autoscaling_group_name = "${module.cluster.asg_id}"
}
