# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
}

variable "vpc_id" {
  description = "The VPC ID."
}

variable "cluster_id" {
  description = "The Amazon Resource Name (ARN) that identifies the cluster."
}

variable "cluster_role_name" {
  description = "The name of the clusters instance role."
}

variable "listener_rule" {
  description = "Listener rule block containing the listener arn, type and values."
  type        = "map"
}

variable "target" {
  description = "A target block containing the protocol and port exposed on the container."
  type        = "map"
}

variable "health_check" {
  description = "A health block containing health check settings for the target group. Overrides the defaults."
  type        = "map"
}

variable "health_check_grace_period" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200."
  default     = "0"
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running."
  default     = "1"
}

variable "task_container_image" {
  description = "The image used to start a container."
}

variable "task_container_cpu" {
  description = "The number of cpu units reserved for the container."
  default     = "256"
}

variable "task_container_memory_reservation" {
  description = "The soft limit (in MiB) of memory to reserve for the container."
  default     = "512"
}

variable "task_container_command" {
  description = "The command that is passed to the container."
  default     = []
}

variable "task_container_environment" {
  description = "The environment variables to pass to a container."
  default     = {}
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = "map"
  default     = {}
}
