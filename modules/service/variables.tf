# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID."
  type        = string
}

variable "cluster_id" {
  description = "The Amazon Resource Name (ARN) that identifies the cluster."
  type        = string
}

variable "cluster_role_name" {
  description = "The name of the clusters instance role."
  type        = string
}

variable "placement_constraint" {
  default     = ""
  description = "The type of constraint. The only valid values at this time are memberOf and distinctInstance."
  type        = string
}

variable "target" {
  description = "A target block containing the protocol and port exposed on the container."
  type        = map(string)
}

variable "health_check" {
  description = "A health block containing health check settings for the target group. Overrides the defaults."
  type        = map(string)
}

variable "health_check_grace_period" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200."
  default     = 0
  type        = number
}

variable "stop_timeout" {
  default     = 30
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own. The default is 30 seconds."
  type        = number
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running."
  default     = 1
  type        = number
}

variable "task_container_image" {
  description = "The image used to start a container."
  type        = string
}

variable "task_container_cpu" {
  description = "The number of cpu units reserved for the container."
  default     = 256
  type        = number
}

variable "task_container_memory_reservation" {
  description = "The soft limit (in MiB) of memory to reserve for the container."
  default     = 512
  type        = number
}

variable "task_container_command" {
  description = "The command that is passed to the container."
  default     = []
  type        = list(string)
}

variable "task_container_environment" {
  description = "The environment variables to pass to a container."
  default     = {}
  type        = map(string)
}

variable "task_container_environment_count" {
  description = "NOTE: This exists purely to calculate count in Terraform. Should equal the length of your environment map."
  default     = 0
  type        = number
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

variable "service_registry_arn" {
  default     = ""
  description = "ARN of aws_service_discovery_service resource"
  type        = string
}

variable "service_launch_type" {
  default = "EC2"
  description = "The launch type on which to run your service. The valid values are EC2 and FARGATE. Defaults to EC2."
  type = string
}

variable "subnet_ids" {
  default = []
  description = "A list of subnets inside the VPC"
  type        = list(string)
}

variable "security_groups_ecs_id" {
  default = ""
  description = "ID of secure group for ecs"
  type = string
}

variable "task_container_assign_public_ip" {
  description = "Assigned public IP to the container."
  default     = false
  type        = bool
}
