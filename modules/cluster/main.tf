# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------
data "aws_region" "current" {}

resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-cluster"
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "${var.name_prefix}-cluster-instances"
  retention_in_days = var.log_retention_in_days
}

locals {
  cloud_config = templatefile("${path.module}/cloud-config.yml", {
    stack_name       = "${var.name_prefix}-cluster-asg"
    region           = data.aws_region.current.name
    log_group_name   = aws_cloudwatch_log_group.main.name
    ecs_cluster_name = aws_ecs_cluster.main.name
    ecs_log_level    = var.ecs_log_level
  })
}

data "aws_iam_policy_document" "permissions" {
  # TODO: Restrict privileges to specific ECS services.
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:ListContainerInstances",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:Submit*",
      "logs:CreateLogStream",
      "cloudwatch:PutMetricData",
      "ec2:DescribeTags",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "ssm:GetParameter",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      aws_cloudwatch_log_group.main.arn
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
    ]
  }
}

module "asg" {
  source               = "telia-oss/asg/aws"
  version              = "v3.3.1"
  name_prefix          = "${var.name_prefix}-cluster"
  user_data            = coalesce(var.user_data, local.cloud_config)
  vpc_id               = var.vpc_id
  subnet_ids           = var.subnet_ids
  await_signal         = "true"
  pause_time           = "PT5M"
  health_check_type    = "EC2"
  instance_policy      = data.aws_iam_policy_document.permissions.json
  min_size             = var.min_size
  max_size             = var.max_size
  instance_type        = var.instance_type
  instance_ami         = var.instance_ami
  instance_key         = var.instance_key
  instance_volume_size = var.instance_volume_size
  ebs_block_devices    = var.ebs_block_devices
  tags                 = var.tags
}

resource "aws_security_group_rule" "ingress" {
  count                    = var.load_balancer_count
  security_group_id        = module.asg.security_group_id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "32768"
  to_port                  = "65535"
  source_security_group_id = element(var.load_balancers, count.index)
}
