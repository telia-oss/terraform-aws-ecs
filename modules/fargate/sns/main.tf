module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 2.0"
  name    = var.sns_topic_name
}
