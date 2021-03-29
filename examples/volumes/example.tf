terraform {
  required_version = ">= 0.14"
}

provider "aws" {
  region = "eu-west-1"
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
  version = "v3.0.0"

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
  source = "../../modules/cluster"

  name_prefix          = "example"
  vpc_id               = data.aws_vpc.main.id
  subnet_ids           = data.aws_subnet_ids.main.ids
  instance_ami         = data.aws_ami.ecs.id
  instance_volume_size = "10"

  ebs_block_devices = [
    {
      device_name           = "/dev/xvdcz"
      volume_type           = "gp2"
      volume_size           = "30"
      delete_on_termination = true
    },
  ]

  load_balancers      = [module.alb.security_group_id]
  load_balancer_count = 1

  tags = {
    environment = "prod"
    terraform   = "True"
  }
}
