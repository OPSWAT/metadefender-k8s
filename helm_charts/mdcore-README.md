
Metadefender core
===========

This is a Helm chart for deploying MetaDefender Core (https://www.opswat.com/products/metadefender/core) in a Kubernetes cluster

This chart can deploy the following depending on the provided values:
- One or more MD Core instances 
- A PostgreSQL database instance pre-configured to be used by MD Core

In addition to the chart, we also provide a number of values files for specific scenarios:
- `mdcore-aws-eks-values.yml` - for deploying in an AWS environment using Amazon EKS
- `mdcore-azure-aks-values.yml` - for deploying in an Azure environment using AKS
- `mdcore-azure-gcloud-*.yml` - for deploying in an GCP environment using GKE
- `mdcore-openshift.yml` - for deploying in an OpenShift environment
- `mdcore-mdhub-module.yml` - values for deploying the MD Hub stack

## Installation

### From source
MD Core can be installed directly from the source code, here's an example using the generic values:
```console
git clone https://github.com/OPSWAT/metadefender-k8s.git metadefender
cd metadefender/helm_carts
helm install my_mdcore ./mdcore
```

### From the GitHub helm repo
The installation can also be done using the helm repo which is updated on each release:
 ```console
helm repo add mdk8s https://opswat.github.io/metadefender-k8s/
helm repo update mdk8s
helm install my_mdcore mdk8s/metadefender_core
```

### OpenShift deployment

#### **Cluster requirements**
1. A configured image pull secret for the current OpenShift user for the RedHat docker repo: `registry.redhat.io` . The helm values for OpenShift use the following image from RedHat: `registry.redhat.io/rhel8/postgresql-12` . This is only required if using the database deployment from the Helm chart, a managed external database service can be configured instead if available.
The repo credentials can be configured with the following `oc` commands:
```
oc create secret docker-registry imagepullsecret --docker-server=registry.redhat.io --docker-username=<REDHAT_USER> --docker-password=<REDHAT_PASSWORD> --docker-email=<REDHAT_EMAIL>

oc secrets link <OPENSHIFT_USER> imagepullsecret --for=pull
```
2. An existing persistent volume or storage class to be used for database persistency. The `mdcore-openshift.yml` values file is configured with an example persistent volume claim using a certain storage class.

#### **Helm chart**
To deploy the helm chart directly in a RedHat OpenShift cluster we have the `mdcore-openshift.yml` values file. This file can be used as an example of the changes required for OpenShift:
- **PostgreSQL image**: the docker image has been changed to use the RedHat repo: `registry.redhat.io/rhel8/postgresql-12`
- **Storage**: a persistent volume claim has been configured to use an existing storage class since `hostPath` is not supported on an unprivileged container

Example installation when using local helm files and setting the custom values manually:
```
helm install my_mdcore ./helm_charts/mdcore -f mdcore-openshift.yml \
 --set 'db_password=<SET_POSTGRES_PASSWORD>' \
 --set 'env.POSTGRESQL_ADMIN_PASSWORD=<SET_POSTGRES_ADMIN_PASSWORD>' \
 --set 'storage_configs.pvc-example.spec.storageClassName=<SET_STORAGE_CLASS_NAME>' \
 --set 'mdcore_license_key=<SET_LICENSE_KEY>'
```

#### **Exposing MD Core**
After installation MD Core can be exposed in OpenShift by creating a new route in the `Networking -> Routes` section with the following settings:
- Path: `/`
- Service: `md-core`
- Target port: `8008 -> 8008`

An ingress is also created by default and can be disabled by setting the `core_ingress.enabled` value to `false` .


### MD Hub deployment
Example values for enabling the MD Hub module can be found in the `mdcore-mdhub-module.yml` file. By setting the `ENABLED_MODULES: "mdhub"` value, the chart configures and deploys the following additional pods:
- redis (open-source caching server)
- rabbitmq (open-source messaging broker)
- md-hub (known as MetaDefender Core Hub )
- md-nas (central file storage server, known as MetaDefender Core NAS)

In addition to enabling the `mdhub` module, the `md-nas` pod also requires an ssl certificate and certificate key that can be configured from the values file:
```
CERT_KEY: |
  <SET_MD_NAS_CERT_KEY>
CERT: |
  <SET_MD_NAS_CERT>
```

The `md-hub` service listens by default on port `8889` as a ClusterIP. Changing the port from the values file also updates the configuration file mounted in the md-hub container.
```
core_components:
  md-hub:
    ports:
      - port: 8889
    service_type: ClusterIP
```
Credentials can also be configured in the values file and are saved as secrets, they are randomly generated if left unset. Once configured, the entire MD Core and Hub stack can be deployed with helm:
```
helm install my_mdcore ./helm_charts/mdcore -f mdcore-mdhub-module.yml
```
Additional MD Hub documentation can be found here: https://docs.opswat.com/mdcore/central-hub-deployment/overview

## Operational Notes
The entire deployment can be customized by overwriting the chart's default configuration values. Here are a few point to look out for when changing these values:
- Sensitive values (like credentials and keys) are saved in the Kubernetes cluster as secrets and are not deleted when the chart is removed and they can be reused for future deployments
- Credentials that are not explicitly set (passwords and the api key) and do not already exist as k8s secrets will be randomly generated, if they are set, the respective k8s secret will be updated or created if it doesn't exist
- **The license key value is mandatory**, if it's left unset or if it's invalid, the MD Core instance will report as "unhealthy" and it will be restarted
- The configured license should have a sufficient number of activations for all pod running MD Core, each pod counts as 1 activation. Terminating pods will also deactivate the respective MD Core instance.
- By default, a PostgreSQL database is deployed alongside the MD Core deployment with the same credentials as set in the values file
- In a production environment it's recommended to use an external service for the database (like Amazon RDS) and set `deploy_with_core_db` to false in order to not deploy an in-cluster database
- The deployed MD Core pod has a startup container that will wait for a database connection before allowing MD Core to start

## Configuration

The following table lists the configurable parameters of the Metadefender core chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `mdcore_user` | Initial admin user for the MD Core web interface | `"admin"` |
| `mdcore_password` | Initial admin password for the MD Core web interface, if not set it will be randomly generated | `null` |
| `core_db_user` | PostgreSQL database username | `"postgres"` |
| `core_db_password` | PostgreSQL database password, if not set it will be randomly generated | `null` |
| `mdcore_api_key` | 36 character API key used for the MD Core REST API, if not set it will be randomly generated | `null` |
| `mdcore_license_key` | A valid license key, **this value is mandatory** | `"<SET_LICENSE_KEY_HERE>"` |
| `activation_server` | URL to the OPSWAT activation server, this value should not be changed | `"activation.dl.opswat.com"` |
| `MDCORE_REST_PORT` | Default port for the MD Core service | `"8008"` |
| `MDCORE_DB_MODE` | Database mode | `"4"` |
| `MDCORE_DB_TYPE` | Database type | `"remote"` |
| `MDCORE_DB_HOST` | Hostname / entrypoint of the database, this value should be changed any if using an external database service | `"postgres-core"` |
| `MDCORE_DB_PORT` | Port for the PostgreSQL Database | `"5432"` |
| `deploy_with_core_db` | Enable or disable the local in-cluster PostgreSQL database | `true` |
| `persistance_enabled` |  | `true` |
| `storage_provisioner` |  | `"hostPath"` |
| `storage_name` |  | `"hostPath"` |
| `storage_node` |  | `"minikube"` |
| `hostPathPrefix` | If `deploy_with_core_db` is set to true, this is the absolute path on the node where to keep the database filesystem for persistance | `"mdcore-storage"` |
| `environment` | Deployment environment type, the default `generic` value will not configure or provision any additional resources in the cloud provider (like load balancers), other values: `aws_eks_fargate` | `"generic"` |
| `install_alb` | If set to true and `environment` is set to `aws_eks_fargate`, an ALB ingress controller will be installed | `true` |
| `eks_cluster_name` | Name of the EKS cluster, mandatory only if `environment` is set to `aws_eks_fargate` | `null` |
| `app_name` | Application name, it also sets the namespace on all created resources and replaces `<APP_NAME>` in the ingress host (if the ingress is enabled) | `"default"` |
| `core_ingress.host` | Hostname for the publicly accessible ingress, the `<APP_NAME>` string will be replaced with the `app_name` value | `"<APP_NAME>-mdss.local"` |
| `core_ingress.service` | Service name where the ingress should route to, this should be left unchanged | `"md-core"` |
| `core_ingress.port` | Port where the ingress should route to | `8008` |
| `core_ingress.enabled` | Enable or disable the ingress creation | `false` |
| `core_ingress.class` | Sets the ingress class | `"nginx"` |
| `core_docker_repo` |  | `"opswat"` |
| `core_components.postgres-core.name` |  | `"postgres-core"` |
| `core_components.postgres-core.image` |  | `"postgres"` |
| `core_components.postgres-core.env` |  | `[{"name": "POSTGRES_PASSWORD", "valueFrom": {"secretKeyRef": {"name": "mdcore-postgres-cred", "key": "password"}}}, {"name": "POSTGRES_USER", "valueFrom": {"secretKeyRef": {"name": "mdcore-postgres-cred", "key": "user"}}}]` |
| `core_components.postgres-core.ports` |  | `[{"port": 5432}]` |
| `core_components.postgres-core.is_db` |  | `true` |
| `core_components.postgres-core.persistentDir` |  | `"/var/lib/postgresql/data"` |
| `core_components.md-core.name` |  | `"md-core"` |
| `core_components.md-core.image` | Overrides the default docker image for the MD Core service, this value can be changed if you want to set a different version of MD Core | `"opswat/metadefendercore-debian:5.0.1"` |
| `core_components.md-core.replicas` | Sets the number of replicas if you want to have multiple MD Core instances | `1` |
| `core_components.md-core.env` |  | `[{"name": "MD_USER", "valueFrom": {"secretKeyRef": {"name": "mdcore-cred", "key": "user"}}}, {"name": "MD_PWD", "valueFrom": {"secretKeyRef": {"name": "mdcore-cred", "key": "password"}}}, {"name": "MD_INSTANCE_NAME", "valueFrom": {"fieldRef": {"fieldPath": "metadata.name"}}}, {"name": "APIKEY", "valueFrom": {"secretKeyRef": {"name": "mdcore-api-key", "key": "value"}}}, {"name": "LICENSE_KEY", "valueFrom": {"secretKeyRef": {"name": "mdcore-license-key", "key": "value"}}}, {"name": "DB_USER", "valueFrom": {"secretKeyRef": {"name": "mdcore-postgres-cred", "key": "user"}}}, {"name": "DB_PWD", "valueFrom": {"secretKeyRef": {"name": "mdcore-postgres-cred", "key": "password"}}}]` |
| `core_components.md-core.ports` |  | `[{"port": 8008}]` |
| `core_components.md-core.service_type` | Sets the service type for MD Core service (ClusterIP, NodePort, LoadBalancer) | `"ClusterIP"` |
| `core_components.md-core.extra_labels.aws-type` | If `aws-type` is set to `fargate`, the MD Core pod will be scheduled on an AWS Fargate virtual node (if a fargate profile is provisioned and configured) | `"fargate"` |
| `core_components.md-core.resources.requests.memory` | Minimum reserved memory | `"4Gi"` |
| `core_components.md-core.resources.requests.cpu` | Minimum reserved cpu | `"1.0"` |
| `core_components.md-core.resources.limits.memory` | Maximum memory limit | `"8Gi"` |
| `core_components.md-core.resources.limits.cpu` | Maximum cpu limit | `"1.0"` |
| `core_components.md-core.livenessProbe.httpGet.path` | Health check endpoint | `"/readyz"` |
| `core_components.md-core.livenessProbe.httpGet.port` | Health check port | `8008` |
| `core_components.md-core.livenessProbe.initialDelaySeconds` |  | `10` |
| `core_components.md-core.livenessProbe.periodSeconds` |  | `3` |
| `core_components.md-core.livenessProbe.timeoutSeconds` |  | `5` |
| `core_components.md-core.livenessProbe.failureThreshold` |  | `3` |
| `core_components.md-core.strategy.type` |  | `"RollingUpdate"` |
| `core_components.md-core.strategy.rollingUpdate.maxSurge` |  | `0` |
| `podAnnotations` |  | `{}` |
| `podSecurityContext` |  | `{}` |
| `securityContext` |  | `{}` |
| `nodeSelector` |  | `{}` |
| `tolerations` |  | `[]` |
| `affinity` |  | `{}` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

