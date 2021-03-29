## ECS Cluster

- Autoscaling group/launch configuration.
- Amazon Linux 2 ECS Optimized AMI with ECS and SSM agents running.
- A security group for the cluster (with all egress and ingress from the specified load balancers).
- CloudWatch log group for the ECS agent.
- IAM role/instance profile with appropriate privileges.
