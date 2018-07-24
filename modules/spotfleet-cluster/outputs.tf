# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "id" {
  description = "The Amazon Resource Name (ARN) that identifies the cluster."
  value       = "${aws_ecs_cluster.main.id}"
}

output "role_id" {
  description = "The name of the instance role."
  value       = "${module.spotfleet.role_id}"
}

output "role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the instance role."
  value       = "${module.spotfleet.role_arn}"
}

output "security_group_id" {
  description = "The name of the security group."
  value       = "${module.spotfleet.security_group_id}"
}
