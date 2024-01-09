
Metadefender ICAP Server
===========

This is a Helm chart for deploying MetaDefender ICAP (https://www.opswat.com/products/metadefender/icap) in a Kubernetes cluster

This chart can deploy the following depending on the provided values:
- One or more MD ICAP Server instances 

## Installation

### 1. From source
MD ICAP Server can be installed directly from the source code, here's an example using the generic values:
```console
git clone https://github.com/OPSWAT/metadefender-k8s.git metadefender
cd metadefender/helm_charts
helm install my-mdicap ./icap
```

### 2. From the latest release
The installation can also be done using the latest release from github:
```console
helm install my-mdicap <MDICAP_RELEASE_URL>.tgz 
```

## Operational Notes
The entire deployment can be customized by overwriting the chart's default configuration values. Here are a few point to look out for when changing these values:
- Sensitive values (like credentials and keys) are saved in the Kubernetes cluster as secrets and are not deleted when the chart is removed and they can be reused for future deployments
- Credentials that are not explicitly set (passwords and the api key) and do not already exist as k8s secrets will be randomly generated, if they are set, the respective k8s secret will be updated or created if it doesn't exist
- **The license key value is mandatory**, if it's left unset or if it's invalid, the MD ICAP Server instance will report as "unhealthy" and it will be restarted
- The configured license should have a sufficient number of activations for all pod running MD ICAP Server, each pod counts as 1 activation. Terminating pods will also deactivate the respective MD ICAP Server instance.

## Configuration

The following table lists the configurable parameters of the Metadefender ICAP chart and their default values.

| Parameter                | Description             | Default        |
| ------------------------ | ----------------------- | -------------- |
| `ACCEPT_EULA` | Set the ACCEPT_EULA variable to any value to confirm your acceptance of the End-User Licensing Agreement. | `"false"` |
| `mdicapsrv_user` | Initial admin user for the MD ICAP Server web interface | `"admin"` |
| `mdicapsrv_password` | Initial admin password for the MD ICAP Server web interface, if not set it will be randomly generated | `null` |
| `activation_server` | URL to the OPSWAT activation server, this value should not be changed | `"activation.dl.opswat.com"` |
| `mdicapsrv_api_key` | 36 character API key used for the MD ICAP Server REST API, if not set it will be randomly generated | `null` |
| `mdicapsrv_license_key` | A valid license key, **this value is mandatory** | `"<SET_LICENSE_KEY_HERE>"` |
| `db_user` | PostgreSQL database username  | `"postgres"` |
| `db_password` | PostgreSQL database password, if not set it will be randomly generated | `"postgres"` |
| `olms.enabled` | Enable active license with the On-Prem License Manager Server | `"false"` |
| `olms.olms_host_url` | URL to On-Prem License Manager Server | `"olms.<name-space>"` |
| `olms.olms_rest_port` | Default REST port for the On-Prem License Manager Server | `"8040"` |
| `olms.olms_socket_port` | Default Socket port for the On-Prem License Manager Server | `"3316"` |
| `olms.olms_rule` | Default rule for active license on the On-Prem License Manager Server | `"Default_Rule"` |
| `olms.olms_comment` | Set the comment for the On-Prem License Manager Server | `""` |
| `icap_ingress.host` | Hostname for the publicly accessible ingress, the `<APP_NAME>` string will be replaced with the `app_name` value | `"<APP_NAME>-mdicapsrv.k8s"` |
| `icap_ingress.service` | Service name where the ingress should route to, this should be left unchanged | `"md-icapsrv"` |
| `icap_ingress.rest_port` | Port where the ingress should route to | `8048` |
| `icap_ingress.enabled` | Enable or disable the ingress creation | `false` |
| `icap_ingress.class` | Sets the ingress class | `"nginx"` |
| `postgres_mdicapsrv.enabled` | Set to false to not create postgresql server  | `true` |
| `postgres_mdicapsrv.name` | Name of the Postgres instance | `"postgres-mdicapsrv"` |
| `postgres_mdicapsrv.image` | Default image repository for postgres instance | `"postgres:12.12"` |
| `postgres_mdicapsrv.env.name` | List of envs <ul><li>`POSTGRES_PASSWORD: ` This environment variable is required for you to use the PostgreSQL image. It must not be empty or undefined. This environment variable sets the superuser password for PostgreSQL</li><li>`POSTGRES_USER: ` This variable will create the specified user with superuser power and a database with the same name. If it is not specified, then the default user of postgres will be used</li></ul>  | `"postgres"` |
| `icap_docker_repo` | Name of MD ICAP Server image repository | `"opswat"` |
| `storage_configs.enabled` | Enable or disable for storage data Postgresql | `"false"` |
| `storage_configs.accessModes` | Set permission for access to the resource storage | `"ReadWriteMany"` |
| `storage_configs.resources.resources.storage` | Set the size of the storage PVC | `"5Gi"` |
| `storage_configs.storageClassName` | The name of the Storage class of the Kubernetes cluster | `"nfs-client"` |
| `healthcheck.enabled` | The config allow expose API health check for feature health check on Kubernetes | `"true"` |
| `cleanup_db.enabled` | Enable create cron job for clean up database of the instance is inactive | `"false"` |
| `cleanup_db.schedule` | Field to include a timezone; for example: CRON_TZ=UTC * * * * * or TZ=UTC * * * * *. | `"0 */12 * * *"` |
| `cleanup_db.successfulJobsHistoryLimit` | The field specify how many completed jobs should be kept | `"1"` |
| `cleanup_db.failedJobsHistoryLimit` | The field specify how many failed jobs should be kept  | `"1"` |
| `icap_components.md_icapsrv.initContainers.name` |  | `"check-db-ready"` |
| `icap_components.md_icapsrv.initContainers.image` |  | `"postgres:12.12"` |
| `icap_components.md_icapsrv.initContainers.envFrom.configMapRef.name` | The name of the config map reference with MD ICAP Server | `"mdicapsrv-env"` |
| `icap_components.md_icapsrv.initContainers.command` | The command line for check postgresql server ready for connection | `['sh', '-c', 'until pg_isready -h $DB_HOST -p $DB_PORT; do echo waiting for database; sleep 2; done;']` |
| `icap_components.md_icapsrv.name` | Name of MD ICAP Server image | `"md-icapsrv"` |
| `icap_components.md_icapsrv.image` | This value always get the image latest in the repository. Overrides the default docker image for the MD ICAP Server service, this value can be changed if you want to set a different version of MD ICAP Server (ex: opswat/metadefendericapsrv-debian:4.13.0). | `"opswat/metadefendericapsrv-debian"` |
| `icap_components.md_icapsrv.env` | The system environments for MD ICAP Server | `[{"name":"MD_USER","valueFrom":{"secretKeyRef":{"name":"mdicapsrv-cred","key":"user"}}},{"name":"MD_PWD","valueFrom":{"secretKeyRef":{"name":"mdicapsrv-cred","key":"password"}}},{"name":"APIKEY","valueFrom":{"secretKeyRef":{"name":"mdicapsrv-api-key","key":"value"}}},{"name":"LICENSE_KEY","valueFrom":{"secretKeyRef":{"name":"mdicapsrv-license-key","key":"value"}}},{"name":"POSTGRES_PASSWORD","valueFrom":{"secretKeyRef":{"name":"mdicapsrv-postgres-cred","key":"password"}}},{"name":"POSTGRES_USER","valueFrom":{"secretKeyRef":{"name":"mdicapsrv-postgres-cred","key":"user"}}}]` |
| `icap_components.md_icapsrv.data_retention.config_history` | Set the time of the data retention config history | `"168"` |
| `icap_components.md_icapsrv.data_retention.processing_history` | Set the time of the data retention processing history | `"168"` |
| `icap_components.md_icapsrv.import_configuration.enabled` | Enable import config from file. <br> **Notes:** The mdicapsrv-import-configuration ConfigMap will create if you put the import config file on the `files/<icap_components.md_icapsrv.import_configuration.importConfigMapSubPath>` when install chart.| `"false"` |
| `icap_components.md_icapsrv.import_configuration.targets` | List of import target <ul><li>`all` : Import all target</li><li>`schema` : Configuration for Security rules</li><li>`servers` : Configuration for Server profiles</li><li>`global` : Configuration for Global setting</li><li>`history` : Configuration for ICAP history</li><li>`auditlog` : Configuration for Config history</li><li>`session` : Configuration for Security -> Session</li><li>`password-policy` : Configuration for Password policy</li><li>`certs` : Configuration for Certificates. **Notes: Make sure the path in the config file is valid in the container**</li><li>`ssl` : Configuration for Security. It is used to enable/disable HTTPS/ICAPS</li><li>`user-management` : Configuration for User management</li><li>`email` : Configuration for Email Server</li><li>`nginxsupport` : Configuration for NGINX Communication</li></ul> **Note:** The `all`, `user-management` target will override HTTPS_CERT_PATH, ICAPS_CERT_PATH, MD_USER, MD_PWD, MD_EMAIL only use it if you know what are you doing. e.g: "[schema, servers]" | `"[schema, servers]"` |
| `icap_components.md_icapsrv.import_configuration.importConfigMap` | The name of the ConfigMap contains import config file <br> (This can export from [Import/Export configuration](https://docs.opswat.com/mdicap/operating/import-export-configuration)) | `"mdicapsrv-import-configuration"` |
| `icap_components.md_icapsrv.import_configuration.importConfigPath` |  | `"/opt/opswat"` |
| `icap_components.md_icapsrv.import_configuration.importConfigMapSubPath` | The key in the ConfigMap has the value containing the import config file | `"settings_export_package.zip"` |
| `icap_components.md_icapsrv.import_configuration.importConfigFilePass` | Password for unzip file import config file. **If you use the JSON file, you can let it empty** | `""` |
| `icap_components.md_icapsrv.nginx_support.enabled` | Enable config NGINX Communication | `"false"` |
| `icap_components.md_icapsrv.tls.https.enabled` | Enable HTTPS | `"false"` |
| `icap_components.md_icapsrv.tls.https.certSecret` | The name of the Secret contains certificate | `"mdicapsrv-https-tls-cert"` |
| `icap_components.md_icapsrv.tls.https.certSecretSubPath` | The key in the Secret has the value containing the certificate | `"mdicapsrv-https.crt"` |
| `icap_components.md_icapsrv.tls.https.certKeySecret` | The name of the Secret contains certificate private key | `"mdicapsrv-https-tls-cert-key"` |
| `icap_components.md_icapsrv.tls.https.certKeySecretSubPath` | The key in the Secret has the value containing the certificate private key | `"mdicapsrv-https.key"` |
| `icap_components.md_icapsrv.tls.https.mountPath` | MD ICAP Server container will mount HTTPS certificate to the path | `"/https_cert"` |
| `icap_components.md_icapsrv.tls.icaps.enabled` | Enable ICAPS | `"false"` |
| `icap_components.md_icapsrv.tls.icaps.certSecret` | The name of the Secret contains certificate | `"mdicapsrv-icaps-tls-cert"` |
| `icap_components.md_icapsrv.tls.icaps.certSecretSubPath` | The key in the Secret has the value containing the certificate | `"mdicapsrv-icaps.crt` |
| `icap_components.md_icapsrv.tls.icaps.certKeySecret` | The name of the Secret contains certificate private key | `"mdicapsrv-icaps-tls-cert-key"` |
| `icap_components.md_icapsrv.tls.icaps.certKeySecretSubPath` | The key in the Secret has the value containing the certificate private key | `"mdicapsrv-icaps.key"` |
| `icap_components.md_icapsrv.tls.icaps.mountPath` | MD ICAP Server container will mount ICAPS certificate to the path | `"/icaps_cert"` |
| `icap_components.md_icapsrv.tls.nginxs.enabled` | Enable NGINXS Communication | `"false"` |
| `icap_components.md_icapsrv.tls.nginxs.certSecret` | The name of the Secret contains certificate | `"mdicapsrv-nginxs-tls-cert"` |
| `icap_components.md_icapsrv.tls.nginxs.certSecretSubPath` | The key in the Secret has the value containing the certificate | `"mdicapsrv-nginxs.crt"` |
| `icap_components.md_icapsrv.tls.nginxs.certKeySecret` | The name of the Secret contains certificate private key | `"mdicapsrv-nginxs-tls-cert-key"` |
| `icap_components.md_icapsrv.tls.nginxs.certKeySecretSubPath` | The key in the Secret has the value containing the certificate private key | `"mdicapsrv-nginxs.key"` |
| `icap_components.md_icapsrv.tls.nginxs.mountPath` |MD ICAP Server container will mount NGINX Communication certificate to the path | `"/nginxs_cert"` |
| `icap_components.md_icapsrv.ports.rest` | Default REST port for the MD ICAP Server service | `"8048"` |
| `icap_components.md_icapsrv.trustCertificate.enabled` | Enable mount certificate to MD ICAP Server and trust it | `"true"` |
| `icap_components.md_icapsrv.trustCertificate.mountPath` | Set the path for mount certificate server to the container | `"/trust_certs"` |
| `icap_components.md_icapsrv.trustCertificate.configs.certSecret` | Set the name of the secret contains certificate | `"mdicapsrv-trust-server-cert"` |
| `icap_components.md_icapsrv.trustCertificate.configs.certSecretSubPath` | Set the key of the secret contains certificate | `"mdicapsrv-trust.crt"` |
| `icap_components.md_icapsrv.ports.icap` | Default ICAP port for the MD ICAP Server service | `"1344"` |
| `icap_components.md_icapsrv.ports.icaps` | Default ICAPS port for the MD ICAP Server service | `"11344"` |
| `icap_components.md_icapsrv.ports.nginx` | Default NGINX communication port | `"8043"` |
| `icap_components.md_icapsrv.ports.nginxs` | Default NGINX secured communication port | `"8443"` |
| `icap_components.md_icapsrv.database.db_mode` | Database mode | `"4"` |
| `icap_components.md_icapsrv.database.db_type` | Database type | `"remote"` |
| `icap_components.md_icapsrv.database.db_host` | Hostname / entrypoint of the database, this value should be changed any if using an external database service | `"postgres-mdicapsrv"` |
| `icap_components.md_icapsrv.database.db_port` | Port for the PostgreSQL Database | `"5432"` |
| `icap_components.md_icapsrv.service_type` | Sets the service type for MD ICAP Server service (ClusterIP, NodePort, LoadBalancer) | `"ClusterIP"` |
| `icap_components.md_icapsrv.extra_labels.aws-type` | If `aws-type` is set to `fargate`, the MD ICAP Server pod will be scheduled on an AWS Fargate virtual node (if a fargate profile is provisioned and configured) | `"fargate"` |
| `icap_components.md_icapsrv.resources.requests.memory` | Minimum reserved memory | `"2Gi"` |
| `icap_components.md_icapsrv.resources.requests.cpu` | Minimum reserved cpu | `"2.0"` |
| `icap_components.md_icapsrv.resources.limits.memory` | Maximum memory limit | `"4Gi"` |
| `icap_components.md_icapsrv.resources.limits.cpu` | Maximum cpu limit | `"4.0"` |
| `icap_components.md_icapsrv.imagePullPolicy` | The imagePullPolicy for a container and the tag of the image affect when the kubelet attempts to pull (download) the specified image | `"IfNotPresent"` |
| `icap_components.md_icapsrv.livenessProbe.httpGet.path` | Health check endpoint | `"/readyz"` |
| `icap_components.md_icapsrv.livenessProbe.httpGet.port` | Health check port. It should be the same with icap_components.md_icapsrv.ports.rest_port | `8048` |
| `icap_components.md_icapsrv.livenessProbe.initialDelaySeconds` | The initialDelaySeconds field tells the kubelet that it should wait 30 seconds before performing the first probe | `30` |
| `icap_components.md_icapsrv.livenessProbe.periodSeconds` | The periodSeconds field specifies that the kubelet should perform a liveness probe every 10 seconds | `10` |
| `icap_components.md_icapsrv.livenessProbe.timeoutSeconds` | Number of seconds after which the probe times out. Defaults to 10 second. Minimum value is 1. | `10` |
| `icap_components.md_icapsrv.livenessProbe.failureThreshold` | The trick is to set up a startup probe with the same command, HTTP or TCP check, with a failureThreshold * periodSeconds long enough to cover the worse case startup time | `3` |
| `icap_components.md_icapsrv.strategy.type` | Rolling updates allow Deployments' update to take place with zero downtime by incrementally updating Pods instances with new ones | `"RollingUpdate"` |
| `icap_components.md_icapsrv.strategy.rollingUpdate.maxSurge` | The field is an optional field that specifies the maximum number of Pods that can be created over the desired number of Pods | `0` |
| `icap_components.md_icapsrv.sidecars` | Configuration for the activation-manager sidecar | `[{"name": "activation-manager", "image": "alpine", "envFrom": [{"configMapRef": {"name": "mdicapsrv-env"}}], "env": [{"name": "APIKEY", "valueFrom": {"secretKeyRef": {"name": "mdicapsrv-api-key", "key": "value"}}}, {"name": "LICENSE_KEY", "valueFrom": {"secretKeyRef": {"name": "mdicapsrv-license-key", "key": "value"}}}], "command": ["/bin/sh", "-c"], "args": ["apk add curl jq\nstop() {\n  echo 'Deactivating using the MD ICAP Server API'\n  curl -H \"apikey: $APIKEY\" -X POST \"https://localhost:$REST_PORT/admin/license/deactivation\"\n  echo 'Deactivating using activation server API'\n  curl -X GET \"https://$ACTIVATION_SERVER/deactivation?key=$LICENSE_KEY&deployment=$DEPLOYMENT\"\n  exit 0\n}\ntrap stop SIGTERM SIGINT SIGQUIT\n\nuntil [ -n $DEPLOYMENT ] && [ $DEPLOYMENT != null ]; do\n    echo 'Checking...'\n    export DEPLOYMENT=$(curl --silent -H \"apikey: $APIKEY\" \"http://localhost:$REST_PORT/admin/license\" | jq -r \".deployment\")\n    echo \"Deployment ID: $DEPLOYMENT\"\n    sleep 1\ndone\necho \"Waiting for termination signal...\"\nwhile true; do sleep 1; done\necho \"MD ICAP Server pod finished, exiting\"\nexit 0\n"]}]` |
| `nodeSelector` | `nodeSelector` is the simplest recommended form of node selection constraint | `{}` |
| `autoscaling.enabled` | Enable feature HPA (Horizontal Pod Autoscaler) for MD ICAP Server | `false` |
| `autoscaling.minReplicas` | This field indicates the number minimum of the pods | `1` |
| `autoscaling.maxReplicas` | This field indicates the number maximum of the pods | `10` |
| `autoscaling.metrics` |  | `[{"type":"Resource","resource":{"name":"cpu","target":{"type":"Utilization","averageUtilization":60}}},{"type":"Resource","resource":{"name":"memory","target":{"type":"Utilization","averageUtilization":60}}}]` |
| `autoscaling.behavior` |  | `{"scaleDown":{"stabilizationWindowSeconds":300,"policies":[{"type":"Percent","value":100,"periodSeconds":15}],"selectPolicy":"Max"},"scaleUp":{"stabilizationWindowSeconds":60,"policies":[{"type":"Percent","value":100,"periodSeconds":15},{"type":"Pods","value":4,"periodSeconds":15}],"selectPolicy":"Max"}}` |

## Notice
- Set "import_configuration" to false if you do not have file "mdicapsrv-config.json" in "/opt/opswat/mdicapsrv-config.json". By this option, after finish installation you must config MD ICAP Server manually or import an existing configuration by import/export feature.
- To have a file "mdicapsrv-config.json" correctly, please install a MD ICAP Server, do configuration setting then use export feature to get the json config file.
- Please specific value of the secret template file for enable HTTPS, ICAPS or NGINXs. Need to mapping the key of the secret HTTPS, ICAPS and NGINXS with `*.certSecretSubPath` and `*.certKeySecretSubPath`
## Release note
### v5.4.0
- Support Transfer-Encoding for HTTP parser
- Enhance ICAP collect support package
- Support includes ICAP's version to execute files
- Support multiple Blocked page
- Update NGINX header one time when response data from Lua
- Fix some issues
### v5.3.0
- Support SOAP/JSON message with Base64 embedded data
- UI accessibility
- Security enhancements: <ul><li>NGINX 22.1</li><li>Curl 8.4.0</li><li>Angular CLI 14.0</li></ul>
- Other updates: <ul><li>"Permissive passive" mode under the Global settings section is now enabled by default.</li><li>New scan verdict filtration for SBOM related result.</li></ul>
### v5.2.1
- Integration with My OPSWAT portal.
### v5.2.0
- Feature upload certificates
- Remove import targets: certs, ssl
- Added annotation for ingress when enable auto scaling with HPA
- Support active license with On-Prem License Manager Server added config for On-Prem License Manager Server via: `olms_server` `olms_rest_port` `olms_socket_port` `olms_sockets_port` `olms_rule`
- Support Postgres Server added config for database server via: `db_mode` `db_type` `db_host` `db_port`
- Added configurations for trust certificate server from the secrets via: `trustCertificate.certSecret` `trustCertificate.certSecretSubPath`
- Support HPA on Kubernetes via: `autoscaling` (Notice: Require installed metrics server before enable HPA https://github.com/kubernetes-sigs/metrics-server)
### v5.1.1
- Support TLS version. (icap_components.md_icapsrv.tls.https.tlsVersions, icap_components.md_icapsrv.tls.icaps.tlsVersions, icap_components.md_icapsrv.tls.nginxs.tlsVersions)
- Enforce End-User Licensing Agreement. (ACCEPT_EULA)
- Remove some unused configurations relate to AWS environment
- Change `MDICAPSRV_IMPORT_CONF_FILE` to `icap_components.md_icapsrv.import_configuration.importConfigPath`
- Change `MDICAPSRV_AUDIT_DATA_RETENTION` to  `icap_components.md_icapsrv.data_retention.config_history`
- Change `MDICAPSRV_HISTORY_DATA_RETENTION` to `icap_components.md_icapsrv.data_retention.processing_history`
- Change `MDICAPSRV_CERT_PATH` to `icap_components.md_icapsrv.tls.https.mountPath` and `icap_components.md_icapsrv.tls.icaps.mountPath`
- Change `MDICAPSRV_NGINX_CERT_PATH` to `icap_components.md_icapsrv.tls.nginxs.mountPath`
- Change `icap_components.md_icapsrv.nginx_support.tls.nginxsCertSecret` to `icap_components.md_icapsrv.tls.nginxs.certSecret`
- Change `icap_components.md_icapsrv.nginx_support.tls.certSecretSubPath` to `icap_components.md_icapsrv.tls.nginxs.certSecretSubPath`
- Change `icap_components.md_icapsrv.nginx_support.tls.certKeySecret` to `icap_components.md_icapsrv.tls.nginxs.certKeySecret`
- Change `icap_components.md_icapsrv.nginx_support.tls.certKeySecretSubPath` to `icap_components.md_icapsrv.tls.nginxs.certKeySecretSubPath`
- Change `.Values.MDICAPSRV_REST_PORT` to `.Values.icap_components.md_icapsrv.ports.rest` 
- Change `.Values.MDICAPSRV_ICAP_PORT` to `.Values.icap_components.md_icapsrv.ports.icap` 
- Change `.Values.MDICAPSRV_ICAPS_PORT` to `.Values.icap_components.md_icapsrv.ports.icaps` 
- Change `icap_components.md_icapsrv.nginx_support.port` to `.Values.icap_components.md_icapsrv.ports.nginx` 
- Change `icap_components.md_icapsrv.nginx_support.port_s` to `.Values.icap_components.md_icapsrv.ports.nginxs` 
- Change `.Values.app_name` to `.Release.Namespace`
### v5.1.0
- Support import config from encrypt file. (icap_components.md_icapsrv.import_configuration.importConfigFilePass)