#!/bin/bash
default_ns=default
namespace=${1:-$default_ns}
sp_name=sp_$(date +"%Y-%m-%d_%H-%M-%S")
mkdir $sp_name

# Get the logs from all the pods in the namespace
mkdir $sp_name/logs
kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $namespace | xargs -L 1 -I {} bash -c "kubectl logs -n $namespace --all-containers --ignore-errors {} > $sp_name/logs/{}.log"

# Get pod details from all pods in the namespace
mkdir $sp_name/pods
kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $namespace | xargs -L 1 -I {} bash -c "kubectl describe pod -n $namespace {} > $sp_name/pods/{}.txt"

# List all resources
kubectl get all -n $namespace > $sp_name/kubectl_all.txt

# Get the enviroment variables applied on mdss and mdcore
kubectl get configmap mdcore-env mdss-env -o yaml -n $namespace 2&>1 > $sp_name/configmaps.yaml

# Get the ingress rules from the namespace
kubectl get ingress -o yaml -n $namespace 2&>1 > $sp_name/ingress.yaml

# Get events on the cluster
kubectl get events -o yaml --all-namespaces 2&>1 > $sp_name/events.yaml

zip -r $sp_name.zip $sp_name
