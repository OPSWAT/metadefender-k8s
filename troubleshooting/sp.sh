#!/bin/bash
default_ns=default
namespace=${1:-$default_ns}
sp_name=sp_$(date +"%Y-%m-%d_%H-%M-%S")
mkdir $sp_name
mkdir $sp_name/logs
kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $namespace | xargs -L 1 -I {} bash -c "kubectl logs -n $namespace --all-containers --ignore-errors {} > $sp_name/logs/{}.log"
mkdir $sp_name/pods
kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $namespace | xargs -L 1 -I {} bash -c "kubectl describe pod -n $namespace {} > $sp_name/pods/{}.txt"
kubectl get all > $sp_name/kubectl_all.txt
kubectl get configmap mdcore-env mdss-env -o yaml 2&>1 > $sp_name/configmaps.yaml

zip -r $sp_name.zip $sp_name