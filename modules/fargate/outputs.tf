output "target_group_arn" {
  description = "The ARN of the Target Group."
  value       = module.ecs-fargate.target_group_arn
}

output "target_group_name" {
  description = "The Name of the Target Groups."
  value       = module.ecs-fargate.target_group_name
}

output "task_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the service role."
  value       = module.ecs-fargate.task_role_arn
}

output "task_role_name" {
  description = "The name of the service role."
  value       = module.ecs-fargate.task_role_name
}

output "service_sg_id" {
  description = "The Amazon Resource Name (ARN) that identifies the service security group."
  value       = module.ecs-fargate.service_sg_id
}

output "service_name" {
  description = "The name of the service."
  value       = module.ecs-fargate.service_name
}

output "service_arn" {
  description = "The Amazon Resource Name (ARN) that identifies the service."
  value       = module.ecs-fargate.service_arn
}

output "log_group_name" {
  description = "The name of the Cloudwatch log group for the task."
  value       = module.ecs-fargate.log_group_name
}

output "sns_topic_arn" {
  description = "SNS topic to subscribe for alerts"
  value       = module.monitoring_sns_topic.this_sns_topic_arn
}

output "load_balancer_domain" {
  description = "Get DNS record of load balancer"
  value       = module.fargate_alb.dns_name
}

output "load_balancer_arn" {
  description = "Get ARN of load balancer"
  value       = module.fargate_alb.arn
}

output "cluster_id" {
  description = "Id of ECS cluster"
  value       = aws_ecs_cluster.cluster.id
}
