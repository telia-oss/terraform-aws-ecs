data "aws_iam_policy_document" "lambda_services_dashboard" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:*",
      "cloudwatch:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:*",
      "ecs:*",
      "elasticloadbalancing:*",
    ]

    resources = [
      "*",
    ]
  }
}

module "dashboard-lambda" {
  source = "../lambda"

  policy = data.aws_iam_policy_document.lambda_services_dashboard.json

  name_prefix = "${var.name_prefix}-dashboards"
  filename    = "${path.module}/lambda_services_dashboard.zip"

  environment = {
    ECS_CLUSTER     = "${var.name_prefix}-cluster"
    ECS_REGION_NAME = var.default_region
  }

  handler = "main.lambda_handler"
  runtime = "python3.6"

  tags = var.tags
}

resource "aws_lambda_permission" "cloudwatch_services_dashboard" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.dashboard-lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_services_dashboard.arn
}

resource "aws_cloudwatch_event_rule" "lambda_services_dashboard" {
  name                = module.dashboard-lambda.name
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_services_dashboard" {
  target_id = module.dashboard-lambda.name
  rule      = aws_cloudwatch_event_rule.lambda_services_dashboard.name
  arn       = module.dashboard-lambda.arn
}
