
MetaDefender Cluster
=====================

This is a set of two Helm charts for deploying [MetaDefender Cluster](https://www.opswat.com/docs/mdcluster) to a Kubernetes cluster:

| Chart | Path | Deploys |
|---|---|---|
| `md-cluster-services` | `md-cluster-services` | The control plane: Control Center, Identity Service, File Storage, plus the `mdcluster-config` ConfigMap / `mdcluster-secrets` Secret, and (by default) an in-cluster PostgreSQL, Redis and RabbitMQ |
| `md-cluster-instances` | `md-cluster-instances` | The worker fleet: one StatefulSet per entry under `workers` (`ometascan`, `api-gateway`, `callback-service` by default) |

`md-cluster-instances` is **not standalone**. Its workers mount the `mdcluster-config` ConfigMap and `mdcluster-secrets` Secret created by `md-cluster-services`, so **`md-cluster-services` must be installed first, into the same namespace**, and be ready before `md-cluster-instances` is installed. The two charts have no Helm `dependencies:` wiring between them — the ordering is enforced only by convention (and by `--wait` in the commands below); installing the workers first will crash-loop them.

There is no Ingress or HorizontalPodAutoscaler template in either chart — exposure and scaling are manual, described below.

## Prerequisites

- A Kubernetes cluster and `kubectl`/`helm` (Helm 3) configured against it
- A MetaDefender Cluster license key (`secrets.LICENSE_KEY`) — contact sales-inquiry@opswat.com if you don't have one
- Access to the container images referenced by `DOCKER_REPO`/`MDCLS_VERSION` (default `opswat/metadefendercluster-debian:<component>-2.8.0`); set `imagePullSecrets` in both charts if the registry is private
- If you disable the bundled PostgreSQL/Redis/RabbitMQ (recommended for production, see below), reachable endpoints for your own instances

## Installation

### 1. Get the charts

From source:
```console
git clone https://github.com/OPSWAT/metadefender-k8s.git metadefender
cd metadefender/helm_charts/mdcluster
```

Or from the published Helm repo:
```console
helm repo add mdk8s https://opswat.github.io/metadefender-k8s/
helm repo update mdk8s
```
(replace the local chart paths below with `mdk8s/md-cluster-services` / `mdk8s/md-cluster-instances`)

### 2. Fill in an override values file

Rather than passing every secret on the command line, copy the provided template and fill it in:

```console
cp override-values.yaml.example override-values.yaml
```

`override-values.yaml.example` covers the settings most deployments need to touch: the image repo/tag (`DOCKER_REPO`, `MDCLS_VERSION`, `imagePullPolicy`, `imagePullSecrets`), the credentials with no working default (`CONTROL_CENTER_ENCRYPTION_KEY` — must be exactly 32 characters — and `ADMIN_APIKEY`), the three shared `*_CONNECTION_KEY`s, the bootstrap admin account (`ADMIN_USER`/`ADMIN_PASSWORD`/`ADMIN_EMAIL`), the optional `LICENSE_KEY`, and persistence for PostgreSQL and File Storage (enabled at `100Gi` each, since the defaults in `values.yaml` are ephemeral `emptyDir`). Keep `override-values.yaml` out of version control — it holds real credentials.

> **Note:** this template leaves `CONTROL_CENTER_DB_PASSWORD`/`IDENTITY_DB_PASSWORD`/`DATALAKE_PASSWORD`/`WAREHOUSE_PASSWORD` and the RabbitMQ credentials at their dev defaults (`postgres`/`postgres`, `admin`/`admin`). That's fine for a quick trial, but rotate them too before running anything real — especially once `postgres.persistence.enabled: true` means that data actually sticks around. See the `secrets` table below for the full list and the [all four DB passwords must match](#interesting--production-configuration) rule.

### 3. Install `md-cluster-services` and wait for it to be ready

The in-chart PostgreSQL bootstraps a single superuser from `CONTROL_CENTER_DB_USER`/`CONTROL_CENTER_DB_PASSWORD`, and `IDENTITY_DB_PASSWORD`, `DATALAKE_PASSWORD` and `WAREHOUSE_PASSWORD` are really that same user — if you do rotate them, all four password values must be identical.

```console
kubectl create namespace mdcluster
helm install md-cluster-services ./md-cluster-services \
  --namespace mdcluster --wait --timeout 20m \
  -f override-values.yaml
```

`--wait` blocks until Control Center, Identity Service, File Storage and the enabled infrastructure pods pass their readiness probes — this is what makes the install order real, since `md-cluster-instances` needs the `mdcluster-config`/`mdcluster-secrets` objects this release creates.

### 4. Install `md-cluster-instances`

This release reads its configuration from the `md-cluster-services` release above, so it takes no secrets of its own — pass the same `override-values.yaml` again only if you changed the `workers` block (e.g. replica counts):

```console
helm install md-cluster-instances ./md-cluster-instances \
  --namespace mdcluster --wait --timeout 20m \
  -f override-values.yaml
```

### 5. Verify

```console
kubectl -n mdcluster get all
```
You should see `control-center`, `identity-service`, `file-storage-0` (StatefulSet), the infra pods you left enabled, and one pod per worker (`ometascan-0`, `api-gateway-0`, `callback-service-0` by default). Allow a couple of minutes after `--wait` returns for the workers to finish registering with Control Center over RabbitMQ before scanning traffic.

### Accessing Control Center

Control Center is published through a `NodePort` Service by default (container port `8892`). For quick access:
```console
kubectl -n mdcluster get svc control-center
```
For anything beyond a smoke test, put it behind your own Ingress/LoadBalancer — see [Exposing Control Center](#exposing-control-center) below.

## Configuration reference

### `md-cluster-services` — top level

| Key | Default | Notes |
|---|---|---|
| `DOCKER_REPO` | `opswat/metadefendercluster-debian` | Image repo prefix; images are tagged `<repo>:<component>-<version>` |
| `MDCLS_VERSION` | `2.8.0` | Default image tag for every component |
| `imagePullPolicy` | `IfNotPresent` | Overridable per component |
| `imagePullSecrets` | *(commented out)* | Set for private registries |

### `md-cluster-services` — components

| Component | Key(s) | Default | Notes |
|---|---|---|---|
| Control Center | `control-center.service.type` | `NodePort` | Singleton (Deployment, `replicas` fixed at 1) |
| | `control-center.service.nodePort` | *(unset)* | Only used when `service.type: NodePort` |
| Identity Service | *(scheduling/resources only)* | — | Singleton, ClusterIP |
| File Storage | `file-storage.replicas` | `1` | StatefulSet; Control Center is told about every replica via a computed `FILE_STORAGE_SERVICES` env var |
| | `file-storage.persistence.enabled` | `false` | `false` → `emptyDir` (ephemeral, like docker-compose) |
| | `file-storage.persistence.size` | `100Gi` | Used only when persistence is enabled |
| PostgreSQL | `postgres.enabled` | `true` | Set `false` to use an external database |
| | `postgres.image` | `postgres:16` | |
| | `postgres.persistence.enabled` | `false` | PVC carries `helm.sh/resource-policy: keep` when enabled, so it survives `helm uninstall` |
| Redis | `redis.enabled` | `true` | Set `false` to use an external cache |
| | `redis.image` | `redis:8` | |
| RabbitMQ | `rabbitmq.enabled` | `true` | Set `false` to use an external broker |
| | `rabbitmq.image` | `rabbitmq:4.2.5-management` | AMQP port `5672`, management UI `15672` |

Every component also accepts, as optional per-component knobs: `version` (image tag override), `resources`, `nodeSelector`/`affinity`/`tolerations`, `probes` (timeout/failure-threshold overrides), and `terminationGracePeriodSeconds`. The Deployment/StatefulSet shape itself is fixed in the templates and not configurable.

### `md-cluster-services` — `secrets` (all dev defaults — override before exposing)

| Key | Dev default | Purpose |
|---|---|---|
| `CONTROL_CENTER_DB_USER` / `_PASSWORD` | `postgres` / `postgres` | Also bootstraps the in-chart Postgres superuser |
| `IDENTITY_DB_USER` / `_PASSWORD` | `postgres` / `postgres` | Must match `CONTROL_CENTER_DB_PASSWORD` |
| `DATALAKE_USER` / `_PASSWORD` | `postgres` / `postgres` | Must match `CONTROL_CENTER_DB_PASSWORD` |
| `WAREHOUSE_USER` / `_PASSWORD` | `postgres` / `postgres` | Must match `CONTROL_CENTER_DB_PASSWORD` |
| `RABBITMQ_USER` / `_PASSWORD` | `admin` / `admin` | |
| `REDIS_USER` / `_PASSWORD` | *(commented out)* | Optional, only if your Redis requires auth |
| `IDENTITY_CONNECTION_KEY` | `1234abcd` | Shared with `FILE_STORAGE_CONNECTION_KEY`/`WORKER_CONNECTION_KEY` is fine |
| `FILE_STORAGE_CONNECTION_KEY` | `1234abcd` | |
| `WORKER_CONNECTION_KEY` | `1234abcd` | |
| `CONTROL_CENTER_ENCRYPTION_KEY` | `''` | **Must be exactly 32 characters** |
| `ADMIN_USER` / `ADMIN_EMAIL` | `admin` / `admin@admin` | Bootstrap admin account identity |
| `ADMIN_PASSWORD` | `admin` | Bootstrap admin account password |
| `ADMIN_APIKEY` | `''` | **Required in practice**, despite the empty default — Identity Service bootstraps the admin account with it, and Control Center, File Storage and the workers all authenticate their registration calls with the same value. Must be 36 hex chars, ≥10 digits, ≥10 letters, no run of 4+ of either class |
| `LICENSE_KEY` | `''` | Required for a usable deployment |

### `md-cluster-services` — `env` (renders the shared `mdcluster-config` ConfigMap)

Holds hosts/ports for every component (`CONTROL_CENTER_PORT`, `IDENTITY_HOST`/`PORT`, `FILE_STORAGE_LISTEN_PORT`, `*_SERVICES` broker/DB endpoints, etc.) plus:

| Key | Default | Notes |
|---|---|---|
| `FILE_STORAGE_MIN_REPLICA` / `FILE_STORAGE_MAX_REPLICA` | `1` / `1` | Reported to Control Center after startup; keep in step with `file-storage.replicas` |
| `GLOBAL_WAIT_TIMEOUT` | `150` (seconds) | How long each service polls for its dependencies at startup |

To point at external infrastructure, disable the corresponding component (`postgres.enabled: false`, etc.) and change the matching `env` entries (`CONTROL_CENTER_DB_HOST`, `IDENTITY_DB_HOST`, `DATALAKE_SERVICES`, `WAREHOUSE_SERVICES`, `REDIS_SERVICES`, `RABBITMQ_SERVICES`) to the external endpoints.

### `md-cluster-instances`

| Key | Default | Notes |
|---|---|---|
| `upgradeInstances` | `false` | Global opt-in for the per-worker pre-upgrade Job (see below); only takes effect on `helm upgrade` |
| `workers` | `ometascan` (port `8008`), `api-gateway` (port `8899`), `callback-service` (port `8894`) | Map of instance name → config; the key becomes `WORKER_INSTANCE_TYPE` |
| `workers.<name>.listenPort` | *(required per entry)* | Must not collide across workers |
| `workers.<name>.replicas` | *(k8s default)* | Per-instance scaling; there is **no autoscaling** in this chart |
| `workers.<name>.service` | *(unset)* | Dedicated Service for this worker — **only supported for `api-gateway`**; any other name fails the render |
| `workers.<name>.terminationGracePeriodSeconds` | `1800` | Long by design, so in-flight scans finish before the pod is killed. Lower it only if losing in-flight scans on rollout/scale-down is acceptable |
| `workers.<name>.logLevel` | `info` | Maps to `WORKER_INSTANCE_LOG_LEVEL` |
| `workers.<name>.isolate.enabled` / `.timeout` | `true` / `1600` | `WORKER_ISOLATE_INSTANCE(_TIMEOUT)` |
| `workers.<name>.upgradeInstances` | *(falls back to top-level `upgradeInstances`)* | Per-worker override |

Each worker also accepts `version`, `imagePullPolicy`, `resources`, `nodeSelector`/`affinity`/`tolerations`, and `probes` overrides, same as the services chart. Adding a key to `workers` creates another StatefulSet on `helm upgrade`; removing one deletes it. `env` in this chart only holds the two keys the worker template reads directly (`WORKER_LISTEN_PORT`, `WORKER_SERVICE_NAMESPACE`) — every other setting comes from the `mdcluster-config` ConfigMap owned by `md-cluster-services`, so change it there rather than duplicating it here.

## Production configuration

- **License key** — `secrets.LICENSE_KEY` is empty by default; the deployment isn't usable without it.
- **Rotate every dev-default credential** — see the `secrets` table above. `ADMIN_APIKEY` in particular looks optional (`''`) but is required for the admin account and inter-service registration to work at all.
- **All four DB passwords must match** — `CONTROL_CENTER_DB_PASSWORD`, `IDENTITY_DB_PASSWORD`, `DATALAKE_PASSWORD`, `WAREHOUSE_PASSWORD` are the same underlying Postgres superuser when using the in-chart database.
- **Use external PostgreSQL/Redis/RabbitMQ in production** — the bundled ones (`postgres.enabled`, `redis.enabled`, `rabbitmq.enabled`, all `true` by default) target dev/test parity with the docker-compose stack, not HA. Disable them and point the matching `env` hosts/services at managed instances.
- **Persistence is off by default** — `file-storage.persistence.enabled` and `postgres.persistence.enabled` are both `false` (data in `emptyDir`, lost when the pod is replaced). Enable them (and set a `storageClassName` if your cluster needs one) for any deployment whose data matters. Persistent volumes carry `helm.sh/resource-policy: keep`, so they outlive `helm uninstall`.
- **Exposing Control Center** — defaults to `NodePort`; set `control-center.service.type: LoadBalancer` or `ClusterIP` and put your own Ingress in front, since neither chart ships an Ingress template.
- **Scaling is manual, no HPA** — scale `file-storage.replicas` and each `workers.<name>.replicas` directly. Keep `env.FILE_STORAGE_MIN_REPLICA`/`MAX_REPLICA` in the services chart in step with the actual `file-storage.replicas`.
- **`api-gateway` is the only worker that can have a dedicated Service** — setting `workers.<name>.service` on any other worker name fails the chart render on purpose.
- **Image pull secrets** — set `imagePullSecrets` in *both* charts' `values.yaml` for private registries; it's commented out by default.
- **Long worker shutdown window by design** — `terminationGracePeriodSeconds` defaults to `1800` (30 minutes) so in-flight scans finish before a pod is killed on scale-down/rollout. Only shorten it (e.g. in ephemeral test environments) if losing those scans is acceptable.
- **Version pinning during a rolling upgrade** — the top-level `MDCLS_VERSION` sets the default tag for every component, but each component/worker can override it with its own `version:` key to mix versions temporarily.

## Upgrading

```console
helm upgrade md-cluster-services ./md-cluster-services --namespace mdcluster --reuse-values

# Wait services upgraded successfully

helm upgrade md-cluster-instances ./md-cluster-instances --namespace mdcluster --reuse-values --set upgradeInstances=true
```

### Database upgrades

Not applicable when using an external, managed database. For the in-chart PostgreSQL, `postgres.image` pins the version (default `postgres:16`) — check release notes before bumping it across a major version.

## Uninstalling

```console
helm uninstall md-cluster-instances --namespace mdcluster

# Wait services uninstall successfully

helm uninstall md-cluster-services --namespace mdcluster
```
Uninstall the workers first to avoid them crash-looping against a ConfigMap/Secret that's about to disappear. Persistent volumes (if persistence was enabled) are kept (`helm.sh/resource-policy: keep`) and must be deleted separately if you want to reclaim the storage.

## Troubleshooting

- **Workers crash-loop right after install** — almost always `md-cluster-instances` was installed before `md-cluster-services` finished becoming ready, or into a different namespace. Confirm `kubectl -n mdcluster get configmap mdcluster-config` and `kubectl -n mdcluster get secret mdcluster-secrets` both exist first.
- **`Error: execution error ... a dedicated service is only supported for "api-gateway"`** — remove `workers.<name>.service` for any worker other than `api-gateway`.
- **Control Center can't reach a worker** — check `WORKER_SERVICE_NAMESPACE`/`WORKER_LISTEN_PORT` in the services chart's `env` match what the instances chart expects; they're read from the same `mdcluster-config` ConfigMap on both sides.
