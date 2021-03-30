data "aws_iam_policy_document" "lambda_service_utilization_monitoring" {
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
      "elasticloadbalancing:*",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:*",
      "ecs:*",
    ]

    resources = [
      "*",
    ]
  }
}

data "archive_file" "lambda_service_utilization_monitoring-dotfiles" {
  type        = "zip"
  output_path = "${path.module}/lambda_service_utilization_monitoring.zip"

  source {
    content  = file("${path.module}/lambda_service_utilization_monitoring/main.py")
    filename = "main.py"
  }
}

module "alarm-lambda" {
  source = "../lambda"

  policy = data.aws_iam_policy_document.lambda_service_utilization_monitoring.json

  name_prefix = "${var.name_prefix}-monitoring"
  filename    = "${path.module}/lambda_service_utilization_monitoring.zip"

  environment = {
    ECS_CLUSTER        = "${var.name_prefix}-cluster"
    SNS_ALERT_TOPIC    = var.sns_notification_topic
    EVALUATION_PERIODS = var.ecs_service_alerts_evaluation_periods
    ECS_REGION_NAME    = var.default_region
  }

  handler = "main.lambda_handler"
  runtime = "python3.6"

  tags = var.tags
}

resource "aws_lambda_permission" "cloudwatch_services_alarm" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.alarm-lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_services_alarm.arn
}

resource "aws_cloudwatch_event_rule" "lambda_services_alarm" {
  name                = module.alarm-lambda.name
  schedule_expression = "rate(15 minutes)"
}

#alarm
resource "aws_cloudwatch_event_target" "lambda_services_alarm" {
  target_id = module.alarm-lambda.name
  rule      = aws_cloudwatch_event_rule.lambda_services_alarm.name
  arn       = module.alarm-lambda.arn
}
