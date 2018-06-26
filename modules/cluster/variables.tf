# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
variable "name_prefix" {
  description = "A prefix used for naming resources."
}

variable "vpc_id" {
  description = "The VPC ID."
}

variable "subnet_ids" {
  description = "ID of subnets where instances can be provisioned."
  type        = "list"
}

variable "instance_type" {
  description = "Type of instance to provision."
  default     = "t2.micro"
}

variable "instance_ami" {
  description = "The EC2 (ECS optimizied) image ID to launch."
}

variable "instance_key" {
  description = "The key name that should be used for the instance."
  default     = ""
}

variable "instance_volume_size" {
  description = "The size of the volume in gigabytes."
  default     = "8"
}

variable "docker_volume_size" {
  description = "The size of the docker volume (/dev/xvdcz) in gigabytes."
  default     = "22"
}

variable "min_size" {
  description = "The minimum (and desired) size of the cluster."
  default     = "1"
}

variable "max_size" {
  description = "The maximum size of the cluster."
  default     = "3"
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
  description = "NOTE: This exists purely to calculate count in Terraform. Should equal the length of your ingress map."
  default     = 0
}

variable "tags" {
  description = "A map of tags (key/value)."
  type        = "map"
  default     = {}
}
