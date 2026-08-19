
Metadefender core
===========

This is a Helm chart for deploying MetaDefender Core (https://docs.opswat.com/mdcore/kubernetes-configuration) in a Kubernetes cluster

This chart can deploy the following depending on the provided values:
- One or more MD Core instances 
- A PostgreSQL database instance pre-configured to be used by MD Core

In addition to the chart, we also provide a number of values files for specific scenarios:
- `mdcore-aws-eks-values.yml` - for deploying in an AWS environment using Amazon EKS
- `mdcore-azure-aks-values.yml` - for deploying in an Azure environment using AKS
- `mdcore-azure-gcloud-*.yml` - for deploying in an GCP environment using GKE
- `mdcore-openshift.yml` - for deploying in an OpenShift environment

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

`mdcore-openshift.yml` is a **reference configuration** for deploying MD Core on Red Hat OpenShift under the platform's default security standards. It deploys MD Core and PostgreSQL as **non-root containers under the `restricted-v2` SCC**, declares their security context explicitly, and exposes MD Core through an OpenShift **Route** with TLS. The license key is the only value you have to supply.

`restricted-v2` is the SCC OpenShift applies to authenticated users' workloads by default. It denies all host access, requires a UID and SELinux context allocated to the namespace, requires all Linux capabilities to be dropped, and disallows privilege escalation. Three consequences affect this chart:

- The pod runs as an **arbitrary, per-namespace UID** which has **no entry in the container's user database** and **cannot write to the container's root directory**.
- **`hostPath` volumes are not permitted**, so the chart's default `storage_provisioner: hostPath` cannot be used.
- All **capabilities must be dropped** and privilege escalation disallowed.

#### **Security context**

The reference configuration declares the security posture on the pod, on both application containers, and on the init container, rather than letting the SCC mutate the pod silently at admission time. That makes the manifests reviewable, lets them be checked by a policy engine, and lets them run unchanged on a plain Kubernetes cluster whose namespaces use Pod Security Admission in `restricted` mode.

| Setting | Value | Purpose |
| ------- | ----- | ------- |
| `runAsNonRoot` | `true` | never run as UID 0 |
| `allowPrivilegeEscalation` | `false` | block setuid/setgid escalation |
| `capabilities.drop` | `[ALL]` | drop every Linux capability |
| `seccompProfile.type` | `RuntimeDefault` | apply the runtime's default seccomp filter |

`runAsUser`, `runAsGroup` and `fsGroup` are deliberately **not** set. OpenShift allocates a UID range and an SELinux context per namespace and injects them; hardcoding a UID would be rejected by the SCC. MD Core and PostgreSQL both run correctly under whatever UID the namespace assigns.

`readOnlyRootFilesystem` is **not** enabled: MD Core writes to several paths inside its install directory at runtime, so a read-only root filesystem would require mounting a writable volume over each of them.

#### **ConfigMap and Secret configuration**

The chart creates these itself; no manual step is required. Credentials are never placed in the pod spec — they are referenced from Secrets via `secretKeyRef`.

| Object | Kind | Contents |
| ------ | ---- | -------- |
| `mdcore-env` | ConfigMap | database host/port/mode, REST port, `STORAGE_PATH`, activation server |
| `<release>-config` | ConfigMap | the `env` values (health check, proxy, Splunk, licensing settings) |
| `mdcore-cred` | Secret | MD Core web interface user and password |
| `mdcore-postgres-cred` | Secret | PostgreSQL user and password |
| `mdcore-api-key` | Secret | MD Core REST API key |
| `mdcore-license-key` | Secret | MD Core license key |

Any credential left unset is generated randomly on first install. Secrets are intentionally **retained when the chart is uninstalled** so a reinstall reuses the same credentials — delete them explicitly, or delete the namespace, if you want them gone.

#### **Cluster requirements**
No image pull secret and no StorageClass are required for a default deployment — `mdcore-openshift.yml` deploys the upstream `postgres:18` image with an ephemeral database, which works on any OpenShift cluster. You only need a valid MD Core license key.

Optional, depending on how you deploy:
- **Database persistence**: an existing StorageClass, if you uncomment the `pvc` block in `mdcore-openshift.yml`. Check what is available with `oc get storageclass`. For production, prefer an external managed PostgreSQL service (`deploy_with_core_db: false`) over an in-cluster database.
- **A RedHat PostgreSQL image**: only if you specifically want RedHat-supported images instead of the upstream one. Those images live in `registry.redhat.io` and need a pull secret, and they expect `POSTGRESQL_*` environment variables rather than the `POSTGRES_*` ones the chart sets by default:
```
oc create secret docker-registry imagepullsecret --docker-server=registry.redhat.io --docker-username=<REDHAT_USER> --docker-password=<REDHAT_PASSWORD> --docker-email=<REDHAT_EMAIL>

oc secrets link <OPENSHIFT_USER> imagepullsecret --for=pull
```

#### **Helm chart**
To deploy the helm chart directly in a RedHat OpenShift cluster we have the `mdcore-openshift.yml` values file. It differs from the generic values in the following ways:
- **Security context**: declared explicitly on the pod and on every container, as described above.
- **Service exposure**: an OpenShift Route with edge TLS, instead of an Ingress. See the section below.
- **Database readiness check**: the init container is overridden to call `pg_isready` with an explicit `-U $DB_USER`. Without it, libpq derives the default database user from the current UID; that lookup fails for the arbitrary UID, so `pg_isready` exits 3 (`no attempt`) without ever connecting and the pod stays in `Init:0/1` indefinitely. Keep the image tag in that override in sync with `core_components.md-core.image` when upgrading.
- **Writable `STORAGE_PATH`**: an `emptyDir` is mounted at `/metadefendercore`. The MD Core entrypoint creates this directory at the container's root, which the arbitrary UID cannot write — without the mount the container exits with `Cannot create '/metadefendercore' directory.` and crash-loops. Replace the `emptyDir` with a PVC if sanitized / DLP-processed / quarantined files must be retained.
- **Storage**: no `hostPath` and no PVC by default. Neither component declares a `persistentDir`, so both use ephemeral container storage. **The in-cluster database does not survive a pod restart** — see the notes in the values file for the persistent and external-database options.
- **PostgreSQL image**: the chart default (`postgres:18`) is kept. It runs correctly under `restricted-v2` as long as its data directory is not a mounted volume.
- **Liveness probe**: `initialDelaySeconds` is raised to 600. On first boot MD Core downloads all engine definitions, which can exceed the default 90s and cause the pod to be killed mid-download.
- **Ingress**: disabled, since a Route is the usual way to expose a service on OpenShift (see below).

Example installation when using local helm files and setting the custom values manually:
```
helm install my_mdcore ./helm_charts/mdcore -f mdcore-openshift.yml \
 --set 'mdcore_license_key=<SET_LICENSE_KEY>'
```

#### **Exposing MD Core**

The chart can create the OpenShift Route for you, so no manual step in the console is needed. It is rendered from `templates/route-template.yml` and is only created when `core_route.enabled` is `true` — `core_route` is absent from the chart's default values, so the template is inert on non-OpenShift clusters and the Route API does not need to exist there. `mdcore-openshift.yml` enables it:

```yaml
core_route:
  enabled: true
  service: md-core
  port: 8008
  host: ""                             # empty -> OpenShift generates the hostname
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

With `host` left empty, OpenShift generates `<route-name>-<namespace>.apps.<cluster-domain>`, which keeps this file portable across clusters. Set `host` for a fixed hostname; the `<APP_NAMESPACE>` placeholder is replaced with the release namespace.

TLS terminates at the router (`edge`) and plain HTTP is redirected to HTTPS, so the REST API and web UI are not served unencrypted outside the cluster. The router's default certificate is used. To serve your own certificate, add `certificate` and `key` under `tls`. For encryption all the way to the pod, configure MD Core's own TLS (`core_components.md-core.tls`) and change `termination` to `reencrypt`.

Check the assigned hostname after installation with:
```
oc get route core-route
```

To expose MD Core some other way instead, set `core_route.enabled` to `false` and use a `LoadBalancer`/`NodePort` service (`core_components.md-core.service_type`) or the chart's Ingress (`core_ingress`).

Ingress creation is **disabled by default** (`core_ingress.enabled: false`). To expose MD Core via a Kubernetes Ingress, set `core_ingress.enabled` to `true` and configure `core_ingress.class` and `core_ingress.ingress_annotations` for your cluster's ingress controller (for example AWS ALB or GCE). Cloud-specific values files include ready-made examples.

## Operational Notes
The entire deployment can be customized by overwriting the chart's default configuration values. Here are a few point to look out for when changing these values:
- Sensitive values (like credentials and keys) are saved in the Kubernetes cluster as secrets and are not deleted when the chart is removed and they can be reused for future deployments
- Credentials that are not explicitly set (passwords and the api key) and do not already exist as k8s secrets will be randomly generated, if they are set, the respective k8s secret will be updated or created if it doesn't exist
- **The license key value is mandatory**, if it's left unset or if it's invalid, the MD Core instance will report as "unhealthy" and it will be restarted
- The configured license should have a sufficient number of activations for all pod running MD Core, each pod counts as 1 activation. Terminating pods will also deactivate the respective MD Core instance.
- By default, a PostgreSQL database is deployed alongside the MD Core deployment with the same credentials as set in the values file
- In a production environment it's recommended to use an external service for the database (like Amazon RDS) and set `deploy_with_core_db` to false in order to not deploy an in-cluster database
- The deployed MD Core pod has a startup container that will wait for a database connection before allowing MD Core to start

### Storage and stateless design

| Component | Persistent data | Default mount | Environment variable |
| --------- | ----------------- | ------------- | -------------------- |
| `md-core` | Sanitized, DLP-processed, and quarantined files | `STORAGE_PATH` (`/metadefendercore`) | `STORAGE_PATH` (from `mdcore-env` ConfigMap) |
| `postgres-core` | PostgreSQL database | `/var/lib/postgresql` (PGDATA is a version-scoped subdir) | N/A (use external DB in production) |

- **Default (`storage_provisioner: hostPath`)**: Each component with `persistentDir` gets a dedicated directory on the node under `hostPathPrefix/<component-name>`. Pods can be recreated; data survives on the same node.
- **PVC mode**: Set `storage_provisioner` to `custom` (or any value other than `hostPath`). Ensure each component's `storage_name` matches a PVC from the `pvc` list (for example `postgres-core` and `md-core-storage`).
- **Stateless MD Core** (no file-storage persistence): Set `core_components.md-core.persistentDir` to `null` and omit or clear `STORAGE_PATH` if the deployment does not use CDR/DLP/quarantine file retention.
- **External database only**: Set `deploy_with_core_db: false` and point `MDCORE_DB_HOST` at your managed PostgreSQL service.

See [MD Core Docker environment variables](https://www.opswat.com/docs/mdcore/container-deployment/docker-image-published-on-opswat-docker-hub) for `STORAGE_PATH` semantics.

## KEDA Autoscaling

The chart can deploy a KEDA `ScaledObject` for the `md-core` Deployment. KEDA autoscaling is **disabled by default**; enable it by setting `keda.enabled` to `true`.

KEDA polls the MD Core `/stat/nodes` API through the in-cluster `md-core` service and reads raw scan slot counts from the first entry in `statuses`. The default formula converts those raw values into used-slot percentage:

```text
((total_slots - available_slots) * 100) / total_slots
```

By default, `keda.targetValue` is `80`, which means scaling starts when used slots are at or above 80%, or when available slots drop below 20%.

To inspect the API response and confirm the JSON paths for your deployment, call `/stat/nodes` with the MD Core API key:

```console
APIKEY=$(kubectl get secret mdcore-api-key -n <namespace> -o jsonpath='{.data.value}' | base64 -d)

kubectl exec -n <namespace> deploy/md-core -- \
  curl -sS -H "apikey: ${APIKEY}" http://127.0.0.1:8008/stat/nodes
```

The default values expect a response shape like:

```json
{
  "statuses": [
    {
      "scan_queue_details": {
        "available_slots": 500,
        "total_scan_queue": 500
      }
    }
  ]
}
```

### Requirements

- **KEDA** must be installed in the cluster.
- The `/stat/nodes` response must expose the fields configured by `keda.availableSlotsValueLocation` and `keda.totalSlotsValueLocation`.
- Each additional `md-core` pod consumes **one license activation**. Ensure your license has enough activations for `keda.maxReplicas`.

When running multiple replicas behind an ingress, keep session affinity enabled (see `core_ingress.ingress_annotations`).

### Example

```console
helm upgrade --install my_mdcore ./helm_charts/mdcore \
  --set keda.enabled=true \
  --set keda.minReplicas=2 \
  --set keda.maxReplicas=5 \
  --set keda.targetValue=80 \
  --set mdcore_license_key=<SET_LICENSE_KEY>
```

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
| `STORAGE_PATH` | Container path for sanitized, DLP, and quarantined files; must match `core_components.md-core.persistentDir` when persistence is enabled | `"/metadefendercore"` |
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
| `core_ingress.class` | Ingress class name; required when ingress is enabled | `""` |
| `core_ingress.ingress_annotations` | Controller-specific ingress annotations | `null` |
| `keda.enabled` | Enable KEDA autoscaling for the `md-core` Deployment | `false` |
| `keda.deployment` | Deployment name targeted by the KEDA `ScaledObject` | `"md-core"` |
| `keda.minReplicas` | Minimum number of `md-core` pods when KEDA is enabled | `1` |
| `keda.maxReplicas` | Maximum number of `md-core` pods when KEDA is enabled | `3` |
| `keda.url` | MD Core API endpoint polled by KEDA; if null, the chart uses the namespace-qualified service DNS name | `null` |
| `keda.availableSlotsValueLocation` | JSON path for available scan slots in the `/stat/nodes` response | `"statuses.0.scan_queue_details.available_slots"` |
| `keda.totalSlotsValueLocation` | JSON path for total scan slots in the `/stat/nodes` response | `"statuses.0.scan_queue_details.total_scan_queue"` |
| `keda.formula` | KEDA formula that converts raw slot counts to used-slot percentage | See `values.yaml` |
| `keda.targetValue` | Used-slot percentage that triggers scaling | `"80"` |
| `core_docker_repo` |  | `"opswat"` |
| `core_components.postgres-core.name` |  | `"postgres-core"` |
| `core_components.postgres-core.image` |  | `"postgres"` |
| `core_components.postgres-core.env` |  | `[{"name": "POSTGRES_PASSWORD", "valueFrom": {"secretKeyRef": {"name": "mdcore-postgres-cred", "key": "password"}}}, {"name": "POSTGRES_USER", "valueFrom": {"secretKeyRef": {"name": "mdcore-postgres-cred", "key": "user"}}}]` |
| `core_components.postgres-core.ports` |  | `[{"port": 5432}]` |
| `core_components.postgres-core.is_db` |  | `true` |
| `core_components.postgres-core.persistentDir` | Volume mount at postgres home dir; PGDATA (version-scoped subdir) lives under it | `"/var/lib/postgresql"` |
| `core_components.postgres-core.storage_name` | PVC name when not using hostPath | `"postgres-core"` |
| `core_components.md-core.persistentDir` | Mount path for MD Core file storage; set to `null` for stateless | `"/metadefendercore"` |
| `core_components.md-core.storage_name` | PVC name when not using hostPath | `"md-core-storage"` |
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

