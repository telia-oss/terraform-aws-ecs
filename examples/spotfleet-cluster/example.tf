# ------------------------------------------------------------------------------
# ecs/spotfleet-cluster
# ------------------------------------------------------------------------------
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

module "spotfleet-cluster" {
  source              = "../../modules/spotfleet-cluster"
  target_capacity     = "2"
  name_prefix         = "example"
  vpc_id              = "${data.aws_vpc.main.id}"
  subnet_ids          = ["${data.aws_subnet_ids.main.ids}"]
  instance_ami        = "${data.aws_ami.ecs.id}"
  load_balancer_count = 0

  tags {
    environment = "prod"
    terraform   = "True"
  }
}
