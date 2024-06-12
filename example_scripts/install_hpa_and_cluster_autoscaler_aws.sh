#!/bin/bash

# Strings to replace with specific values for deployment:
# <MIN_NODES>
# <MAX_NODES>
# <ASG_REGION>
# <K8S_ASG_NAME>
# <AWS_ACCOUNT_ID>

SCRIPT_PATH=$(pwd)
min=1
max=3
region="us-west-1"
asg_name=""
account_id=""
cluster_name="md-k8s"
custom_hpa="false"
delete="false"

function printHelp () {
  echo "Usage: "
  echo "  install_hpa_and_cluster_autoscaler_aws.sh --min <min_nodes> --max <max_nodes> --region <asg_region> --cluster_name <cluster_name> --asg_name <k8s_asg_name> --account_id <aws_account_id>"
  echo
  echo "    --min <min> - Min is the minimum number of nodes in the ASG (default: \"$min\")"
  echo "    --max <max> - Max is the minimum number of nodes in the ASG (default: \"$max\")"
  echo "    --region <asg_region> - Region where the ASG of the K8S Cluster is created (default: \"$region\")"
  echo "    --cluster_name <cluster_name> - Region where the ASG of the K8S Cluster is created (default: \"$region\")"
  echo "    --asg_name <k8s_asg_name> - Name of the ASG of the K8S Cluster that is created (default: \"$asg_name\")"
  echo "    --account_id <aws_account_id> - ID of the AWS Account where the K8S Cluster is running (default: \"$account_id\")"
  echo "    --custom_hpa - Flag to indicate to use the file custom_hpa.yml configuration file "
  echo
  echo "	install_hpa_and_cluster_autoscaler_aws.sh --min 1 --max 8 --region 'us-west-1' --asg_name 'example-asg' --acount_id 123456789 "
  echo
  echo "    install_hpa_and_cluster_autoscaler_aws.sh --delete"
}

while [[ $# -gt 0 ]]; do
      opt="$1";
      shift;
      current_arg="$1"
      if [[ "$current_arg" =~ ^-{1,2}.* ]] || [ "$current_arg" == "" ]; then
        echo "ERROR: You may have left an argument blank. Double check your command." 
        exit 1;
      fi
      case "$opt" in
        "--min") 
            min="$1"; 
            shift;;
        "--max") 
            max="$1"; 
            shift;;
        "--region") 
            region="$1"; 
            shift;;
        "--cluster_name") 
            cluster_name="$1"; 
            shift;;
        "--asg_name") 
            asg_name="$1"; 
            shift;;
        "--account_id") 
            account_id="$1"; 
            shift;;
        "--custom_hpa") 
            custom_hpa="true";;
        "--delete") 
            delete="true";;
        *) 
        echo "ERROR: Invalid option: \""$opt"\"" >&2
        exit 1;;
      esac
done

if [ "${delete}" == "true" ];then
    echo "Deleting all resources created in K8S by this script, AWS resources need to be manually deleted (IAM Policy and Role cluster-autoscaler)"

    kubectl delete hpa md-core
    kubectl delete -f cluster-autoscaler-one-asg-aws.yaml
    kubectl delete serviceaccount cluster-autoscaler -n kube-system

    exit 1
else

    if [ -z "$min" ] && [ -z "$max" ] && [ -z "$region" ] && [ -z "$asg_name" ] && [ -z "$account_id" ];then
          echo "All parameters are required"
          printHelp
          exit 0
    fi
fi

# Create an IAM OIDC provider for your cluster
oidc_id=$(aws eks describe-cluster --name $cluster_name --region $region --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $oidc_id
is_activated=$(aws iam list-open-id-connect-providers --region $region | grep $oidc_id | cut -d "/" -f4)
if [ -z "$is_activated" ];then
    echo "OIDC Provider is already activated"
else
    eksctl utils associate-iam-oidc-provider --cluster $cluster_name --region $region --approve
fi

## Configure a Kubernetes service account to assume an IAM role

# Create IAM Policy
policy_arn=$(aws iam create-policy --policy-name cluster-autoscaler-policy --policy-document file://iam_policy_cluster_autoscaler.json | jq '.Policy.Arn')

if [ -z $policy_arn ];then 
    echo "Policy already created"
    policy_arn="arn:aws:iam::"$ACCOUNT_ID":policy/cluster-autoscaler-policy"
    echo "Using policy: "$policy_arn
else 
    echo "Policy newly created: "$policy_arn
fi

# Create an IAM role and associate it with a Kubernetes service account. You can use either eksctl or the AWS CLI. 

eksctl create iamserviceaccount --name cluster-autoscaler --region $region --namespace kube-system --cluster $cluster_name --role-name metadefender-cluster-autoscaler-role \
    --attach-policy-arn $policy_arn --approve --override-existing-serviceaccounts

# Check svc account is properly attached
kubectl describe serviceaccount cluster-autoscaler -n kube-system


# EDIT CONFIGURATION OF CLUSTER AUTOSCALER YAML FILE 
sed -i "s/<MIN_NODES>/$min/g" cluster-autoscaler-one-asg-aws.yaml
sed -i "s/<MAX_NODES>/$max/g" cluster-autoscaler-one-asg-aws.yaml
sed -i "s/<K8S_ASG_NAME>/$asg_name/g" cluster-autoscaler-one-asg-aws.yaml

kubectl apply -f cluster-autoscaler-one-asg-aws.yaml

#### INSTAL BASIC HPA ### 

if [ "${custom_hpa}" == "true" ];then
    kubectl apply -f custom_hpa.yaml
else
    kubectl autoscale deployment md-core --cpu-percent=80 --min=$min --max=$max
fi



### Delete commands 

# aws iam delete-policy --policy-arn arn:aws:iam::1111122222333:policy/cluster-autoscaler-policy
# kubectl delete hpa md-core
# kubectl delete -f cluster-autoscaler-one-asg-aws.yaml
# kubectl delete serviceaccount cluster-autoscaler -n kube-system

# eksctl create iamserviceaccount --name cluster-autoscaler --region <region> --namespace kube-system --cluster <cluster_name> --role-name metadefender-cluster-autoscaler-role \
#     --attach-policy-arn arn:aws:iam::111112222333:policy/cluster-autoscaler-policy --override-existing-serviceaccounts

#aws iam put-role-policy \
#    --role-name metadefender-cluster-autoscaler-role \
#    --policy-name cluster-autoscaler-policy \
#    --policy-document file://iam_policy_cluster_autoscaler.json