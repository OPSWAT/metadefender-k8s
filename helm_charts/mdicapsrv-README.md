
Metadefender ICAP Server
===========

This is a Helm chart for deploying MetaDefender ICAP (https://www.opswat.com/products/metadefender/icap) in a Kubernetes cluster

This chart can deploy the following depending on the provided values:
- One or more MD ICAP Server instances 

## Installation

### From source
MD ICAP Server can be installed directly from the source code, here's an example using the generic values:
```console
git clone https://github.com/OPSWAT/metadefender-k8s.git metadefender
cd metadefender/helm_charts
helm install my-mdicap ./icap
```

### From the latest release
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
| `mdicapsrv_api_key` | 36 character API key used for the MD ICAP Server REST API, if not set it will be randomly generated | `null` |
| `mdicapsrv_license_key` | A valid license key, **this value is mandatory** | `"<SET_LICENSE_KEY_HERE>"` |
| `activation_server` | URL to the OPSWAT activation server, this value should not be changed | `"activation.dl.opswat.com"` |
| `persistance_enabled` | Set to false to not create any volumes or host paths in the deployment, all storage will be ephemeral | `true` |
| `storage_provisioner` | Available storage providers | `"hostPath"` |
| `storage_name` | Available storage providers | `"hostPath"` |
| `storage_node` | Available storage providers | `"minikube"` |
| `hostPathPrefix` | This is the absolute path on the node where to keep the data filesystem for persistance | `"mdicapsrv-storage"` |
| `icap_ingress.host` | Hostname for the publicly accessible ingress, the `<APP_NAME>` string will be replaced with the `app_name` value | `"<APP_NAME>-mdicapsrv.k8s"` |
| `icap_ingress.service` | Service name where the ingress should route to, this should be left unchanged | `"md-icapsrv"` |
| `icap_ingress.rest_port` | Port where the ingress should route to | `8048` |
| `icap_ingress.enabled` | Enable or disable the ingress creation | `false` |
| `icap_ingress.class` | Sets the ingress class | `"nginx"` |
| `icap_docker_repo` | Name of MD ICAP Server image repository | `"opswat"` |
| `icap_components.md_icapsrv.name` | Name of MD ICAP Server image | `"md-icapsrv"` |
| `icap_components.md_icapsrv.image` | This value always get the image latest in the repository. Overrides the default docker image for the MD ICAP Server service, this value can be changed if you want to set a different version of MD ICAP Server (ex: opswat/metadefendericapsrv-debian:4.13.0). | `"opswat/metadefendericapsrv-debian"` |
| `icap_components.md_icapsrv.env` | The system environments for MD ICAP Server | `[{"name":"MD_USER","valueFrom":{"secretKeyRef":{"name":"mdicapsrv-cred","key":"user"}}},{"name":"MD_PWD","valueFrom":{"secretKeyRef":{"name":"mdicapsrv-cred","key":"password"}}},{"name":"APIKEY","valueFrom":{"secretKeyRef":{"name":"mdicapsrv-api-key","key":"value"}}},{"name":"LICENSE_KEY","valueFrom":{"secretKeyRef":{"name":"mdicapsrv-license-key","key":"value"}}}]` |
| `icap_components.md_icapsrv.import_configuration.enabled` | Enable import config from file. <br> **Notes:** The mdicapsrv-import-configuration ConfigMap will create if you put the import config file on the `files/<icap_components.md_icapsrv.import_configuration.importConfigMapSubPath>` when install chart.| `"false"` |
| `icap_components.md_icapsrv.import_configuration.targets` | List of import target <ul><li>`all` : Import all target</li><li>`schema` : Configuration for Security rules</li><li>`servers` : Configuration for Server profiles</li><li>`global` : Configuration for Global setting</li><li>`history` : Configuration for ICAP history</li><li>`auditlog` : Configuration for Config history</li><li>`session` : Configuration for Security -> Session</li><li>`password-policy` : Configuration for Password policy</li><li>`certs` : Configuration for Certificates. **Notes: Make sure the path in the config file is valid in the container**</li><li>`ssl` : Configuration for Security. It is used to enable/disable HTTPS/ICAPS</li><li>`user-management` : Configuration for User management</li><li>`email` : Configuration for Email Server</li><li>`nginxsupport` : Configuration for NGINX Communication</li></ul> **Note:** The `all`, `certs`, `ssl`, `user-management` target will override HTTPS_CERT_PATH, ICAPS_CERT_PATH, MD_USER, MD_PWD, MD_EMAIL only use it if you know what are you doing. e.g: "[schema, servers]" | `"[schema, servers]"` |
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
| `icap_components.md_icapsrv.ports.icap` | Default ICAP port for the MD ICAP Server service | `"1344"` |
| `icap_components.md_icapsrv.ports.icaps` | Default ICAPS port for the MD ICAP Server service | `"11344"` |
| `icap_components.md_icapsrv.ports.nginx` | Default NGINX communication port | `"8043"` |
| `icap_components.md_icapsrv.ports.nginxs` | Default NGINX secured communication port | `"8443"` |
| `icap_components.md_icapsrv.service_type` | Sets the service type for MD ICAP Server service (ClusterIP, NodePort, LoadBalancer) | `"ClusterIP"` |
| `icap_components.md_icapsrv.extra_labels.aws-type` | If `aws-type` is set to `fargate`, the MD ICAP Server pod will be scheduled on an AWS Fargate virtual node (if a fargate profile is provisioned and configured) | `"fargate"` |
| `icap_components.md_icapsrv.resources.requests.memory` | Minimum reserved memory | `"4Gi"` |
| `icap_components.md_icapsrv.resources.requests.cpu` | Minimum reserved cpu | `"1.0"` |
| `icap_components.md_icapsrv.resources.limits.memory` | Maximum memory limit | `"8Gi"` |
| `icap_components.md_icapsrv.resources.limits.cpu` | Maximum cpu limit | `"1.0"` |
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

## Notice
- Set "import_configuration" to false if you do not have file "mdicapsrv-config.json" in "/opt/opswat/mdicapsrv-config.json". By this option, after finish installation you must config MD ICAP Server manually or import an existing configuration by import/export feature.
- To have a file "mdicapsrv-config.json" correctly, please install a MD ICAP Server, do configuration setting then use export feature to get the json config file.
- Please specific value of the secret template file for enable HTTPS, ICAPS or NGINXs. Need to mapping the key of the secret HTTPS, ICAPS and NGINXS with `*.certSecretSubPath` and `*.certKeySecretSubPath`
## Release note
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