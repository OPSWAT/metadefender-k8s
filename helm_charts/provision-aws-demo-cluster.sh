#!/bin/bash

# Required configuration variables
MDSS_CLUSTER_NAME=mdss-k8s-aws
MDSS_CLUSTER_REGION=eu-central-1

# Create an EKS cluster, only a fargate profile is created without any persistent data
eksctl create cluster \
--name $MDSS_CLUSTER_NAME \
--region $MDSS_CLUSTER_REGION \
--fargate \
--alb-ingress-access

# Get the cluster VPC id needed to configure the subnets 
MDSS_CLUSTER_VPC=$(aws eks describe-cluster --name $MDSS_CLUSTER_NAME \
--output text --query "cluster.resourcesVpcConfig.vpcId")

# Configre the subnets in the VPC so they can be used by the AWS load balancer
for subnet in $(aws ec2 describe-subnets \
--filters "Name=vpc-id,Values=$MDSS_CLUSTER_VPC" \
--output text --query "Subnets[*].SubnetId"); \
do (aws ec2 create-tags --resources $subnet \
--tags "Key"="kubernetes.io/cluster/$MDSS_CLUSTER_NAME","Value"="shared"); done

# Output values to console
echo cluster_name: $MDSS_CLUSTER_NAME
echo vpc_id: $MDSS_CLUSTER_VPC
echo cluster_region: $MDSS_CLUSTER_REGION