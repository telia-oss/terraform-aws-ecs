# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "id" {
  description = "The Amazon Resource Name (ARN) that identifies the cluster."
  value       = aws_ecs_cluster.main.id
}

output "asg_id" {
  description = "The autoscaling group id (name)."
  value       = module.asg.id
}

output "role_name" {
  description = "The name of the instance role."
  value       = module.asg.role_name
}

output "role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the instance role."
  value       = module.asg.role_arn
}

output "security_group_id" {
  description = ""
  value       = module.asg.security_group_id
}
