variable "name_prefix" {
  type        = string
  description = "Name prefix for lambda monitorings"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources"
  type        = map(string)
  default     = {}
}

variable "ecs_service_alerts_evaluation_periods" {
  description = "How many periods should alerts at ECS service cross the threshold to be triggered"
  default     = 5
  type        = number
}

variable "sns_notification_topic" {
  description = "SNS notification topic for alerting messages from user_data scripts"
  default     = ""
  type        = string
}

variable "default_region" {
  default     = "eu-west-1"
  description = "Default region to be used in Lambda functions"
  type        = string
}