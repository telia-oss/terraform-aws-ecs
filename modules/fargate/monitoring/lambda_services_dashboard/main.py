import json
import boto3
import logging
import os
from jinja2 import Environment, FileSystemLoader

session = boto3.session.Session()
logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    cluster_name = os.environ.get('ECS_CLUSTER')
    ecs_region_name = os.environ.get('ECS_REGION_NAME') if \
        os.environ.get('ECS_REGION_NAME') else 'eu-west-1'

    ecs = session.client(
        service_name='ecs',
        region_name=ecs_region_name
    )
    clw = session.client(
        service_name='cloudwatch',
        region_name=ecs_region_name
    )
    elb = boto3.client(
        service_name='elbv2',
        region_name=ecs_region_name
    )

    templates_dir = './templates'
    env = Environment(loader=FileSystemLoader(templates_dir))
    template = env.get_template('dashboard.json.j2')

    dashboard_data = {}

    # basic listing, list services returns only 10 records at once
    services = ecs.list_services(
        cluster=cluster_name
    )
    services_list = services['serviceArns']
    while len(services['serviceArns']) and 'nextToken' in services:
        services = ecs.list_services(
            cluster=cluster_name,
            nextToken=services['nextToken']
        )
        services_list += services['serviceArns']

    services = []
    for i in range(0, len(services_list), 10):
        services += ecs.describe_services(
            cluster=cluster_name,
            services=services_list[i:i+10]
        )['services']

    for s in services:
        tmp = {}
        if len(s['loadBalancers']) == 0:
            continue
        target_groups = elb.describe_target_groups(
            TargetGroupArns=[s['loadBalancers'][0]['targetGroupArn']]
        )['TargetGroups']
        if len(target_groups) == 0:
            continue
        tmp['target_group'] = target_groups[0]['TargetGroupName']
        tmp['target_group_id'] = s['loadBalancers'][0]['targetGroupArn'].split('/')[-1]
        load_balancers = elb.describe_load_balancers(LoadBalancerArns=[target_groups[0]['LoadBalancerArns'][0]])
        if len(load_balancers['LoadBalancers']) == 0:
            continue
        tmp['load_balancer'] = load_balancers['LoadBalancers'][0]['LoadBalancerName']
        tmp['load_balancer_id'] = load_balancers['LoadBalancers'][0]['LoadBalancerArn'].split('/')[-1]
        dashboard_data[s['serviceName']] = tmp

    template_data_list = []
    y_counter = 0

    for service in dashboard_data:
        template_data_list += [
            {
                "target_group_id": dashboard_data[service]['target_group_id'],
                "target_group_name": dashboard_data[service]['target_group'],
                "ecs_service": service,
                "load_balancer_name": dashboard_data[service]['load_balancer'],
                "load_balancer_id": dashboard_data[service]['load_balancer_id'],
                "ecs_cluster_name": cluster_name,
                "region": ecs_region_name,
                "y": y_counter,
            }
        ]
        y_counter += 1

    dashboard_body = template.render(
        template_data_list=template_data_list
    )
    clw.put_dashboard(
        DashboardName=cluster_name + "-ecs-services-list-dashboard",
        DashboardBody=dashboard_body
    )

    return {
        "statusCode": 200,
        "body": json.dumps('Ended correctly')
    }


if __name__ == "__main__":
    lambda_handler("", "")
