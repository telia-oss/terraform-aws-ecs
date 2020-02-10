# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "vpc_id" {
  description = "The VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
}

variable "cluster_id" {
  description = "The Amazon Resource Name (ARN) that identifies the cluster."
  type        = string
}

variable "cluster_name" {
  description = "Name that identifies the cluster."
  type        = string
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

variable "containers_definitions" {
  description = "Container setting which is than passed to fargate ecs service"
  default     = {}
}

variable "alb_arn" {
  type        = string
  description = "ALB ARN"
}

variable "certificate_arn" {
  type        = string
  description = "ARN for certificate at ACM"
  default     = ""
}

variable "allowed_subnets" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "Subnets allowed to access the services and load balancer"
}

variable "allowed_sg" {
  type        = string
  description = "Allowed SG to ECS services, probably useful only for Load Balancer"
}
