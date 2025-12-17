MD_CLUSTER_NAME        = "md-k8s"
MD_CLUSTER_REGION      = "eu-central-1"
ACCESS_KEY_ID          = "<ACCESS_KEY_ID>"
SECRET_ACCESS_KEY      = "<SECRET_ACCESS_KEY>"
PERSISTENT_DEPLOYMENT  = true
DEPLOY_FARGATE_NODES   = true

## 3rd Party Services
## PostgreSQL RDS Database for MetaDefender Core, ICAP and Storage Security
DEPLOY_RDS_POSTGRES_DB = true
POSTGRES_USERNAME      = "<POSTGRES_USERNAME>"
POSTGRES_PASSWORD      = "<POSTGRES_PASSWORD>"

## Redis Cache AWS Elasticache Service for MetaDefender Storage Security
DEPLOY_REDIS           = false

## RabbitMQ AWS MQ Service for MetaDefender Storage Security
DEPLOY_RABBITMQ        = false
MQ_PASSWORD            = "<MQ_PASSWORD>"
MQ_USERNAME            = "<MQ_USERNAME>"