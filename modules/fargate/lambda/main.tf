resource "random_string" "lambda_postfix_generator" {
  length  = 4
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${module.lambda.name}"
  retention_in_days = var.log_retention_in_days
}

module "lambda" {
  source      = "git::https://github.com/telia-oss/terraform-aws-lambda"
  name_prefix = var.name_prefix
  filename    = var.filename
  policy      = var.policy
  runtime     = var.runtime
  handler     = var.handler
  environment = var.environment
  tags        = var.tags
}

