# Task role assume policy
data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
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
  key_id = var.repository_credentials_kms_key
}

data "aws_iam_policy_document" "read_repository_credentials" {
  statement {
    effect = "Allow"

    resources = [
      var.repository_credentials,
      data.aws_kms_key.secretsmanager_key.arn,
    ]

    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
    ]
  }
}

