variable "name_prefix" {
  description = "A prefix used for naming resources."
}

variable "target_capacity" {
  description = "The target capacity of the request - in vCPUs"
}

variable "vpc_id" {
  description = "The VPC ID."
}

variable "subnet_ids" {
  description = "ID of subnets where instances can be provisioned."
  type        = "list"
}

variable "pre-defined-spotrequest" {
  description = "Which pre defined spot request list to use: small, small-ipv6, medium, medium-ipv6, large, large-ipv6"
  default     = "small"
}

variable "spot_price" {
  description = "The maximum price per unit (vCPU) - default is set to roughly on demand price"
  default     = "0.05"
}

variable "allocation_strategy" {
  description = "Allocation stragegy either lowestPrice or diversified"
  default     = "lowestPrice"
}

variable "instance_ami" {
  description = "The EC2 image ID to launch. - default is Amazon ESC-optimized AMI in eu-west-1"
  default     = "ami-921423eb"
}

variable "valid_until" {
  description = "Valid to date for the spot requests - after this date instances will not be replaced"
  default     = "2028-05-03T00:00:00Z"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = "map"
  default     = {}
}

variable "ecs_log_level" {
  description = "Log level for the ECS agent."
  default     = "info"
}

variable "load_balancers" {
  description = "List of load balancer security groups that can ingress on the dynamic port range."
  type        = "list"
  default     = []
}

variable "load_balancer_count" {
  description = "HACK: This exists purely to calculate count in Terraform. Should equal the length of your ingress map."
  default     = 0
}

# Hack to overcome that count variables cannot be inferred
variable "subnet_count" {
  description = "For future use: count of subnets - current predefined spot requests are for 3 subnets"
  default     = 3
}
