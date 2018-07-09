# ------------------------------------------------------------------------------
# Output
# ------------------------------------------------------------------------------
output "id" {
  value = "${aws_ecs_cluster.main.id}"
}

output "role_id" {
  value = "${module.spotfleet.role_id}"
}

output "role_arn" {
  value = "${module.spotfleet.role_arn}"
}

output "security_group_id" {
  value = "${module.spotfleet.security_group_id}"
}
