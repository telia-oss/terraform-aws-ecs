import json
import boto3
import logging
import os
import json

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

    dashboard_data = {}
    services_dict = {"widgets": []}

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
        # blok pro services_dict
        services_dict['widgets'].append({
            "type": "metric",
            "x": 0,
            "y": y_counter * 5,
            "width": 5,
            "height": 5,
            "properties": {
                "view": "timeSeries",
                "stacked": False,
                "metrics": [
                    ["AWS/ECS", "MemoryUtilization", "ServiceName", service, "ClusterName",
                     cluster_name]
                ],
                "region": ecs_region_name,
                "title": service+" - memory usage",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            }
        })
        services_dict['widgets'].append({
            "type": "metric",
            "x": 5,
            "y": y_counter * 5,
            "width": 5,
            "height": 5,
            "properties": {
                "metrics": [
                    [ "AWS/ECS", "CPUUtilization", "ServiceName", service, "ClusterName", cluster_name]
                ],
                "view": "timeSeries",
                "stacked": False,
                "region": ecs_region_name,
                "title": service+" - cpu usage",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            }
        })
        services_dict['widgets'].append({
            "type": "metric",
            "x": 10,
            "y": y_counter * 5,
            "width": 5,
            "height": 5,
            "properties": {
                "metrics": [
                    ["AWS/ApplicationELB", "RequestCountPerTarget", "TargetGroup",
                     "targetgroup/"+dashboard_data[service]['target_group']+"/"+dashboard_data[service]['target_group_id'],
                     {"stat": "Sum", "period": 60}]
                ],
                "view": "timeSeries",
                "stacked": False,
                "region": ecs_region_name,
                "title": service+" - request count",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                }
            }
        })
        if dashboard_data[service]['load_balancer'] != "":
            services_dict['widgets'].append({
                "type": "metric",
                "x": 15,
                "y": y_counter * 5,
                "width": 5,
                "height": 5,
                "properties": {
                    "metrics": [
                        ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup",
                         "targetgroup/"+dashboard_data[service]['target_group']+"/"+dashboard_data[service]['target_group_id'], "LoadBalancer",
                         "app/"+dashboard_data[service]['load_balancer']+"/"+dashboard_data[service]['load_balancer_id']]
                    ],
                    "view": "timeSeries",
                    "stacked": False,
                    "region": ecs_region_name,
                    "title": service+" - tg elb response time",
                    "yAxis": {
                        "left": {
                            "min": 0
                        }
                    }
                }
            })
        else:
            services_dict['widgets'].append({
                "type": "text",
                "x": 15,
                "y": y_counter * 5,
                "width": 5,
                "height": 5,
                "properties": {
                    "markdown": "\n ELB not associated\n"
                }
            })
        if dashboard_data[service]['load_balancer'] != "":
            services_dict['widgets'].append({
                "type": "metric",
                "x": 20,
                "y": y_counter * 5,
                "width": 4,
                "height": 5,
                "properties": {
                    "view": "timeSeries",
                    "stacked": False,
                    "metrics": [
                        ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup",
                         "targetgroup/"+dashboard_data[service]['target_group']+"/"+dashboard_data[service]['target_group_id'], "LoadBalancer",
                         "app/"+dashboard_data[service]['load_balancer']+"/"+dashboard_data[service]['load_balancer_id']],
                        [".", "HealthyHostCount", ".", ".", ".", "."]
                    ],
                    "region": ecs_region_name,
                    "title": service+" - health hosts",
                    "yAxis": {
                        "left": {
                            "min": 0
                        }
                    }
                }
            })
        else:
            services_dict['widgets'].append({
                "type": "text",
                "x": 20,
                "y": y_counter * 5,
                "width": 4,
                "height": 5,
                "properties": {
                    "markdown": "\n ELB not associated\n"
                }
            })
        y_counter += 1

    dashboard_body = json.dumps(services_dict)
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

