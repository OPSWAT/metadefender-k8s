#!/bin/bash
default_ns=default
namespace=${1:-$default_ns}
sp_name=sp_$(date +"%Y-%m-%d_%H-%M-%S")
mkdir $sp_name

# Get the logs from all the pods in the namespace
mkdir $sp_name/logs
kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $namespace | xargs -L 1 -I {} bash -c "kubectl logs -n $namespace --all-containers --ignore-errors {} > $sp_name/logs/{}.log"

# Get the previous logs from all the pods in the namespace (for restarted containers)
mkdir $sp_name/logs-previous
kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $namespace | xargs -L 1 -I {} bash -c "kubectl logs -n $namespace --all-containers --ignore-errors --previous {} > $sp_name/logs-previous/{}.log 2>/dev/null || true"

# Get the serilog output files from all the pods in the namespace
mkdir $sp_name/serilog
kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $namespace | xargs -L 1 -I {} bash -c "kubectl exec {} -n $namespace -- bash -c \"cat /app/logs/*\" > $sp_name/serilog/{}.log"

# Get the MDSS integration service logs (4.4.0+ MTS layout)
# The merged integration containers run discovery/remediation/storage side by side,
# each writing its Serilog output to /app/<service>/logs/. The singular protocol
# pods (smbservice/sftpservice/nfsservice) use /app/logs/ instead. Only target pods
mkdir $sp_name/integration-logs
integration_pods=$(kubectl get pods -n $namespace -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{range .spec.containers[*]}{.image}{","}{end}{"\n"}{end}' | grep mdintegrations_ | cut -d'|' -f1)
for pod in $integration_pods; do
  mkdir -p "$sp_name/integration-logs/$pod"
  case "$pod" in
    smbservice-*|sftpservice-*|nfsservice-*)
      # singular protocol pods write to /app/logs
      kubectl cp -n $namespace "$pod:/app/logs" "$sp_name/integration-logs/$pod/service" >/dev/null 2>&1 || true
      ;;
    *)
      # containers that write to /app/<discovery|remediation|storage>/logs
      for service in discovery remediation storage; do
        kubectl cp -n $namespace "$pod:/app/$service/logs" "$sp_name/integration-logs/$pod/$service" >/dev/null 2>&1 || true
      done
      ;;
  esac
done
find $sp_name/integration-logs -mindepth 1 -type d -empty -delete 2>/dev/null || true
rmdir $sp_name/integration-logs 2>/dev/null || true

# Get pod details from all pods in the namespace
mkdir $sp_name/pods
kubectl get pods --no-headers -o custom-columns=":metadata.name" -n $namespace | xargs -L 1 -I {} bash -c "kubectl describe pod -n $namespace {} > $sp_name/pods/{}.txt"

# List all resources
kubectl get all -n $namespace > $sp_name/kubectl_all.txt

# Get the enviroment variables applied on mdss and mdcore
kubectl get configmaps -n $namespace -o yaml > $sp_name/configmaps.yaml

# Get the ingress rules from the namespace
kubectl get ingress -o yaml -n $namespace 2&>1 > $sp_name/ingress.yaml

# Get events on the cluster
kubectl get events -o yaml --all-namespaces 2&>1 > $sp_name/events.yaml

zip -r $sp_name.zip $sp_name
