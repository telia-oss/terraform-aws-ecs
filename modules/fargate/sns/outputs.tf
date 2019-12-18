output "this_sns_topic_arn" {
  description = "SNS topic ARN for potential subscriptions"
  value       = module.sns_topic.this_sns_topic_arn
}

output "this_sns_topic_name" {
  description = "SNS topic name"
  value       = var.sns_topic_name
}
