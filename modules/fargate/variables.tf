variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "name_prefix" {
  type        = string
  description = "Name prefix for fargate cluster"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources"
  type        = map(string)
  default     = {}
}

variable "internal_elb" {
  default     = true
  type        = bool
  description = "If used, load balancer will be only for internal use"
}

variable "containers_definitions" {
  description = "Container setting which is than passed to fargate ecs service"
  default     = {}
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs used for load balancer"
  default     = []
}

variable "certificate_arn" {
  type        = string
  description = "ARN for certificate at ACM required for HTTPS listener"
  default     = ""
}

variable "allowed_subnets" {
  type = map(list(string))
  default = {
    ipv4 = ["0.0.0.0/0"]
    ipv6 = ["::/0"]
  }
  description = "Subnets allowed to access the services and load balancer"
}
