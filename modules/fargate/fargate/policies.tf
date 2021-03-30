# Task role assume policy
data "aws_iam_policy_document" "task_assume" {
  for_each = var.containers_definitions
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Task logging privileges
data "aws_iam_policy_document" "task_permissions" {
  for_each = var.containers_definitions
  statement {
    effect = "Allow"

    resources = [
      aws_cloudwatch_log_group.main[each.key].arn,
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

# Task ecr privileges
data "aws_iam_policy_document" "task_execution_permissions" {
  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

data "aws_kms_key" "secretsmanager_key" {
  for_each = { for i, z in var.containers_definitions : i => z if lookup(z, "repository_credentials_kms_key", "") != "" }
  key_id   = lookup(var.containers_definitions[each.key], "repository_credentials_kms_key", "")
}

data "aws_iam_policy_document" "read_repository_credentials" {
  for_each = { for i, z in var.containers_definitions : i => z if lookup(z, "repository_credentials_kms_key", "") != "" }
  statement {
    effect = "Allow"

    resources = [
      lookup(var.containers_definitions[each.key], "repository_credentials", ""),
      data.aws_kms_key.secretsmanager_key[each.key].arn,
    ]

    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
    ]
  }
}

