# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "service_arn" {
  description = "The Amazon Resource Name (ARN) that identifies the service."
  value       = "${module.service.service_arn}"
}

output "target_group_arn" {
  description = "The ARN of the Target Group."
  value       = "${module.service.target_group_arn}"
}

output "service_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the service role."
  value       = "${module.service.service_role_arn}"
}

output "service_role_name" {
  description = "The name of the service role."
  value       = "${module.service.service_name}"
}

output "task_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the task role."
  value       = "${module.service.task_role_arn}"
}

output "task_role_name" {
  description = "The name of the task role."
  value       = "${module.service.task_role_name}"
}
