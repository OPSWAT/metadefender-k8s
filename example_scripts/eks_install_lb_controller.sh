#!/bin/bash

# Strings to replace with specific values for deployment:
# <K8S_CLUSTER_NAME>
# <K8S_REGION>
# <K8S_VPC_ID>
# <AWS_ACCOUNT_NR>
# (optional) 602401143452.dkr.ecr.eu-central-1.amazonaws.com/amazon/aws-load-balancer-controller

curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy<K8S_CLUSTER_NAME> \
    --policy-document file://iam_policy.json

oidc_id=$(aws eks describe-cluster --name <K8S_CLUSTER_NAME> --query "cluster.identity.oidc.issuer" --region <K8S_REGION> --output text | cut -d '/' -f 5)
eksctl utils associate-iam-oidc-provider --cluster <K8S_CLUSTER_NAME> --region <K8S_REGION> --approve

eksctl create iamserviceaccount \
  --cluster=<K8S_CLUSTER_NAME> \
  --namespace=kube-system \
  --name=aws-load-balancer-controller<K8S_CLUSTER_NAME> \
  --role-name "AmazonEKSLoadBalancerControllerRole<K8S_CLUSTER_NAME>" \
  --attach-policy-arn=arn:aws:iam::<AWS_ACCOUNT_NR>:policy/AWSLoadBalancerControllerIAMPolicy<K8S_CLUSTER_NAME> \
  --region <K8S_REGION> \
  --approve

helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<K8S_CLUSTER_NAME> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller<K8S_CLUSTER_NAME> \
  --set region=<K8S_REGION> \
  --set vpcId=<K8S_VPC_ID> \
  --set image.repository=<IMAGE_LB_CONTROLLER_REGION>        # image.repository=602401143452.dkr.ecr.eu-central-1.amazonaws.com/amazon/aws-load-balancer-controller Replace the image from here acording to your region: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html