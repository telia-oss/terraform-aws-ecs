provider "aws" {
  region = "eu-west-3"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = data.aws_vpc.main.id
}

## Basic fargate cluster with monitoring and service from telia oss fargate module

module "basic_fargate" {
  source = "../../modules/fargate"

  name_prefix = "fargate-basic"
  vpc_id      = data.aws_vpc.main.id
  subnet_ids  = data.aws_subnet_ids.main.ids

  internal_elb = false

  tags = {
    environment = "dev"
  }
}

module "fargate_service" {
  source = "../../modules/fargate/service"

  name_prefix          = "hello-world"
  vpc_id               = data.aws_vpc.main.id
  private_subnet_ids   = data.aws_subnet_ids.main.ids
  lb_arn               = module.basic_fargate.load_balancer_arn
  cluster_id           = module.basic_fargate.cluster_id
  task_container_image = "crccheck/hello-world:latest"

  // public ip is needed for default vpc, default is false
  task_container_assign_public_ip = true

  // port, default protocol is HTTP
  task_container_port = 8000

  task_container_environment = {
    TEST_VARIABLE = "TEST_VALUE"
  }

  health_check = {
    port = "traffic-port"
    path = "/"
  }

  service_listner_rules = [
    {
      field = "host-header"
      values = [
      "hello-world.com"]
    }
  ]

  tags = {
    environment = "dev"
    terraform   = "True"
  }
}

## More complex example with container definitions in the same module
#
# Difference is that due to interpolation, you have to have only static values in containers_definitions map
#

resource "aws_ssm_parameter" "docker-tag" {
  name  = "nginx_docker_tag"
  type  = "String"
  value = "latest"
}

# this simulates where you can get the version of your docker image
data "aws_ssm_parameter" "docker-tag" {
  name       = "nginx_docker_tag"
  depends_on = [aws_ssm_parameter.docker-tag]
}


module "fargate" {
  source = "../../modules/fargate"

  name_prefix = "fargate"
  vpc_id      = data.aws_vpc.main.id
  subnet_ids  = data.aws_subnet_ids.main.ids

  internal_elb = false

  containers_definitions = {
    helloworld = {
      task_container_image            = "crccheck/hello-world:latest"
      task_container_assign_public_ip = true
      task_container_port             = 8000
      task_container_environment = [
        {
          name  = "TEST_VARIABLE"
          value = "TEST_VALUE"
        }
      ]
      health_check = {
        port = "traffic-port"
        path = "/"
      }
      task_tags = {
        terraform = "True"
      }
    }
    hellonginx = {
      task_container_image            = "nginx:${aws_ssm_parameter.docker-tag.value}"
      task_container_assign_public_ip = true
      task_container_port             = 80
      task_container_environment = [
        {
          name  = "TEST_VARIABLE"
          value = "TEST_VALUE"
        }
      ]
      health_check = {
        port = "traffic-port"
        path = "/"
      }
      task_tags = {
        terraform = "True"
      }

    }
  }
  tags = {
    environment = "dev"
  }
}

output "load_balancer_domain_fargate" {
  description = "Get DNS record of load balancer"
  value       = module.fargate.load_balancer_domain
}

output "load_balancer_domain_basic_fargate" {
  description = "Get DNS record of load balancer"
  value       = module.basic_fargate.load_balancer_domain
}
