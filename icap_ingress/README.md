ICAP Nginx Ingress (early access)
=====================

The following resources and instructions can be used to create and configure a K8S ingress that routes traffic through an existing ICAP instance for scanning.

## Requirements

The following requirements should be met before deploying the new ingress and controller:
- An existing K8S cluster
- An Nginx ingress controller installed in the cluster
- A working ICAP instance (either in the cluster or an external one that is accessible)

## Deployment

There are 2 ways of deploying the new ingress controller, either replace the entire controller image with the one provided that includes the new module for ICAP or add just the Nginx module to an existing nginx ingress controller.

### Using the image

To replace the ingress controller image we need to patch the existing k8s resource (deployment, DaemonSet etc.) for the existing ingress controller to include the new image. For this edit the ```ingress-controller-patch-image.yml``` file and replace the container name to match the existing contoller and run the following command (replace 'deployment' and 'ingress-nginx-controller' with your specific resource type and name for the controller):

```
kubectl patch deployment ingress-nginx-controller --patch-file ingress-controller-patch-image.yml
```

Once the new image is deployed, we can configure the controller to use ICAP and create an ingress for the target application we want to expose. For this edit the ```icap-conf.yml``` file and replace the values marked by '< ... >' according to your environment and apply it:

```
kubectl apply -f icap-conf.yml
```

### Using the custom nginx module

First we need to load the new module as a ConfigMap in the cluster. Apply the module resource using kubectl and replace the version with the one compatible with the existing controller:

```
kubectl apply nginx-icap-module-<NGINX_VERSION>.yml
```

To add the new module we need to patch the existing k8s resource (deployment, DaemonSet etc.) for the existing ingress controller to mount the module in the container. For this edit the ```ingress-controller-patch-module.yml``` file and replace the container name to match the existing contoller and run the following command (replace 'deployment' and 'ingress-nginx-controller' with your specific resource type and name for the controller):

```
kubectl patch deployment ingress-nginx-controller --patch-file ingress-controller-patch-module.yml
```

Once the new module is deployed, we can configure the controller to use ICAP and create an ingress for the target application we want to expose. For this edit the ```icap-conf.yml``` file and replace the values marked by '< ... >' according to your environment and apply it:

```
kubectl apply -f icap-conf.yml
```
