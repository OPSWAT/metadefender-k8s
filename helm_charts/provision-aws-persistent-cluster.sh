#!/bin/bash

# Required configuration variables
MDSS_CLUSTER_NAME=mdss-k8s-aws
MDSS_CLUSTER_REGION=eu-central-1

# Create a key pair required for the EKS cluster
aws ec2 create-key-pair --region $MDSS_CLUSTER_REGION --key-name $MDSS_CLUSTER_NAME

# Create an EKS cluster, the number of nodes and node type can be changed according performance requirements
# The nodes are only used for the MDSS services that are not stateless (i.e. database services)
eksctl create cluster \
--name $MDSS_CLUSTER_NAME \
--region $MDSS_CLUSTER_REGION \
--alb-ingress-access \
--with-oidc \
--ssh-access \
--ssh-public-key $MDSS_CLUSTER_NAME \
--managed \
--node-type t3.medium \
--nodes 1 \
--nodes-min 1 \
--nodes-max 1 \
--max-pods-per-node 50 \
--node-labels type=ec2-db-node

# Create an AWS Fargate profile used for stateless services
eksctl create fargateprofile --namespace default --cluster $MDSS_CLUSTER_NAME --labels aws-type=fargate

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