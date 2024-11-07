
Metadefender_software_supply_chain
===========

This is a Helm chart for deploying MetaDefender Software Supply Chain (https://www.opswat.com/products/metadefender/software-supply-chain) in a Kubernetes cluster

This chart can deploy the following depending on the provided values:
- All MDSSC services in separate pods 
- A MongoDB database instance pre-configured to be used by MDSSC

## Installation

### From source
MDSSC can be installed directly from the source code, here's an example using generic values:
```console
git clone https://github.com/OPSWAT/metadefender-k8s.git metadefender
cd metadefender/helm_carts
helm install my_mdssc ./mdssc
```

### From the GitHub helm repo
The installation can also be done using the helm repo which is updated on each release:
```console
helm repo add mdk8s https://opswat.github.io/metadefender-k8s/
helm repo update mdk8s
helm install my_mdssc mdk8s/metadefender_software_supply_chain
```

## Operational Notes
The entire deployment can be customized by overwriting the chart's default configuration values. Here are a few point to look out for when changing these values:
- By default, a MongoDB database is deployed alongside the MDSSC deployment
- In a production environment it's recommended to use an external service for the database  and set `deploy_with_mdssc_db` to false in order to not deploy an in-cluster database

## Configuration

The following table lists the configurable parameters of the Metadefender_software_supply_chain chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `mdssc-common-environment.DISCOVERY_STRATEGY` |  | `"ImageArchiveDiscovery"` |
| `mdssc-common-environment.API_DEV_PORT` |  | `"8001 "` |
| `mdssc-common-environment.PRODUCT_NAME` |  | `"MetaDefender Software Supply Chain"` |
| `mdssc-common-environment.PRODUCT_NAME_SHORT` |  | `"MDSSC"` |
| `mdssc-common-environment.EULA_ACCEPTED_AFTER_UPGRADE` |  | `"yes"` |
| `mdssc-common-environment.ENABLED_MODULES` |  | `"github,dockerhub,bitbucket,amazonecr,quay,jfrogcontainer,jfrogbinary"` |
| `mdssc-common-environment.MONGO_URL` |  | `"mongodb://mongodb:27017/MDCS"` |
| `mdssc-common-environment.MONGO_SSL_ALLOW_INVALID_CERTIFICATES` |  | `"false"` |
| `mdssc-common-environment.MONGO_CA_CERTIFICATE` |  | `""` |
| `mdssc-common-environment.MONGO_DB` |  | `"MDCS"` |
| `mdssc-common-environment.MONGO_MIGRATIONS_HOST` |  | `"mongomigrations"` |
| `mdssc-common-environment.MONGO_MIGRATIONS_PORT` |  | `"27777"` |
| `mdssc-common-environment.RABBITMQ_URI` |  | `"amqp://rabbitmq:5672"` |
| `mdssc-common-environment.RABBITMQ_HOST` |  | `"rabbitmq"` |
| `mdssc-common-environment.RABBITMQ_PORT` |  | `"5672"` |
| `mdssc-common-environment.RABBITMQ_DEFAULT_PASS` |  | `"guest"` |
| `mdssc-common-environment.RABBITMQ_DEFAULT_USER` |  | `"guest"` |
| `mdssc-common-environment.APIGATEWAY_PORT` |  | `"8005"` |
| `mdssc-common-environment.APIGATEWAY_PORT_SSL` |  | `"8006"` |
| `mdssc-common-environment.NGINX_TIMEOUT` |  | `"300"` |
| `mdssc-common-environment.BACKUPS_TO_KEEP` |  | `"3"` |
| `mdssc-common-environment.LICENSINGSERVICE_HOST` |  | `"licensingservice"` |
| `mdssc-common-environment.LICENSINGSERVICE_URL` |  | `"http://licensingservice"` |
| `mdssc-common-environment.LICENSINGSERVICE_PORT` |  | `"5000"` |
| `mdssc-common-environment.SMBSERVICE_URL` |  | `"http://smbservice"` |
| `mdssc-common-environment.SMBSERVICE_PORT` |  | `"5002"` |
| `mdssc-common-environment.CODE_VERSION` |  | `"30a858390ca19fff81f2092f83a32f11c07d4fc8"` |
| `mdssc-common-environment.BUILD_VERSION` |  | `"3.4.1.369"` |
| `mdssc-common-environment.RABBITMQ_SCANNING_PREFETCH_COUNT` |  | `"20"` |
| `mdssc-common-environment.HTTPS_ACTIVE` |  | `"no"` |
| `mdssc-common-environment.BRANCH` | Set Platform version (image tag) | `"3.4.1"` |
| `mdssc-common-environment.MDSSC_BRANCH` | Set MDSSC version (image tag) | `"stable"` |
| `mdssc-common-environment.LOG_LEVEL` |  | `"4"` |
| `mdssc-common-environment.APP_LOG_LEVEL` |  | `"INFORMATION"` |
| `mdssc-common-environment.SMB_SHORT_DEADLINE` |  | `"5"` |
| `mdssc-common-environment.SMB_LONG_DEADLINE` |  | `"30"` |
| `mdssc-common-environment.POLLY_RETRY_COUNT` |  | `"3"` |
| `mdssc-common-environment.POLLY_LONG_RETRY` |  | `"5"` |
| `mdssc-common-environment.POLLY_SHORT_RETRY` |  | `"1"` |
| `mdssc-common-environment.SMB_UPLOAD_CHUNK` |  | `"2"` |
| `mdssc-common-environment.DISCOVERY_SERVICE_SMB_RTP_HANDLING` |  | `"0"` |
| `mdssc-common-environment.MD_CORE_CERTIFICATE_VALIDATION` |  | `"0"` |
| `mdssc-common-environment.POLLY_LONG_RETRY_BOX` |  | `"2"` |
| `mdssc-common-environment.POLLY_SHORT_RETRY_BOX` |  | `"1"` |
| `mdssc-common-environment.POLLY_POST_ACTION_RETRY_TIME` |  | `"30"` |
| `mdssc-common-environment.LOAD_BALANCER_MD_CORE_UNAVAILABLE_TIME` |  | `"5"` |
| `mdssc-common-environment.WEBCLIENT_HOST` |  | `"webclient"` |
| `mdssc-common-environment.AZURE_BLOBS_PAGE_SIZE` |  | `"100"` |
| `mdssc-common-environment.DISCOVERY_SERVICE_IGNORE_EMPTY_OBJECTS` |  | `"0"` |
| `mdssc-common-environment.DISCOVERY_SERVICE_REPROCESSING_FAILED_TIME_HOURS` |  | `"24"` |
| `mdssc-common-environment.MARK_STUCK_FILE_AS_FAILED_HOURS` |  | `"24"` |
| `mdssc-common-environment.CACHE_SERVICE_URI` |  | `"redis:6379"` |
| `mdssc-common-environment.CACHE_SERVICE_URL` |  | `"redis"` |
| `mdssc-common-environment.CACHE_SERVICE_PORT` |  | `"6379"` |
| `mdssc-common-environment.POLLY_RETRY_TIME` |  | `"30"` |
| `mdssc-common-environment.OBJECT_CONTENT_REDIS_TTL` |  | `"30"` |
| `mdssc-common-environment.RABBITMQ_RPC_LONG_TIMEOUT` | minutes | `"5"` |
| `mdssc-common-environment.LICENSINGSERVICE_LISTENING_IP` |  | `"0.0.0.0"` |
| `mdssc-common-environment.SFTPSERVICE_URL` |  | `"http://sftpservice"` |
| `mdssc-common-environment.SFTPSERVICE_PORT` |  | `"5003"` |
| `mdssc-common-environment.SFTP_SHORT_DEADLINE` |  | `"5"` |
| `mdssc-common-environment.SFTP_LONG_DEADLINE` |  | `"30"` |
| `mdssc-common-environment.SFTP_UPLOAD_CHUNK` |  | `"2"` |
| `mdssc-common-environment.FORCE_AWS_SIGNATURE_V4` |  | `"1"` |
| `mdssc-common-environment.NFSSERVICE_URL` |  | `"http://nfsservice"` |
| `mdssc-common-environment.NFSSERVICE_PORT` |  | `"5004"` |
| `mdssc-common-environment.NFS_SHORT_DEADLINE` |  | `"5"` |
| `mdssc-common-environment.NFS_LONG_DEADLINE` |  | `"30"` |
| `mdssc-common-environment.NFS_UPLOAD_CHUNK` |  | `"2"` |
| `mdssc-common-environment.SMBSERVICE_FILE_READY_CHECK_MODE` |  | `"1"` |
| `mdssc-common-environment.SMBSERVICE_PREFETCH_COUNT` |  | `"10"` |
| `mdssc-common-environment.DISCOVERY_SERVICE_SFTP_RTP_HANDLING` |  | `"0"` |
| `mdssc-common-environment.DISCOVERY_SERVICE_NFS_RTP_HANDLING` |  | `"0"` |
| `mdssc-common-environment.TOKEN_EXPIRY_TIME_HOURS` |  | `"1"` |
| `mdssc-common-environment.SFTP_DISCOVERY_DEBOUNCE_TIME_SECONDS` |  | `"5"` |
| `mdssc-common-environment.NFS_DISCOVERY_DEBOUNCE_TIME_SECONDS` |  | `"5"` |
| `mdssc-common-environment.SMBSERVICE_SESSION_RETRY_WAIT_TIME` |  | `"5"` |
| `mdssc-common-environment.SMBSERVICE_SESSION_MAX_RETRIES` |  | `"3"` |
| `mdssc-common-environment.SMBSERVICE_SESSIONS_ON_STORAGE` |  | `"10"` |
| `mdssc-common-environment.DISCOVERY_COMPLETED_CHECK_SECONDS` |  | `"10"` |
| `deploy_with_mdssc_db` | Enable or disable the local in-cluster database, set to false when deploying with an external database service | `true` |
| `persistance_enabled` |  | `true` |
| `hpa.enabled` |  | `false` |
| `hpa.minReplicas` |  | `2` |
| `hpa.maxReplicas` |  | `3` |
| `hpa.cpuTargetUtilization` |  | `85` |
| `storage_provisioner` |  | `"hostPath"` |
| `storage_name` |  | `"hostPath"` |
| `storage_node` |  | `"minikube"` |
| `hostPathPrefix` | This is the absolute path on the node where to keep the database filesystem for persistance, <APP_NAMESPACE> is replaced with the current deployment namespace | `"mdssc-storage-<APP_NAMESPACE>"` |
| `mdssc_ingress.host` | Hostname for the publicly accessible ingress, the `<APP_NAMESPACE>` string will be replaced with the current namespace | `"<APP_NAMESPACE>-mdssc.k8s"` |
| `mdssc_ingress.service` | Service name where the ingress should route to, this should be left unchanged | `"webclient"` |
| `mdssc_ingress.port` | Port where the ingress should route to | `80` |
| `mdssc_ingress.enabled` | Enable or disable the ingress creation | `false` |
| `mdssc_ingress.class` | Sets the ingress class, it can be "public" or "nginx" or some other value depending on the ingress controller in the cluster | `"public"` |
| `auto_onboarding` | If set to true, it will deploy a container that will do the initial setup automatically if correct values are provided | `false` |
| `mdssc_import_config` | Content of config file to be imported by the onboarding container | `null` |
| `ONBOARDING_USER_NAME` | User name of user that will be created by onboarding container (defaults to admin if left unset) | `null` |
| `ONBOARDING_PASSWORD` | Password of user that will be created by onboarding container (randomly generated if left unset, can be retrieved from the "onboarding-env" secret) | `null` |
| `ONBOARDING_EMAIL` | Email of user that will be created by onboarding container | `null` |
| `ONBOARDING_FULL_NAME` | Full name of user that will be created by onboarding container | `null` |
| `mdssc_docker_repo` |  | `"opswat"` |
| `imagePullPolicy` |  | `"IfNotPresent"` |
| `mdssc_config_map_env_name` |  | `"mdssc-env"` |
| `mdsscHostAliases` | Custom hosts entries | `[{"ip": "10.0.1.16", "hostnames": ["s3-us-west-1.cloudian-sf", "test.s3-us-west-1.cloudian-sf", "small.s3-us-west-1.cloudian-sf"]}]` |
| `mdssc_components.mongodb.name` |  | `"mongodb"` |
| `mdssc_components.mongodb.image` |  | `"mongo:3.6"` |
| `mdssc_components.mongodb.ports` |  | `[{"port": 27017}]` |
| `mdssc_components.mongodb.persistentDir` |  | `"/data/db"` |
| `mdssc_components.mongodb.is_db` |  | `true` |
| `mdssc_components.mongodb.resources.requests.memory` |  | `"2Gi"` |
| `mdssc_components.mongodb.resources.requests.cpu` |  | `"0.5"` |
| `mdssc_components.mongomigrations.name` |  | `"mongomigrations"` |
| `mdssc_components.mongomigrations.custom_repo` |  | `true` |
| `mdssc_components.mongomigrations.image` |  | `"mdcloudservices_mongo-migrations"` |
| `mdssc_components.mongomigrations.ports` |  | `[{"port": 27777}]` |
| `mdssc_components.mongomigrations.persistentDir` |  | `"/backup"` |
| `mdssc_components.mongomigrations.resources.requests.memory` |  | `"0.125Gi"` |
| `mdssc_components.mongomigrations.resources.requests.cpu` |  | `"0.010"` |
| `mdssc_components.rabbitmq.name` |  | `"rabbitmq"` |
| `mdssc_components.rabbitmq.image` |  | `"rabbitmq:3.11.4-management"` |
| `mdssc_components.rabbitmq.ports` |  | `[{"port": 5672}, {"port": 15672}]` |
| `mdssc_components.rabbitmq.mountConfig.configName` |  | `"rabbitmq-config"` |
| `mdssc_components.rabbitmq.mountConfig.mountPath` |  | `"/data/rabbitmq/advanced.config"` |
| `mdssc_components.rabbitmq.mountConfig.subPath` |  | `"advanced.config"` |
| `mdssc_components.rabbitmq.env` |  | `[{"name": "RABBITMQ_ADVANCED_CONFIG_FILE", "value": "/data/rabbitmq/advanced.config"}]` |
| `mdssc_components.rabbitmq.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.rabbitmq.resources.requests.memory` |  | `"0.5Gi"` |
| `mdssc_components.rabbitmq.resources.requests.cpu` |  | `"0.5"` |
| `mdssc_components.redis.name` |  | `"redis"` |
| `mdssc_components.redis.image` |  | `"redis:7.0"` |
| `mdssc_components.redis.ports` |  | `[{"port": 6379}]` |
| `mdssc_components.redis.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.redis.resources.requests.memory` |  | `"0.125Gi"` |
| `mdssc_components.redis.resources.requests.cpu` |  | `"0.100"` |
| `mdssc_components.licensingservice.name` |  | `"licensingservice"` |
| `mdssc_components.licensingservice.custom_repo` |  | `true` |
| `mdssc_components.licensingservice.image` |  | `"mdcloudservices_licensing"` |
| `mdssc_components.licensingservice.ports` |  | `[{"port": 5000}]` |
| `mdssc_components.licensingservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.licensingservice.resources.requests.memory` |  | `"0.125Gi"` |
| `mdssc_components.licensingservice.resources.requests.cpu` |  | `"0.010"` |
| `mdssc_components.frontend.name` |  | `"frontend"` |
| `mdssc_components.frontend.is_mdssc` |  | `true` |
| `mdssc_components.frontend.custom_repo` |  | `true` |
| `mdssc_components.frontend.image` |  | `"mdssc_frontend"` |
| `mdssc_components.frontend.ports` |  | `[{"port": 443}, {"port": 80}]` |
| `mdssc_components.frontend.mountConfig.configName` |  | `"webclient-nginx-config"` |
| `mdssc_components.frontend.mountConfig.mountPath` |  | `"/etc/nginx/conf.d/default.conf"` |
| `mdssc_components.frontend.mountConfig.subPath` |  | `"default.conf"` |
| `mdssc_components.frontend.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.frontend.resources.requests.memory` |  | `"0.25Gi"` |
| `mdssc_components.frontend.resources.requests.cpu` |  | `"0.100"` |
| `mdssc_components.api.name` |  | `"api"` |
| `mdssc_components.api.is_mdssc` |  | `true` |
| `mdssc_components.api.custom_repo` |  | `true` |
| `mdssc_components.api.image` |  | `"mdssc_api"` |
| `mdssc_components.api.env` |  | `[{"name": "ASPNETCORE_URLS", "value": "http://+"}]` |
| `mdssc_components.api.ports` |  | `[{"port": 443}, {"port": 80}]` |
| `mdssc_components.api.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.api.resources.requests.memory` |  | `"0.5Gi"` |
| `mdssc_components.api.resources.requests.cpu` |  | `"0.100"` |
| `mdssc_components.github.name` |  | `"github"` |
| `mdssc_components.github.is_mdssc` |  | `true` |
| `mdssc_components.github.custom_repo` |  | `true` |
| `mdssc_components.github.image` |  | `"mdssc_github"` |
| `mdssc_components.github.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.github.resources.requests.memory` |  | `"0.125Gi"` |
| `mdssc_components.github.resources.requests.cpu` |  | `"0.010"` |
| `mdssc_components.binaries.name` |  | `"binaries"` |
| `mdssc_components.binaries.is_mdssc` |  | `true` |
| `mdssc_components.binaries.custom_repo` |  | `true` |
| `mdssc_components.binaries.image` |  | `"mdssc_binaries"` |
| `mdssc_components.binaries.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.binaries.resources.requests.memory` |  | `"0.125Gi"` |
| `mdssc_components.binaries.resources.requests.cpu` |  | `"0.010"` |
| `mdssc_components.dockerhub.name` |  | `"dockerhub"` |
| `mdssc_components.dockerhub.is_mdssc` |  | `true` |
| `mdssc_components.dockerhub.custom_repo` |  | `true` |
| `mdssc_components.dockerhub.image` |  | `"mdssc_dockerhub"` |
| `mdssc_components.dockerhub.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.dockerhub.resources.requests.memory` |  | `"0.125Gi"` |
| `mdssc_components.dockerhub.resources.requests.cpu` |  | `"0.010"` |
| `mdssc_components.ecr.name` |  | `"ecr"` |
| `mdssc_components.ecr.is_mdssc` |  | `true` |
| `mdssc_components.ecr.custom_repo` |  | `true` |
| `mdssc_components.ecr.image` |  | `"mdssc_ecr"` |
| `mdssc_components.ecr.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.ecr.resources.requests.memory` |  | `"0.125Gi"` |
| `mdssc_components.ecr.resources.requests.cpu` |  | `"0.010"` |
| `mdssc_components.quay.name` |  | `"quay"` |
| `mdssc_components.quay.is_mdssc` |  | `true` |
| `mdssc_components.quay.custom_repo` |  | `true` |
| `mdssc_components.quay.image` |  | `"mdssc_quay"` |
| `mdssc_components.quay.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.quay.resources.requests.memory` |  | `"0.125Gi"` |
| `mdssc_components.quay.resources.requests.cpu` |  | `"0.010"` |
| `mdssc_components.containers.name` |  | `"containers"` |
| `mdssc_components.containers.is_mdssc` |  | `true` |
| `mdssc_components.containers.custom_repo` |  | `true` |
| `mdssc_components.containers.image` |  | `"mdssc_containers"` |
| `mdssc_components.containers.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.containers.resources.requests.memory` |  | `"0.125Gi"` |
| `mdssc_components.containers.resources.requests.cpu` |  | `"0.010"` |
| `mdssc_components.workflowmanagerservice.name` |  | `"workflowmanagerservice"` |
| `mdssc_components.workflowmanagerservice.custom_repo` |  | `true` |
| `mdssc_components.workflowmanagerservice.image` |  | `"mdcloudservices_workflowmanager"` |
| `mdssc_components.workflowmanagerservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.workflowmanagerservice.resources.requests.memory` |  | `"0.25Gi"` |
| `mdssc_components.workflowmanagerservice.resources.requests.cpu` |  | `"0.100"` |
| `mdssc_components.loggingservice.name` |  | `"loggingservice"` |
| `mdssc_components.loggingservice.custom_repo` |  | `true` |
| `mdssc_components.loggingservice.image` |  | `"mdcloudservices_logging"` |
| `mdssc_components.loggingservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.loggingservice.resources.requests.memory` |  | `"0.25Gi"` |
| `mdssc_components.loggingservice.resources.requests.cpu` |  | `"0.050"` |
| `mdssc_components.remediationsservice.name` |  | `"remediationsservice"` |
| `mdssc_components.remediationsservice.custom_repo` |  | `true` |
| `mdssc_components.remediationsservice.image` |  | `"mdcloudservices_remediations"` |
| `mdssc_components.remediationsservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.remediationsservice.resources.requests.memory` |  | `"0.25Gi"` |
| `mdssc_components.remediationsservice.resources.requests.cpu` |  | `"0.100"` |
| `mdssc_components.storagesservice.name` |  | `"storagesservice"` |
| `mdssc_components.storagesservice.custom_repo` |  | `true` |
| `mdssc_components.storagesservice.image` |  | `"mdcloudservices_storages"` |
| `mdssc_components.storagesservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.storagesservice.resources.requests.memory` |  | `"0.25Gi"` |
| `mdssc_components.storagesservice.resources.requests.cpu` |  | `"0.010"` |
| `mdssc_components.discoveryservice.name` |  | `"discoveryservice"` |
| `mdssc_components.discoveryservice.custom_repo` |  | `true` |
| `mdssc_components.discoveryservice.image` |  | `"mdcloudservices_discovery"` |
| `mdssc_components.discoveryservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.discoveryservice.resources.requests.memory` |  | `"0.5Gi"` |
| `mdssc_components.discoveryservice.resources.requests.cpu` |  | `"1.000"` |
| `mdssc_components.scanningservice.name` |  | `"scanningservice"` |
| `mdssc_components.scanningservice.custom_repo` |  | `true` |
| `mdssc_components.scanningservice.image` |  | `"mdcloudservices_scanning"` |
| `mdssc_components.scanningservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.scanningservice.resources.requests.memory` |  | `"1Gi"` |
| `mdssc_components.scanningservice.resources.requests.cpu` |  | `"0.500"` |
| `mdssc_components.jobdispatcher.name` |  | `"jobdispatcher"` |
| `mdssc_components.jobdispatcher.custom_repo` |  | `true` |
| `mdssc_components.jobdispatcher.image` |  | `"mdcloudservices_job-dispatcher"` |
| `mdssc_components.jobdispatcher.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.jobdispatcher.resources.requests.memory` |  | `"0.25Gi"` |
| `mdssc_components.jobdispatcher.resources.requests.cpu` |  | `"0.050"` |
| `mdssc_components.loadbalancerservice.name` |  | `"loadbalancerservice"` |
| `mdssc_components.loadbalancerservice.custom_repo` |  | `true` |
| `mdssc_components.loadbalancerservice.image` |  | `"mdcloudservices_load-balancer"` |
| `mdssc_components.loadbalancerservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.loadbalancerservice.resources.requests.memory` |  | `"0.25Gi"` |
| `mdssc_components.loadbalancerservice.resources.requests.cpu` |  | `"0.100"` |
| `mdssc_components.usermanagementservice.name` |  | `"usermanagementservice"` |
| `mdssc_components.usermanagementservice.custom_repo` |  | `true` |
| `mdssc_components.usermanagementservice.image` |  | `"mdcloudservices_usermanagement"` |
| `mdssc_components.usermanagementservice.extra_labels.aws-type` |  | `"fargate"` |
| `mdssc_components.usermanagementservice.resources.requests.memory` |  | `"0.25Gi"` |
| `mdssc_components.usermanagementservice.resources.requests.cpu` |  | `"0.010"` |



---
_Documentation generated by [Frigate](https://frigate.readthedocs.io)._

