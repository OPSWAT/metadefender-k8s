#!/bin/bash

AKS_RESOURCE_GROUP=Europe
AKS_CLUSTER_NAME=MDK8S
REGION=northeurope

az aks create \
--resource-group $AKS_RESOURCE_GROUP \
--name $AKS_CLUSTER_NAME \
--enable-cluster-autoscaler \
--node-count 1 \
--min-count 1 \
--max-count 2 \
--location $REGION \
--node-vm-size Standard_DS2_v2 \
--enable-addons monitoring,http_application_routing \
--generate-ssh-keys

# az aks enable-addons --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --addons http_application_routing
# az aks install-cli

az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME