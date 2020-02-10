data "aws_region" "current" {}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.name_prefix}-cluster"
}

resource "random_string" "random" {
  length  = 4
  upper   = true
  lower   = true
  number  = true
  special = false
}

module "fargate_alb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "3.0.0"

  name_prefix = "${var.name_prefix}-${random_string.random.result}"
  type        = "application"
  internal    = var.internal_elb
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  tags = var.tags
}

resource "aws_security_group_rule" "ingress_http" {
  security_group_id = module.fargate_alb.security_group_id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = var.allowed_subnets.ipv4
  ipv6_cidr_blocks  = var.allowed_subnets.ipv6
}

resource "aws_security_group_rule" "ingress_https" {
  security_group_id = module.fargate_alb.security_group_id
  type              = "ingress"
  protocol          = "TCP"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = var.allowed_subnets.ipv4
  ipv6_cidr_blocks  = var.allowed_subnets.ipv6
}

module "ecs-fargate" {
  source = "./fargate/"

  cluster_name           = "${var.name_prefix}-cluster"
  cluster_id             = aws_ecs_cluster.cluster.id
  containers_definitions = var.containers_definitions

  alb_arn = module.fargate_alb.arn

  vpc_id             = var.vpc_id
  private_subnet_ids = var.subnet_ids
  allowed_sg         = module.fargate_alb.security_group_id
  allowed_subnets    = concat(var.allowed_subnets.ipv4)
}

module "monitoring_sns_topic" {
  source = "./sns"

  sns_topic_name = "${var.name_prefix}-cluster-sns-monitoring-topic"
}

module "monitoring" {
  source = "./monitoring"

  sns_notification_topic = module.monitoring_sns_topic.this_sns_topic_arn
  name_prefix            = var.name_prefix
  default_region         = data.aws_region.current.name
}
