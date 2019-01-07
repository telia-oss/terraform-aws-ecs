#!/bin/sh
set -euo pipefail

# for integer comparisons: check_counts <testValue> <expectedValue> <testName>
check_counts() {
 if [ $1 -eq $2 ]
 then
   echo "√ $3"
 else
   echo "✗ $3"
   tests_failed=$((tests_failed+1))
fi
}

tests_failed=0



# Set spotfleet request target capacity to 0 and wait for instance to be terminated so that terraform destroy can complete
spotfleet_request_id=`cat terraform-out.json | jq -r '.spotfleet_request_id.value'`
instances=`aws ec2 describe-spot-fleet-instances --spot-fleet-request-id $spotfleet_request_id | jq '.ActiveInstances[].InstanceId' | jq -rs '. |join(" ")'`
aws ec2 modify-spot-fleet-request --target-capacity 0 --spot-fleet-request-id $spotfleet_request_id
aws ec2 wait instance-terminated --instance-ids $instances


#VPC_ID=`cat terraform-out/terraform-out.json | jq -r '.vpc_id.value'`
#export AWS_DEFAULT_REGION=eu-west-1

#subnet_count=`aws ec2 describe-subnets | jq --arg VPC_ID "$VPC_ID" '.Subnets[]| select (.VpcId==$VPC_ID)' | jq -s length`
#check_counts $subnet_count 3 "Expected # of Subnets"

exit $tests_failed