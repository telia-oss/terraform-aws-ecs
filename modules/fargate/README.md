# A Terraform module to create a Fargate cluster

A terraform module providing a Fargate cluster in AWS.

This module:

- Creates an AWS Application load balancer
- Populate it with listeners
- Creates target groups
- Creates Fargate cluster
- Creates AWS ECS Services with tasks at Fargate cluster
- Creates Lambda functions for dynamic creation of alerts and dashboards at CloudWatch

This module was strongly inspired by https://github.com/telia-oss/terraform-aws-ecs-fargate

# Diagram of created resources

![Resources](https://raw.githubusercontent.com/lukaspour/tf_aws_ecs_fargate/master/fargate.png)

## Usage

For further information see example folder

```hcl
module "fargate" {
  source = "../"

  name_prefix = "fargate-test-cluster"
  vpc_id      = data.aws_vpc.main.id
  subnet_ids  = data.aws_subnet_ids.main.ids

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
      task_container_image            = "nginx:latest"
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
```


## var.containers\_definitions

This is a special map of arguments needed for definition of tasks and services:

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| tags\_tags | A map of tags (key-value pairs) passed to resources | map(string) | {} | no |
| task\_log\_retention\_in\_days | Days TTL before logs are dropped from cloudwatch | number | 30 | no |
| task\_container\_name | Name of container, if not used, key of service is used | string | key of container\_definitions | no |
| task\_container\_image | Name of image used for task | string | nginx | no |
| task\_definition\_cpu | Amount of CPU units for a task | number | 256 | no |
| task\_definition\_memory | Amount of memory units for a task | number | 1024 | no |
| task\_container\_command | Docker command of a task | list(string) | [] | no | 
| task\_container\_environment | Docker ENV variables of a task | list(string) | [] | no |
| task\_repository\_credentials | KMS credentials for access to docker image registry | string | null | no |
| task\_container\_assign\_public\_ip | If task should have public IP address | bool | null | no |
| task\_container\_port | Port to be exported from container | number | null | yes |
| deployment\_minimum\_healthy\_percent | Minimum healthy tasks in deployment | number | 50 | no |
| deployment\_maximum\_percent | Maximum healthy tasks in deployment | number | 200 | no |
| health\_check\_grace\_period\_seconds | Health check grace period | number | 300 | no |
| task\_desired\_count | Desired count of running tasks | number | 1 | no |
| service\_registry\_arn | See resource aws\_ecs\_service service\_registries | string | null | no |
| deployment\_controller\_type | See resource aws\_ecs\_service deployment\_controller\_type | string | ECS | no | 
| rule\_field | Listener rule field used in load balancer listener | string | host-header | no |
| rule\_values | Listener rule value used in load balancer listener | string | "${each.key}.com" | no |
| health\_check | Map of health check attributes, see aws\_lb\_target\_group health\_check resource | map(string) | {} | no |
| scaling\_enable | Enable scaling for the task | bool | false | no |
| scaling\_max\_capacity | Scaling max task number | number | 4 | no |
| scaling\_min\_capacity | Scaling min task number | number | 1 | no |
| scaling\_metric | Enable scaling for the task | string ECSServiceAverageCPUUtilization or ECSServiceAverageMemoryUtilization | ECSServiceAverageCPUUtilization | no |
| scaling\_target\_value | Threshold to be reached to scale up/down | number | 70 | no |

# This module 

Provider Requirements:
* **aws:** (any version)
* **random:** (any version)

## Input Variables
* `allowed_subnets` (default `{"ipv4":["0.0.0.0/0"],"ipv6":["::/0"]}`): Subnets allowed to access the services and load balancer
* `certificate_arn` (required): ARN for certificate at ACM required for HTTPS listener
* `containers_definitions` (required): Container setting which is than passed to fargate ecs service
* `internal_elb` (default `true`): If used, load balancer will be only for internal use
* `name_prefix` (required): Name prefix for fargate cluster
* `subnet_ids` (required): Subnet IDs used for load balancer
* `tags` (required): A map of tags (key-value pairs) passed to resources
* `vpc_id` (required): VPC ID

## Output Values
* `cluster_id`: Id of ECS cluster
* `load_balancer_arn`: Get ARN of load balancer
* `load_balancer_domain`: Get DNS record of load balancer
* `log_group_name`: The name of the Cloudwatch log group for the task.
* `service_arn`: The Amazon Resource Name (ARN) that identifies the service.
* `service_name`: The name of the service.
* `service_sg_id`: The Amazon Resource Name (ARN) that identifies the service security group.
* `sns_topic_arn`: SNS topic to subscribe for alerts
* `target_group_arn`: The ARN of the Target Group.
* `target_group_name`: The Name of the Target Groups.
* `task_role_arn`: The Amazon Resource Name (ARN) specifying the service role.
* `task_role_name`: The name of the service role.

## Managed Resources
* `aws_ecs_cluster.cluster` from `aws`
* `aws_security_group_rule.ingress_http` from `aws`
* `aws_security_group_rule.ingress_https` from `aws`
* `random_string.random` from `random`

## Data Resources
* `data.aws_region.current` from `aws`

## Child Modules
* `ecs-fargate` from `./fargate/`
* `fargate_alb` from `telia-oss/loadbalancer/aws` (`3.0.0`)
* `monitoring` from `./monitoring`
* `monitoring_sns_topic` from `./sns`


# Module `fargate`

Provider Requirements:
* **aws:** (any version)
* **null:** (any version)

## Input Variables
* `alb_arn` (required): ALB ARN
* `allowed_sg` (required): Allowed SG to ECS services, probably useful only for Load Balancer
* `allowed_subnets` (default `["0.0.0.0/0"]`): Subnets allowed to access the services and load balancer
* `certificate_arn` (required): ARN for certificate at ACM
* `cluster_id` (required): The Amazon Resource Name (ARN) that identifies the cluster.
* `cluster_name` (required): Name that identifies the cluster.
* `containers_definitions` (required): Container setting which is than passed to fargate ecs service
* `private_subnet_ids` (required): A list of private subnets inside the VPC
* `tags` (required): A map of tags (key-value pairs) passed to resources.
* `vpc_id` (required): The VPC ID.

## Output Values
* `log_group_name`: The name of the Cloudwatch log group for the task.
* `service_arn`: The Amazon Resource Name (ARN) that identifies the service.
* `service_name`: The name of the service.
* `service_sg_id`: The Amazon Resource Name (ARN) that identifies the service security group.
* `target_group_arn`: The ARN of the Target Group.
* `target_group_name`: The Name of the Target Groups.
* `task_role_arn`: The Amazon Resource Name (ARN) specifying the service role.
* `task_role_name`: The name of the service role.

## Managed Resources
* `aws_appautoscaling_policy.ecs_scaling_policy` from `aws`
* `aws_appautoscaling_target.ecs_target` from `aws`
* `aws_cloudwatch_log_group.main` from `aws`
* `aws_ecs_service.service` from `aws`
* `aws_ecs_service.service_with_no_service_registries` from `aws`
* `aws_ecs_task_definition.task` from `aws`
* `aws_iam_role.execution` from `aws`
* `aws_iam_role.task` from `aws`
* `aws_iam_role_policy.log_agent` from `aws`
* `aws_iam_role_policy.read_repository_credentials` from `aws`
* `aws_iam_role_policy.task_execution` from `aws`
* `aws_lb_listener.http` from `aws`
* `aws_lb_listener.https` from `aws`
* `aws_lb_listener_rule.routing_http` from `aws`
* `aws_lb_listener_rule.routing_https` from `aws`
* `aws_lb_target_group.task` from `aws`
* `aws_security_group.ecs_service` from `aws`
* `aws_security_group_rule.egress_service` from `aws`
* `aws_security_group_rule.egress_service_sg` from `aws`
* `aws_security_group_rule.ingress_service` from `aws`
* `aws_security_group_rule.ingress_service_sg` from `aws`
* `null_resource.lb_exists` from `null`

## Data Resources
* `data.aws_iam_policy_document.read_repository_credentials` from `aws`
* `data.aws_iam_policy_document.task_assume` from `aws`
* `data.aws_iam_policy_document.task_execution_permissions` from `aws`
* `data.aws_iam_policy_document.task_permissions` from `aws`
* `data.aws_kms_key.secretsmanager_key` from `aws`
* `data.aws_region.current` from `aws`


# Module `fargate-service`

Provider Requirements:
* **aws:** (any version)
* **null:** (any version)

## Input Variables
* `allowed_subnets` (default `["0.0.0.0/0"]`): Subnets allowed to access the services and load balancer
* `certificate_arn` (required): ARN for certificate at ACM
* `cluster_id` (required): The Amazon Resource Name (ARN) that identifies the cluster.
* `container_name` (required): Optional name for the container to be used instead of name_prefix. Useful when when constructing an imagedefinitons.json file for continuous deployment using Codepipeline.
* `deployment_controller_type` (default `"ECS"`): Type of deployment controller. Valid values: CODE_DEPLOY, ECS.
* `deployment_maximum_percent` (default `200`): The upper limit of the number of running tasks that can be running in a service during a deployment
* `deployment_minimum_healthy_percent` (default `50`): The lower limit of the number of running tasks that must remain running and healthy in a service during a deployment
* `desired_count` (default `1`): The number of instances of the task definitions to place and keep running.
* `health_check` (required): A health block containing health check settings for the target group. Overrides the defaults.
* `health_check_grace_period_seconds` (default `300`): Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers.
* `lb_arn` (required): Arn for the LB for which the service should be attach to.
* `log_retention_in_days` (default `30`): Number of days the logs will be retained in CloudWatch.
* `name_prefix` (required): A prefix used for naming resources.
* `private_subnet_ids` (required): A list of private subnets inside the VPC
* `repository_credentials` (required): name or ARN of a secrets manager secret (arn:aws:secretsmanager:region:aws_account_id:secret:secret_name)
* `repository_credentials_kms_key` (default `"alias/aws/secretsmanager"`): key id, key ARN, alias name or alias ARN of the key that encrypted the repository credentials
* `service_listner_rules` (required): Rules to be bind to listener
* `service_registry_arn` (required): ARN of aws_service_discovery_service resource
* `tags` (required): A map of tags (key-value pairs) passed to resources.
* `task_container_assign_public_ip` (required): Assigned public IP to the container.
* `task_container_command` (required): The command that is passed to the container.
* `task_container_environment` (required): The environment variables to pass to a container.
* `task_container_image` (required): The image used to start a container.
* `task_container_port` (required): Port that the container exposes.
* `task_container_protocol` (default `"HTTP"`): Protocol that the container exposes.
* `task_definition_cpu` (default `256`): Amount of CPU to reserve for the task.
* `task_definition_memory` (default `512`): The soft limit (in MiB) of memory to reserve for the container.
* `vpc_id` (required): The VPC ID.

## Output Values
* `log_group_name`: The name of the Cloudwatch log group for the task.
* `service_arn`: The Amazon Resource Name (ARN) that identifies the service.
* `service_name`: The name of the service.
* `service_sg_id`: The Amazon Resource Name (ARN) that identifies the service security group.
* `target_group_arn`: The ARN of the Target Group.
* `target_group_name`: The Name of the Target Group.
* `task_role_arn`: The Amazon Resource Name (ARN) specifying the service role.
* `task_role_name`: The name of the service role.

## Managed Resources
* `aws_cloudwatch_log_group.main` from `aws`
* `aws_ecs_service.service` from `aws`
* `aws_ecs_task_definition.task` from `aws`
* `aws_iam_role.execution` from `aws`
* `aws_iam_role.task` from `aws`
* `aws_iam_role_policy.log_agent` from `aws`
* `aws_iam_role_policy.read_repository_credentials` from `aws`
* `aws_iam_role_policy.task_execution` from `aws`
* `aws_lb_listener.http` from `aws`
* `aws_lb_listener.https` from `aws`
* `aws_lb_listener_rule.routing_http` from `aws`
* `aws_lb_listener_rule.routing_https` from `aws`
* `aws_lb_target_group.task` from `aws`
* `aws_security_group.ecs_service` from `aws`
* `aws_security_group_rule.egress_service` from `aws`
* `aws_security_group_rule.ingress_service` from `aws`
* `null_resource.lb_exists` from `null`

## Data Resources
* `data.aws_iam_policy_document.read_repository_credentials` from `aws`
* `data.aws_iam_policy_document.task_assume` from `aws`
* `data.aws_iam_policy_document.task_execution_permissions` from `aws`
* `data.aws_iam_policy_document.task_permissions` from `aws`
* `data.aws_kms_key.secretsmanager_key` from `aws`
* `data.aws_region.current` from `aws`


# Module `lambda`

Provider Requirements:
* **aws:** (any version)
* **random:** (any version)

## Input Variables
* `environment` (default `{"NA":"NA"}`): A map that defines environment variables for the Lambda function.
* `filename` (required): The path to the function's deployment package within the local filesystem.
* `handler` (default `"main"`): The function entrypoint in your code.
* `log_retention_in_days` (default `60`): Log retention of the lambda function
* `name_prefix` (required): Name prefix of lambda function
* `policy` (required): A policy document for the lambda execution role.
* `runtime` (default `"go1.x"`): Lambda runtime. Defaults to Go 1.x.
* `security_group_ids` (required): SG IDs for Lambda, should at least allow all outbound
* `subnet_ids` (required): VPC subnets for Lambda
* `tags` (required): Map of tags to assign to lambda function
* `timeout` (default `30`): Execution timeout.

## Output Values
* `arn`
* `name`

## Managed Resources
* `aws_cloudwatch_log_group.lambda_log_group` from `aws`
* `aws_iam_role.lambda_main` from `aws`
* `aws_iam_role_policy.lambda_main` from `aws`
* `aws_lambda_function.lambda` from `aws`
* `random_string.lambda_postfix_generator` from `random`

## Data Resources
* `data.aws_iam_policy_document.lambda_assume` from `aws`


# Module `monitoring`

Provider Requirements:
* **archive:** (any version)
* **aws:** (any version)

## Input Variables
* `default_region` (default `"eu-west-1"`): Default region to be used in Lambda functions
* `ecs_service_alerts_evaluation_periods` (default `5`): How many periods should alerts at ECS service cross the threshold to be triggered
* `name_prefix` (required): Name prefix for lambda monitorings
* `sns_notification_topic` (required): SNS notification topic for alerting messages from user_data scripts
* `tags` (required): A map of tags (key-value pairs) passed to resources

## Managed Resources
* `aws_cloudwatch_event_rule.lambda_services_alarm` from `aws`
* `aws_cloudwatch_event_rule.lambda_services_dashboard` from `aws`
* `aws_cloudwatch_event_target.lambda_services_alarm` from `aws`
* `aws_cloudwatch_event_target.lambda_services_dashboard` from `aws`
* `aws_lambda_permission.cloudwatch_services_alarm` from `aws`
* `aws_lambda_permission.cloudwatch_services_dashboard` from `aws`

## Data Resources
* `data.archive_file.lambda_service_utilization_monitoring-dotfiles` from `archive`
* `data.aws_iam_policy_document.lambda_service_utilization_monitoring` from `aws`
* `data.aws_iam_policy_document.lambda_services_dashboard` from `aws`

## Child Modules
* `alarm-lambda` from `../lambda`
* `dashboard-lambda` from `../lambda`


# Module `sns`

## Input Variables
* `sns_topic_name` (required): SNS topic name to which SQS queue should subscribe

## Output Values
* `this_sns_topic_arn`: SNS topic ARN for potential subscriptions
* `this_sns_topic_name`: SNS topic name

## Child Modules
* `sns_topic` from `terraform-aws-modules/sns/aws` (`~> 2.0`)


# Certificate handling

This module so far does not handle certificate management. You can add `certificate_arn` to add TLS to AWS Load Balancer but creation of the certificate is up to you.

To handle certificate, their creation and usage, see https://www.terraform.io/docs/providers/aws/r/acm_certificate_validation.html 


