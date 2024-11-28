
Metadefender for secure storage
===========

This is a Helm chart for deploying MetaDefender for Secure Storage (https://docs.opswat.com/mdss/installation/kubernetes-deployment) in a Kubernetes cluster

This chart can deploy the following depending on the provided values:
- All MDSS services in separate pods 
- A MongoDB database instance pre-configured to be used by MDSS

In addition to the chart, we also provide a number of values files for specific scenarios:
- mdss-aws-eks-values.yml - for deploying in an AWS environment using Amazon EKS
- mdss-azure-aks-values.yml - for deploying in an Azure environment using AKS

## Installation

### From source
MDSS can be installed directly from the source code, here's an example using the generic values:
```console
git clone https://github.com/OPSWAT/metadefender-k8s.git metadefender
cd metadefender/helm_carts
helm install my_mdss ./mdss
```

### From the GitHub helm repo
The installation can also be done using the helm repo which is updated on each release:
```console
helm repo add mdk8s https://opswat.github.io/metadefender-k8s/
helm repo update mdk8s
helm install my_mdss mdk8s/metadefender_storage_security
```

### Flexible deployment
By default, the helm chart deploys MDSS with support for the following storage units: azureblob,amazonsdk,googlecloud,alibabacloud,azurefiles,box. For a more efficient use of resources, we can specify only the storage units that are required by changing the `ENABLED_MODULES` value. For example, we can enable support for just Azure, AWS and GCP:
```
ENABLED_MODULES: azureblob,azurefiles,amazonsdk,googlecloud
```
Currently supported modules:

`azureblob,amazonsdk,googlecloud,alibabacloud,azurefiles,smb,box,onedrive,sftp,debug`

The `debug` module is reserved for deploying debug and maintenance pods.

## Upgrading
The helm upgrade command can be used to upgrade the mdss services using the latest helm chart:
```
helm upgrade my_mdss <path_to_chart>
```
### Database upgrades
**This step is not required when using an external, managed database**

The helm chart is configured by default to use the latest compatible version of MongoDB. Before upgrading an existing deployment with persistent database, make sure that the database is upgraded to the specific version for the coresponding release:
 - MDSS 3.5.1 - MongoDB 6.0

The MongoDB upgrade procedure needs to be done sequentially following all intermediate releases.

The following components are non-persistent and can be updated to the latest compatible version by setting the respective image tag:
 - RabbitMQ: rabbitmq:3.11.4-management
 - Redis Cache: redis:7.0

## Operational Notes
The entire deployment can be customized by overwriting the chart's default configuration values. Here are a few point to look out for when changing these values:
- By default, a MongoDB database is deployed alongside the MDSS deployment
- In a production environment it's recommended to use an external service for the database  and set `deploy_with_mdss_db` to false in order to not deploy an in-cluster database
- By default, when accessing the MDSS web interface for the first time, the user onboarding process is presented and the initial credentials must be set. To skip this and have a preconfigured user and an initial setup, the following values can be set:
```yaml
# Auto onboarding settings
auto_onboarding: true                  # If set to true, it will deploy a container that will do the initial setup automatically if correct values are provided
mdss_import_config: null                # Content of config file to be imported by the onboarding container
ONBOARDING_USER_NAME: null              # User name of user that will be created by onboarding container (defaults to admin if left unset)
ONBOARDING_PASSWORD: null               # Password of user that will be created by onboarding container (randomly generated if left unset, can be retrieved from the "onboarding-env" secret)
ONBOARDING_EMAIL: null                  # Email of user that will be created by onboarding container
ONBOARDING_FULL_NAME: null              # Full name of user that will be created by onboarding container
```

## Configuration

The following table lists the configurable parameters of the Metadefender for secure storage chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `MONGO_URL` | MongoDB connection string, this should be set only when using a remote database service | `"mongodb://mongodb:27017/MDCS"` |
| `MONGO_MIGRATIONS_HOST` |  | `"mongomigrations"` |
| `MONGO_MIGRATIONS_PORT` |  | `27777` |
| `RABBITMQ_HOST` |  | `"rabbitmq"` |
| `RABBITMQ_PORT` |  | `5672` |
| `APIGATEWAY_PORT` |  | `8005` |
| `APIGATEWAY_PORT_SSL` |  | `8006` |
| `WEB_PORT` | HTTP port for the MDSS service | `80` |
| `WEB_PORT_SSL` | HTTPS port for the MDSS service | `443` |
| `NGINX_TIMEOUT` | Sets a custom timeout | `300` |
| `BACKUPS_TO_KEEP` |  | `3` |
| `LICENSINGSERVICE_HOST` |  | `"licensingservice"` |
| `LICENSINGSERVICE_URL` |  | `"http://licensingservice"` |
| `LICENSINGSERVICE_PORT` |  | `5000` |
| `SMBSERVICE_URL` |  | `"http://smbservice"` |
| `SMBSERVICE_PORT` |  | `5002` |
| `RABBITMQ_SCANNING_PREFETCH_COUNT` |  | `20` |
| `CORE_INCLUDED` |  | `"no"` |
| `CORE_VERSION` |  | `"v4.17.1-1"` |
| `CORE_PORT` |  | `35000` |
| `HTTPS_ACTIVE` |  | `"no"` |
| `MAC_ADDRESS` |  | `"02:42:ac:11:ff:ff"` |
| `HOSTNAME` |  | `"mds_host"` |
| `BRANCH` | Sets a custom MDSS branch for testing/preview versions, this value should be set to stable for production use | `"stable"` |
| `LOG_LEVEL` |  | `4` |
| `APP_LOG_LEVEL` |  | `"INFORMATION"` |
| `SMB_SHORT_DEADLINE` |  | `5` |
| `SMB_LONG_DEADLINE` |  | `30` |
| `POLLY_RETRY_COUNT` |  | `3` |
| `POLLY_LONG_RETRY` |  | `5` |
| `POLLY_SHORT_RETRY` |  | `1` |
| `SMB_UPLOAD_CHUNK` |  | `2` |
| `SMBSERVICE_FOLLOW_SYMLINKS` |  | `0` |
| `DISCOVERY_SERVICE_PERFORMANCE_OPTIMIZATION` |  | `0` |
| `DISCOVERY_SERVICE_DEGREE_OF_PARALLELISM` |  | `10` |
| `DISCOVERY_SERVICE_SMB_RTP_PROCESS_HANDLING` |  | `0` |
| `MD_CORE_CERTIFICATE_VALIDATION` |  | `0` |
| `POLLY_LONG_RETRY_BOX` |  | `2` |
| `POLLY_SHORT_RETRY_BOX` |  | `1` |
| `POLLY_POST_ACTION_RETRY_TIME` |  | `30` |
| `LOAD_BALANCER_MD_CORE_UNAVAILABLE_TIME` |  | `5` |
| `WEBCLIENT_HOST` |  | `"webclient"` |
| `deploy_with_mdss_db` | Enable or disable the local in-cluster database, set to false when deploying with an external database service | `true` |
| `persistance_enabled` |  | `true` |
| `storage_provisioner` |  | `"hostPath"` |
| `storage_name` |  | `"hostPath"` |
| `storage_node` |  | `"minikube"` |
| `hostPathPrefix` | If `deploy_with_mdss_db` is set to true, this is the absolute path on the node where to keep the database filesystem for persistance | `"mdss-storage"` |
| `environment` | Deployment environment type, the default `generic` value will not configure or provision any additional resources in the cloud provider (like load balancers), other values: `aws_eks_fargate` | `"generic"` |
| `install_alb` | If set to true and `environment` is set to `aws_eks_fargate`, an ALB ingress controller will be installed | `true` |
| `eks_cluster_name` | Name of the EKS cluster, mandatory only if `environment` is set to `aws_eks_fargate` | `null` |
| `vpc_id` | ID of the AWS VPC, mandatory only if `environment` is set to `aws_eks_fargate` | `null` |
| `aws_region` | AWS region code, mandatory only if `environment` is set to `aws_eks_fargate` | `null` |
| `AWS_ACCESS_KEY_ID` | AWS access key id, mandatory only if `environment` is set to `aws_eks_fargate` | `null` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key, mandatory only if `environment` is set to `aws_eks_fargate` | `null` |
| `app_name` | Application name, it also sets the namespace on all created resources and replaces `<APP_NAME>` in the ingress host (if the ingress is enabled) | `"default"` |
| `mdss_ingress.host` | Hostname for the publicly accessible ingress, the `<APP_NAME>` string will be replaced with the `app_name` value | `"<APP_NAME>-mdss.k8s"` |
| `mdss_ingress.service` | Service name where the ingress should route to, this should be left unchanged | `"webclient"` |
| `mdss_ingress.port` | Port where the ingress should route to | `80` |
| `mdss_ingress.enabled` | Enable or disable the ingress creation | `false` |
| `mdss_ingress.class` | Sets the ingress class | `"nginx"` |
| `mdss_docker_repo` |  | `"opswat"` |
| `mdss_config_map_env_name` |  | `"mdss-env"` |
| `mdssHostAliases` | Custom hosts entries | `[{"ip": "10.0.1.16", "hostnames": ["s3-us-west-1.cloudian-sf", "test.s3-us-west-1.cloudian-sf", "small.s3-us-west-1.cloudian-sf"]}]` |
| `mdss_components.mongodb.name` |  | `"mongodb"` |
| `mdss_components.mongodb.image` |  | `"mongo:3.6"` |
| `mdss_components.mongodb.ports` |  | `[{"port": 27017}]` |
| `mdss_components.mongodb.persistentDir` |  | `"/data/db"` |
| `mdss_components.mongodb.is_db` |  | `true` |
| `mdss_components.mongomigrations.name` |  | `"mongomigrations"` |
| `mdss_components.mongomigrations.custom_repo` |  | `true` |
| `mdss_components.mongomigrations.image` |  | `"mdcloudservices_mongo-migrations"` |
| `mdss_components.mongomigrations.ports` |  | `[{"port": 27777}]` |
| `mdss_components.mongomigrations.persistentDir` |  | `"/backup"` |
| `mdss_components.rabbitmq.name` |  | `"rabbitmq"` |
| `mdss_components.rabbitmq.image` |  | `"rabbitmq:3.8"` |
| `mdss_components.rabbitmq.ports` |  | `[{"port": 5672}]` |
| `mdss_components.rabbitmq.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.licensingservice.name` |  | `"licensingservice"` |
| `mdss_components.licensingservice.custom_repo` |  | `true` |
| `mdss_components.licensingservice.image` |  | `"mdcloudservices_licensing"` |
| `mdss_components.licensingservice.ports` |  | `[{"port": 5000}]` |
| `mdss_components.licensingservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.smbservice.name` |  | `"smbservice"` |
| `mdss_components.smbservice.custom_repo` |  | `true` |
| `mdss_components.smbservice.image` |  | `"mdcloudservices_smbservice"` |
| `mdss_components.smbservice.ports` |  | `[{"port": 5002}]` |
| `mdss_components.smbservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.discoveryservice.name` |  | `"discoveryservice"` |
| `mdss_components.discoveryservice.custom_repo` |  | `true` |
| `mdss_components.discoveryservice.image` |  | `"mdcloudservices_s3-discovery"` |
| `mdss_components.discoveryservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.discoveryservice.resources.requests.memory` |  | `"2Gi"` |
| `mdss_components.discoveryservice.resources.requests.cpu` |  | `"1"` |
| `mdss_components.discoveryservice.resources.limits.memory` |  | `"4Gi"` |
| `mdss_components.discoveryservice.resources.limits.cpu` |  | `"1"` |
| `mdss_components.scanningservice.name` |  | `"scanningservice"` |
| `mdss_components.scanningservice.custom_repo` |  | `true` |
| `mdss_components.scanningservice.image` |  | `"mdcloudservices_scanning"` |
| `mdss_components.scanningservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.scanningservice.resources.requests.memory` |  | `"2Gi"` |
| `mdss_components.scanningservice.resources.requests.cpu` |  | `"1"` |
| `mdss_components.scanningservice.resources.limits.memory` |  | `"4Gi"` |
| `mdss_components.scanningservice.resources.limits.cpu` |  | `"1"` |
| `mdss_components.notificationservice.name` |  | `"notificationservice"` |
| `mdss_components.notificationservice.custom_repo` |  | `true` |
| `mdss_components.notificationservice.image` |  | `"mdcloudservices_notification"` |
| `mdss_components.notificationservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.notificationservice.resources.requests.memory` |  | `"2Gi"` |
| `mdss_components.notificationservice.resources.requests.cpu` |  | `"1"` |
| `mdss_components.notificationservice.resources.limits.memory` |  | `"4Gi"` |
| `mdss_components.notificationservice.resources.limits.cpu` |  | `"1"` |
| `mdss_components.jobdispatcher.name` |  | `"jobdispatcher"` |
| `mdss_components.jobdispatcher.custom_repo` |  | `true` |
| `mdss_components.jobdispatcher.image` |  | `"mdcloudservices_job-dispatcher"` |
| `mdss_components.jobdispatcher.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.jobdispatcher.resources.requests.memory` |  | `"2Gi"` |
| `mdss_components.jobdispatcher.resources.requests.cpu` |  | `"1"` |
| `mdss_components.jobdispatcher.resources.limits.memory` |  | `"4Gi"` |
| `mdss_components.jobdispatcher.resources.limits.cpu` |  | `"1"` |
| `mdss_components.postactionsservice.name` |  | `"postactionsservice"` |
| `mdss_components.postactionsservice.custom_repo` |  | `true` |
| `mdss_components.postactionsservice.image` |  | `"mdcloudservices_post-actions"` |
| `mdss_components.postactionsservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.postactionsservice.resources.requests.memory` |  | `"2Gi"` |
| `mdss_components.postactionsservice.resources.requests.cpu` |  | `"1"` |
| `mdss_components.postactionsservice.resources.limits.memory` |  | `"4Gi"` |
| `mdss_components.postactionsservice.resources.limits.cpu` |  | `"1"` |
| `mdss_components.apigateway.name` |  | `"apigateway"` |
| `mdss_components.apigateway.custom_repo` |  | `true` |
| `mdss_components.apigateway.image` |  | `"mdcloudservices_api"` |
| `mdss_components.apigateway.env` |  | `[{"name": "ASPNETCORE_URLS", "value": "http://+"}]` |
| `mdss_components.apigateway.ports` |  | `[{"port": 443}, {"port": 80}]` |
| `mdss_components.apigateway.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.webclient.name` |  | `"webclient"` |
| `mdss_components.webclient.custom_repo` |  | `true` |
| `mdss_components.webclient.image` |  | `"mdcloudservices_web"` |
| `mdss_components.webclient.ports` |  | `[{"port": 443}, {"port": 80}]` |
| `mdss_components.webclient.service_type` |  | `"ClusterIP"` |
| `mdss_components.webclient.mountConfig.configName` |  | `"webclient-nginx-config"` |
| `mdss_components.webclient.mountConfig.mountPath` |  | `"/etc/nginx/conf.d/default.conf"` |
| `mdss_components.webclient.mountConfig.subPath` |  | `"default.conf"` |
| `mdss_components.webclient.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.systemchecks.name` |  | `"systemchecks"` |
| `mdss_components.systemchecks.image` |  | `"mdcloudservices_systemchecks"` |
| `mdss_components.systemchecks.custom_repo` |  | `true` |
| `mdss_components.systemchecks.ports` |  | `[{"port": 443}, {"port": 80}]` |
| `mdss_components.systemchecks.mountConfig.configName` |  | `"systemchecks-nginx-config"` |
| `mdss_components.systemchecks.mountConfig.mountPath` |  | `"/etc/nginx/conf.d/default.conf"` |
| `mdss_components.systemchecks.mountConfig.subPath` |  | `"default.conf"` |
| `mdss_components.systemchecks.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.securitychecklistservice.name` |  | `"securitychecklistservice"` |
| `mdss_components.securitychecklistservice.custom_repo` |  | `true` |
| `mdss_components.securitychecklistservice.image` |  | `"mdcloudservices_security-checklist"` |
| `mdss_components.securitychecklistservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.loadbalancerservice.name` |  | `"loadbalancerservice"` |
| `mdss_components.loadbalancerservice.custom_repo` |  | `true` |
| `mdss_components.loadbalancerservice.image` |  | `"mdcloudservices_load-balancer"` |
| `mdss_components.loadbalancerservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.loadbalancerservice.resources.requests.memory` |  | `"2Gi"` |
| `mdss_components.loadbalancerservice.resources.requests.cpu` |  | `"1"` |
| `mdss_components.loadbalancerservice.resources.limits.memory` |  | `"4Gi"` |
| `mdss_components.loadbalancerservice.resources.limits.cpu` |  | `"1"` |
| `mdss_components.loggingservice.name` |  | `"loggingservice"` |
| `mdss_components.loggingservice.custom_repo` |  | `true` |
| `mdss_components.loggingservice.image` |  | `"mdcloudservices_logging"` |
| `mdss_components.loggingservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdss_components.loggingservice.resources.requests.memory` |  | `"2Gi"` |
| `mdss_components.loggingservice.resources.requests.cpu` |  | `"1"` |
| `mdss_components.loggingservice.resources.limits.memory` |  | `"4Gi"` |
| `mdss_components.loggingservice.resources.limits.cpu` |  | `"1"` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

