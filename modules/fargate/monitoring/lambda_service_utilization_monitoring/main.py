import boto3
import logging
import os
import re
import json

session = boto3.session.Session()
logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    cluster_name = os.environ.get('ECS_CLUSTER')
    ecs_region_name = os.environ.get('ECS_REGION_NAME') if \
        os.environ.get('ECS_REGION_NAME') else 'eu-west-1'

    ecs_memory_threshold = os.environ.get('ECS_MEMORY_THRESHOLD') if \
        os.environ.get('ECS_MEMORY_THRESHOLD') else 95
    ecs_memory_threshold = int(ecs_memory_threshold)

    ecs_cpu_threshold = os.environ.get('ECS_CPU_THRESHOLD') if \
        os.environ.get('ECS_CPU_THRESHOLD') else 90
    ecs_cpu_threshold = int(ecs_cpu_threshold)

    sns_alert_topic = os.environ.get('SNS_ALERT_TOPIC') if \
        os.environ.get('SNS_ALERT_TOPIC') else ""

    evaluation_periods = os.environ.get('EVALUATION_PERIODS') if \
        os.environ.get('EVALUATION_PERIODS') else 5
    evaluation_periods = int(evaluation_periods)

    period = os.environ.get('PERIOD') if \
        os.environ.get('PERIOD') else 60
    period = int(period)

    ecs = session.client(
        service_name='ecs',
        region_name=ecs_region_name
    )
    clw_client = session.client(
        service_name='cloudwatch',
        region_name=ecs_region_name
    )
    elb = boto3.client(
        service_name='elbv2',
        region_name=ecs_region_name
    )

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

    services_names = [
        service.split("/")[1][0:32] for service in services_list if re.fullmatch(
            r"[0-9a-zA-Z\-]+", service.split("/")[1][0:32]
        )
    ]

    alert_list_response = clw_client.describe_alarms(
        AlarmNamePrefix='NEO/ECS Service ',
    )
    alert_list_response = alert_list_response['MetricAlarms']

    to_delete_alarms = []
    for alert in alert_list_response:
        logging.info("Removing " + alert['AlarmName'] + " INSUFFICIENT_DATA")
        if alert['StateValue'] == 'INSUFFICIENT_DATA':
            to_delete_alarms.append(alert['AlarmName'])

    clw_client.delete_alarms(
        AlarmNames=to_delete_alarms,
    )

    for service in services_names:
        alarm_name = 'NEO/ECS Service ' + service + ' MEM utilization'
        logging.info("Adding \"" + alarm_name + "\" not present")
        if alarm_name not in [alert['AlarmName'] for alert in alert_list_response]:
            clw_client.put_metric_alarm(
                AlarmName=alarm_name,
                ComparisonOperator='GreaterThanThreshold',
                EvaluationPeriods=evaluation_periods,
                MetricName='MemoryUtilization',
                Namespace='AWS/ECS',
                Period=period,
                TreatMissingData='ignore',
                Statistic='Average',
                Threshold=ecs_memory_threshold,
                ActionsEnabled=True,
                AlarmDescription='Alarm when service MEM exceeds  ' + str(ecs_memory_threshold) + '%',
                Dimensions=[
                    {
                      'Name': 'ClusterName',
                      'Value': cluster_name
                    },
                    {
                      'Name': 'ServiceName',
                      'Value': service
                    },
                ],
                Unit='Percent',
                AlarmActions=[
                    sns_alert_topic,
                ] if sns_alert_topic != "" else [],
                OKActions=[
                    sns_alert_topic,
                ] if sns_alert_topic != "" else []
            )
        alarm_name = 'NEO/ECS Service ' + service + ' CPU utilization'
        logging.info("Adding \"" + alarm_name + "\" not present")
        if alarm_name not in [alert['AlarmName'] for alert in alert_list_response]:
            clw_client.put_metric_alarm(
                AlarmName=alarm_name,
                ComparisonOperator='GreaterThanThreshold',
                EvaluationPeriods=evaluation_periods,
                MetricName='CPUUtilization',
                Namespace='AWS/ECS',
                Period=period,
                TreatMissingData='ignore',
                Statistic='Average',
                Threshold=ecs_cpu_threshold,
                ActionsEnabled=True,
                AlarmDescription='Alarm when service CPU exceeds  ' + str(ecs_cpu_threshold) + '%',
                Dimensions=[
                    {
                      'Name': 'ClusterName',
                      'Value': cluster_name
                    },
                    {
                      'Name': 'ServiceName',
                      'Value': service
                    },
                ],
                Unit='Percent',
                AlarmActions=[
                    sns_alert_topic,
                ] if sns_alert_topic != "" else [],
                OKActions=[
                    sns_alert_topic,
                ] if sns_alert_topic != "" else []
            )

    return {
        "statusCode": 200,
        "body": json.dumps('Ended correctly')
    }


if __name__ == "__main__":
    lambda_handler("", "")

    
