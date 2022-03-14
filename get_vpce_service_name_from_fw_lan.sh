#!/bin/bash
lan_interface=$1
region=$2

lan_subnet_id=$(aws ec2 describe-network-interfaces --region $region --network-interface-id $lan_interface --query 'NetworkInterfaces[0].SubnetId')
# Remove suffix double quote
lan_subnet_id="${lan_subnet_id%\"}"
# Remove prefix double quote
lan_subnet_id="${lan_subnet_id#\"}"

# aws elbv2 describe-load-balancers --region $region --query 'LoadBalancers[].AvailabilityZones[?SubnetId==`$lan_subnet_id`] && LoadBalancers[?Type==`gateway`].LoadBalancerArn | [0]'
load_balancer_arn=$(aws elbv2 describe-load-balancers --region $region --query "LoadBalancers[*].{LoadBalancerArn:LoadBalancerArn,Type:Type,SubnetId:AvailabilityZones[?SubnetId=='$lan_subnet_id'].SubnetId|[0]} |[?Type=='gateway'] | [?SubnetId=='$lan_subnet_id'] | [0].LoadBalancerArn")
# Remove suffix double quote
load_balancer_arn="${load_balancer_arn%\"}"
# Remove prefix double quote
load_balancer_arn="${load_balancer_arn#\"}"


service_name=$(aws ec2 describe-vpc-endpoint-service-configurations --region $region --query "ServiceConfigurations[].{ServiceName:ServiceName,GatewayLoadBalancerArn:GatewayLoadBalancerArns[0]} | [?GatewayLoadBalancerArn=='$load_balancer_arn']|[0].ServiceName")
# Remove suffix double quote
service_name="${service_name%\"}"
# Remove prefix double quote
service_name="${service_name#\"}"

echo $service_name