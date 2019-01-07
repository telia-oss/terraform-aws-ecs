# ------------------------------------------------------------------------------
# ecs/spotfleet-cluster
# ------------------------------------------------------------------------------
terraform {
  required_version = "0.11.11"

  backend "s3" {
    key            = "terraform-modules/development/terraform-aws-ecs/spotfleet-cluster.tfstate"
    bucket         = "<test-account-id>-terraform-state"
    dynamodb_table = "<test-account-id>-terraform-state"
    acl            = "bucket-owner-full-control"
    encrypt        = "true"
    kms_key_id     = "<kms-key-id>"
    region         = "eu-west-1"
  }
}

provider "aws" {
  version             = "1.52.0"
  region              = "eu-west-1"
  allowed_account_ids = ["<test-account-id>"]
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
  name_prefix         = "spotfleet-cluster-test"
  vpc_id              = "${data.aws_vpc.main.id}"
  subnet_ids          = ["${data.aws_subnet_ids.main.ids}"]
  instance_ami        = "${data.aws_ami.ecs.id}"
  load_balancer_count = 0

  tags {
    environment = "test"
    terraform   = "True"
  }
}

output "spotfleet_request_id" {
  value = "${module.spotfleet-cluster.spotfleet_request_id}"
}