
Metadefender for secure storage
===========

This is a Helm chart for deploying MetaDefender for Secure Storage (https://docs.opswat.com/mdss/installation/kubernetes-deployment) in a Kubernetes cluster

This chart can deploy the following depending on the provided values:
- All MDSS services in separate pods 
- A PostgreSQL database instance pre-configured to be used by MDSS

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
By default, the helm chart enables the following storage units: `azureblob,amazonsdk,nfs`. Set `ENABLED_MODULES` to the storage types you need; only `nfs` and `smb` deploy an additional pod. For example, to enable Azure, AWS and GCP:
```
ENABLED_MODULES: azureblob,azurefiles,amazonsdk,googlecloud
```
Currently supported modules:

`azureblob,amazonsdk,googlecloud,alibabacloud,azurefiles,smb,box,graph,sftp,nfs,mft,ftp,oraclesdk`

`smb` deploys the SMB sidecar (`smbservice`),it runs as root with `CAP_SYS_ADMIN` and an unconfined AppArmor profile, so the namespace must admit privileged pods and the nodes need the `cifs` kernel module. On SELinux-enforcing nodes (OpenShift, RHEL with CRI-O) it also needs the SELinux type `spc_t`, which `mdss-openshift.yml` sets. EKS Fargate and GKE Autopilot do not allow this, and on FIPS-enabled nodes the kernel cannot use NTLM. Where it is not possible, switch to the unprivileged SMB sidecar (the `mdss-noroot-rofs.yml` example does, and `mdss-openshift.yml` has it as a commented alternative):
```
mdss_components:
  smbservice:
    image: mdintegrations_smbservice
    securityContext: null
```

### Exposing MDSS on OpenShift
The chart can create the OpenShift Route for you. It is rendered from `templates/route-template.yml` and is only created when `mdss_route.enabled` is `true`. `mdss_route` is absent from the chart's default values, so the template is inert on non-OpenShift clusters and the Route API does not need to exist there. `mdss-openshift.yml` enables it:

```yaml
mdss_route:
  enabled: true
  name: mdss-route
  service: webclient
  port: 80
  host: ""                             # empty -> OpenShift generates the hostname
  annotations:
    haproxy.router.openshift.io/timeout: 60s
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

The Route points at `webclient`, which serves the web UI and forwards `/api` to `apigateway`, so one Route covers both. With `host` left empty, OpenShift generates `<route-name>-<namespace>.apps.<cluster-domain>`. Set `host` for a fixed hostname; the `<APP_NAMESPACE>` placeholder is replaced with the release namespace. TLS terminates at the router (`edge`) with the router's default certificate, and plain HTTP is redirected to HTTPS; add `certificate` and `key` under `tls` to serve your own. The timeout annotation raises the router's 30 s default to the 60 s that `webclient`'s nginx allows.

Check the assigned hostname after installation with:
```
oc get route mdss-route
```

## Upgrading
The helm upgrade command can be used to upgrade the mdss services using the latest helm chart:
```
helm upgrade my_mdss <path_to_chart>
```

### General recommendations

Before performing any upgrade, review the following best practices:

- **Back up the database**: Always take a full backup of your PostgreSQL database before upgrading. For in-cluster deployments this means snapshotting the persistent volume; for externally managed databases use the provider's native backup/snapshot mechanism. Keep the backup until the new version has been validated in production.
- **Read the release notes**: Check for any breaking changes or required configuration updates in the target release before upgrading.
- **Blue-green deployment**: For production environments where rollback safety is critical, consider a blue-green upgrade strategy:
  1. Clone your existing PostgreSQL database to a separate instance (e.g. a snapshot-restored replica or a managed DB clone).
  2. Deploy the new chart version into a separate namespace (e.g. `mdss-green`), pointing it at the cloned database:
     ```
     helm install my_mdss_green <path_to_new_chart> --namespace mdss-green \
       --set POSTGRESQL_URL="<connection_string_to_cloned_db>"
     ```
  3. Validate functionality of the new deployment against the cloned data without affecting production traffic.
  4. Switch ingress or DNS to the new namespace once satisfied.
  5. If issues arise, revert by routing traffic back to the original namespace — the original database remains untouched.
  6. Decommission the old deployment and cloned database after a suitable validation period.

### Database upgrades
**This step is not required when using an external, managed database**

The helm chart is configured by default to use the latest compatible version of PostgreSQL. Before upgrading an existing deployment with a persistent in-cluster database, make sure the database version matches the version required by the corresponding release:
 - MDSS (latest) - PostgreSQL 17

#### Upgrading from MongoDB (versions prior to v4.0.0)

Starting with MDSS v4.0.0, PostgreSQL replaces MongoDB as the primary database backend. If upgrading from an older MongoDB-based deployment, follow the official [Upgrade Guide to PostgreSQL](https://www.opswat.com/docs/mdss/configuration/upgrade-to-postgresql#upgrade-options) which covers three upgrade options:

- **Option 1 – Standard upgrade with migration**: Recommended for small to medium deployments where historical data is required. Data is migrated automatically; no extra configuration needed. Note that migration takes approximately 2–3 hours per 1 million files.
- **Option 2 – Skip data migration**: Recommended for large deployments or when historical data is not critical. The chart sets `SKIP_MONGO_TO_PG: "yes"` by default, so migration is skipped unless explicitly removed from the values. This provides immediate availability of the new version without waiting for data migration.
- **Option 3 – Blue-green deployment**: Recommended for production environments requiring zero downtime. Deploy v4.0.0 in parallel, test it, then cut over storage processing with easy rollback capability.

#### Schema migrations
Database schema migrations are handled automatically by the `pgmigrations` pod, which runs as an init step before any other MDSS containers start up. No manual migration steps are required — ensure the `pgmigrations` pod completes successfully before troubleshooting other service startup issues.

#### Upgrading with an externally managed database
When using an external (managed) database, the database itself holds all persistent state. In this case it is **strongly recommended to perform a clean reinstall** rather than a rolling upgrade, to avoid schema or configuration conflicts:
```
helm delete my_mdss
helm install my_mdss <path_to_chart>
```

The following components are non-persistent and can be updated to the latest compatible version by setting the respective image tag:
 - RabbitMQ: `rabbitmq:4.1.0-alpine`
 - Redis Cache: `redis:7.4.1-alpine`

## Operational Notes
The entire deployment can be customized by overwriting the chart's default configuration values. Here are a few point to look out for when changing these values:
- By default, a PostgreSQL 17 database is deployed alongside the MDSS deployment
- In a production environment it's recommended to use an external service for the database and set `deploy_with_mdss_db` to false in order to not deploy an in-cluster database
- When using an external database, prefer a clean reinstall (`helm delete` / `helm install`) over `helm upgrade`, since the database holds all persistent state and a clean install avoids potential schema or configuration conflicts
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


## Resiliency and cloud-native behavior

### Horizontal Pod Autoscaling

Two autoscaling modes are available and can be combined: CPU/memory based (built into Kubernetes, needs metrics-server) and queue based (needs [KEDA](https://keda.sh)). Both are disabled by default.

The databases, RabbitMQ, Redis and the migration pods are single instance by design and are never autoscaled (`hpa.enabled: false` is set on them in the chart). All other services can run several replicas of the same version.

#### CPU / memory based

```yaml
hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 3
  cpuTargetUtilization: 85
  memoryTargetUtilization: null   # optional, percent of the memory request
  behavior: {}                    # optional autoscaling/v2 scaleUp/scaleDown policies
```

The values apply to every service and can be overridden per component, e.g. `mdss_components.webclient.hpa.maxReplicas: 5`, or `mdss_components.apigateway.hpa.enabled: false` to keep a service at a fixed size. Utilization targets are relative to the container's resource requests, so keep `resources.requests` set (the chart defaults do).

#### Queue based (recommended for the processing services)

CPU is a poor signal for MDSS: discovery, scanning and remediations spend most of their time waiting on storages and MetaDefender Core, so a large backlog can build up while CPU stays low. The services exchange work through RabbitMQ queues, so the number of messages waiting in those queues is the direct measure of pending work.

With KEDA installed in the cluster (`helm install keda kedacore/keda -n keda --create-namespace`, or the *Custom Metrics Autoscaler* operator on OpenShift), enable it with:

```yaml
keda:
  enabled: true
  minReplicaCount: 1
  maxReplicaCount: 5
  queueLength: 100      # target ready messages per replica, evaluated per queue
  cooldownPeriod: 300
  behavior: {}          # optional autoscaling/v2 behavior for the HPA KEDA creates
```

The chart then creates a `ScaledObject` for every component that lists `keda.queues`, plus a `TriggerAuthentication` and a Secret holding the AMQP connection string (built from `RABBITMQ_HOST`/`RABBITMQ_PORT`/`RABBITMQ_DEFAULT_USER`/`RABBITMQ_DEFAULT_PASS`; set `keda.existingSecret` to use your own Secret with the full `amqp://` URI under the key `host`). KEDA talks AMQP on port 5672, so the RabbitMQ management plugin is not required. A component scaled by KEDA gets no CPU HPA, since KEDA manages the HPA for it.

Every work queue exists in three priorities (`_High`, `_Medium`, `_Low`); each one is a separate trigger and the service is scaled to whatever the busiest queue requires. The chart ships these defaults:

| Service | Queues (each `_High`, `_Medium`, `_Low`) |
|---|---|
| scanningservice | `scanning.object_ready_for_scan.v2_queue`, `object_ready_for_scan_queue`, `object_scan_instance_result_queue` |
| discoveryservice | `start_discovery_queue`, `request_object_download_queue`, `event_based_discovery_queue`, `folder_discovery_queue` |
| remediationsservice | `object_scanned_queue`, `object_not_scanned_queue` |

Each component can override any of the settings above, including the queue list:

```yaml
mdss_components:
  scanningservice:
    keda:
      maxReplicaCount: 10
      queueLength: 200
```

Notes:
- Scanning throughput is ultimately bound by the MetaDefender Core instances behind it. Scaling scanningservice beyond what Core can absorb only moves the backlog; scale Core as well (see the MD Core chart).
- The queue depth of a service can be watched directly with `kubectl exec deploy/rabbitmq -- rabbitmqctl list_queues name messages consumers`, which helps to choose `queueLength` for a given workload.
- Clusters that already run Prometheus can alternatively scrape RabbitMQ's built-in Prometheus endpoint (port 15692) and expose `rabbitmq_queue_messages_ready` to the HPA through prometheus-adapter; KEDA is the simpler setup.

### Deployment strategy

Every Deployment gets a rolling update strategy by default:

```yaml
deploymentStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```

A new pod is started and must be running before an old one is stopped, so restarts, configuration changes and scaling do not interrupt a service.

The databases, RabbitMQ, Redis and the migration pods override this with `maxSurge: 0` / `maxUnavailable: 1`: the old pod is stopped before its replacement is created, so two copies are never started side by side (without it, Kubernetes' default would start a second PostgreSQL on the same data directory while the first is still running). The replacement can be created while the old pod is still shutting down; PostgreSQL's data directory lock keeps a second instance from using the data until the first has exited. Any component can set its own `strategy`, e.g. `strategy: {type: Recreate}`, which also waits for the old pod to be fully gone. Set `Recreate` at install time: switching an existing Deployment from `RollingUpdate` to `Recreate` is rejected on upgrade by Helm 4 (server-side apply cannot remove the `rollingUpdate` defaults the API server filled in).

Running two different MDSS versions side by side is not supported. During an in-place `helm upgrade` to a new version each service rolls independently, so for version upgrades follow the recommendations in [Upgrading](#upgrading) (blue-green, or a clean reinstall with an external database), or at least upgrade with

```
helm upgrade my_mdss <path_to_chart> \
  --set deploymentStrategy.rollingUpdate.maxSurge=0 \
  --set deploymentStrategy.rollingUpdate.maxUnavailable=100%
```

so every service stops all of its old pods before starting new ones and never serves requests from two versions at once.

When an HPA or KEDA manages a component, the chart leaves `replicas` out of its Deployment, so a `helm upgrade` never resets or conflicts with the autoscaler's replica count.

### Statelessness

All MDSS services are stateless: configuration comes from the ConfigMaps and Secrets rendered by the chart, and all persistent state (configuration, scan results, license activation) lives in the PostgreSQL database. RabbitMQ and Redis only hold transient data. This is what allows the services to be scaled, rescheduled and replaced freely.

The only volume the chart creates is the in-cluster database's data directory. With an external database (`deploy_with_mdss_db: false`) nothing in the deployment needs persistent storage. `persistance_enabled: false` removes the volumes entirely, making the in-cluster database ephemeral as well (useful for tests; its data is lost when the pod is recreated). Services write their logs to the container filesystem (or only to stdout with `ROTATELOGS_ENABLED: "false"`), so collect logs from stdout in the cluster.

### Non-root user and read-only root filesystem

[mdss-noroot-rofs.yml](mdss-noroot-rofs.yml) runs every MDSS service as UID 1000 with a read-only root filesystem, no privilege escalation and the RuntimeDefault seccomp profile. The chart mounts emptyDir volumes at `/tmp` and `/var/tmp` for any component with `readOnlyRootFilesystem: true`.

The upstream PostgreSQL, RabbitMQ and Redis images are opted out with `securityContext: {}`. Note it has to be `{}` and not `null`: Helm drops keys set to `null`, and the component would silently inherit the global security context again. For a fully non-root deployment use an external database and non-root variants of RabbitMQ and Redis.

```
helm install my_mdss <path_to_chart> -f mdss-noroot-rofs.yml
```

### OpenShift

[mdss-openshift.yml](mdss-openshift.yml) deploys the chart on Red Hat OpenShift. First create, in the namespace you deploy into, the service account used by the components that cannot run under the default restricted SCC:

```
oc create sa mdss -n <namespace>
oc adm policy add-scc-to-user privileged -z mdss -n <namespace>
helm install my-mdss <path_to_chart> -n <namespace> -f mdss-openshift.yml
```

Most services run under the restricted SCC as an arbitrary UID; the example disables the two root-only startup steps for them (`EXPOSE_LOCALHOST_ENABLED: "false"`, `ROTATELOGS_ENABLED: "false"`, so logs go to stdout only). The API gateway, licensing service, webclient and Redis run as root and PostgreSQL as its own user (UID 999) through the `mdss` service account. It also points the webclient's nginx resolver at the OpenShift DNS service.

With the `smb` module, the SMB sidecar also runs on the `mdss` service account, as root with `CAP_SYS_ADMIN` and the SELinux type `spc_t`, so it can mount shares with the kernel's CIFS client; this is why the account needs the `privileged` SCC. For NetApp, add the address MDSS connects from to the SVM's Vscan scanner pool, otherwise ONTAP refuses access to the `ONTAP_ADMIN$` share. On FIPS-enabled clusters, or where `privileged` is not allowed, use the unprivileged SMB sidecar that `mdss-openshift.yml` shows commented out

### Licensing

The license is activated once per deployment, not per pod. The activation is stored in the MDSS database and shared by all replicas of all services, so:

| Scenario | License impact |
|---|---|
| Scaling a service out or in (manually, HPA or KEDA) | None: new replicas use the existing activation, removed replicas release nothing |
| Pod restart, rescheduling, node failure | None |
| Rolling update / `helm upgrade` on the same database | None: the activation survives in the database |
| Reinstall (`helm delete` / `helm install`) pointing at the same database | None: the activation is picked up from the database |
| New deployment with a new or empty database | The license must be activated again for that deployment |
| Decommissioning a deployment | Deactivate the license from MDSS before deleting the deployment and its database, so the activation is released |

Unlike MetaDefender Core, where every instance activates and deactivates its own license, no per-replica activation or deactivation automation is needed for MDSS.
