
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
By default, the helm chart deploys MDSS with support for the following storage units: `azureblob,amazonsdk,nfs`. For a more efficient use of resources, we can specify only the storage units that are required by changing the `ENABLED_MODULES` value. For example, we can enable support for Azure, AWS and GCP:
```
ENABLED_MODULES: azureblob,azurefiles,amazonsdk,googlecloud
```
Currently supported modules:

`azureblob,amazonsdk,googlecloud,alibabacloud,azurefiles,oraclesdk,smb,box,graph,onedrive,sftp,mft,nfs`

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

