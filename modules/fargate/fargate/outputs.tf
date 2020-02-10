# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "target_group_arn" {
  description = "The ARN of the Target Group."
  value       = { for i, z in aws_lb_target_group.task : i => z.arn }
}

output "target_group_name" {
  description = "The Name of the Target Groups."
  value       = { for i, z in aws_lb_target_group.task : i => z.name }
}

output "task_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the service role."
  value       = { for i, z in aws_iam_role.task : i => z.arn }
}

output "task_role_name" {
  description = "The name of the service role."
  value       = { for i, z in aws_iam_role.task : i => z.name }
}

output "service_sg_id" {
  description = "The Amazon Resource Name (ARN) that identifies the service security group."
  value       = { for i, z in aws_security_group.ecs_service : i => z.id }
}

output "service_name" {
  description = "The name of the service."
  value       = { for i, z in aws_ecs_service.service : i => z.name }
}

output "service_arn" {
  description = "The Amazon Resource Name (ARN) that identifies the service."
  value       = { for i, z in aws_ecs_service.service : i => z.id }
}

output "log_group_name" {
  description = "The name of the Cloudwatch log group for the task."
  value       = { for i, z in aws_cloudwatch_log_group.main : i => z.name }
}

