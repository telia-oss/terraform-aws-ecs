# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "service_arn" {
  description = "The Amazon Resource Name (ARN) that identifies the service."
  value       = aws_ecs_service.main.id
}

output "target_group_arn" {
  description = "The ARN of the Target Group."
  value       = aws_lb_target_group.main.arn
}

output "service_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the service role."
  value       = aws_iam_role.service.arn
}

output "service_role_name" {
  description = "The name of the service role."
  value       = aws_iam_role.service.name
}

output "task_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the task role."
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "The name of the task role."
  value       = aws_iam_role.task.name
}

output "service_sg_id" {
  description = "The security group id"
  value       = aws_security_group.ecs_service.id
}
