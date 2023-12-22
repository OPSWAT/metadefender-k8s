#!/bin/bash

SCRIPT_PATH=$(pwd)

# Default Image version of MD Core to be installed
MD_CORE_IMAGE="latest"
cluster_name="md-k8s"
externalDB=false
# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform
OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
MDSS="false"
MDCORE="false"
namespace="default"
replicas=1
db_user="postgres"
db_password=null
mdcore_user="postgres"
mdcore_password=null
rabbit_mq_port=5671
redis_port_mdss=6379
db_host=postgres-core
project_id=""
externalRabbit_mdss=false
externalRedis_mdss=false
db_url_mdss="mongodb://mongodb:27017/MDCS"
rabbit_URI_mdss="amqp://rabbitmq:5672"
rabbit_ip_mdss="rabbitmq"
rabbit_mq_port=5672
rabbit_password_mdss="guest"
rabbit_user_mdss="guest"
redis_uri_mdss="redis:6379"
redis_host_mdss="redis"
redis_port_mdss=6379
k8s_db_mdss=true
privateconnection=true
# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  metadefenderk8s.sh provision|install|upgrade -l|--location <location> --mdcore|--mdss [-i|--image <image_version>] [--region <region>] [--name <name>] [--namespace <namespace>] [--replicas] "
  echo "  metadefenderk8s.sh -h|--help (print this message)"
  echo "    <mode> - one of 'provision', 'install' or 'upgrade'"
  echo "      - 'provision' - Generate resources in the CSP selected in --location"
  echo "      - 'install' - Install MD Core, use --mdss if you want to install mdss too"
  echo "      - 'upgrade'  - upgrade the MD Core version installed"
  echo "    -l <location> - Cloud Provider or Local Cluster [AWS | Azure | Local (Install only) ] - Required on provision and install mode"
  echo "    -mdss|--mdss - When flag included OPSWAT MDSS will be installed"
  echo "    -mdcore|--mdcore - When flag included on provision mode it will also install MD Core"
  echo "    -icap|--icap - When flag included on provision mode it will also install ICAP"
  echo "    -i | --image <image_version> - the image version of MD Core to be installed in the K8S Cluster (default: \"$MD_CORE_IMAGE\"). For other MetaDefender products it will install the latest tag"
  echo "    --region <region> - Region where the K8S Cluster will be created (default: \"$region\")"
  echo "    --name <name> - Name of the K8S Cluster that will be created (default: \"$cluster_name\")"
  echo "    --namespace <namespace> - Name of the namespace where to install the products in the K8S Cluster (default: \"default\")"
  echo "    --replicas <replicas> - Number of replicas of MD Core service (default: 1)"
  echo "    --project_id <project_id> - GCP Project ID (Required for GCP Provisioning)"
  echo
  echo "Typically, one would first provision the cluster selecting the location option "
  echo "that will guide you through the options to select"
  echo
  echo "	metadefenderk8s.sh provision -l AWS --mdcore"
  echo "	metadefenderk8s.sh provision -l AWS -i 5.1.2 --mdcore"
  echo "	metadefenderk8s.sh provision -l AWS -i 5.1.2 --mdcore --mdss"
  echo "	metadefenderk8s.sh provision -l AWS -i 5.1.2 --mdcore --icap"
  echo
}

declare -A cloudOptions
# add key/value string literals without quote
cloudOptions[awscluster]="EKS"
cloudOptions[aws1]="EC2"
cloudOptions[aws2]="Fargate"
cloudOptions[awslb]="Network Load Balancer (LB)"
cloudOptions[awsdb]="RDS"
cloudOptions[awsdbmdss]="Document DB"
cloudOptions[awsredismdss]="AWS Elastic Cache for Redis"
cloudOptions[awsrabbitmdss]="Amazon MQ for RabbitMQ"
cloudOptions[awsregion]="eu-central-1"
cloudOptions[azurecluster]="AKS"
cloudOptions[azure1]="VMS"
cloudOptions[azurelb]="Private Load Balancer"
cloudOptions[azuredb]="PostgreSQL"
cloudOptions[azuredbmdss]="Cosmos DB"
cloudOptions[azureredismdss]="Azure Cache for Redis"
cloudOptions[azureregion]="centralus"
cloudOptions[gcpcluster]="GKE"
cloudOptions[gcp1]="VMS"
cloudOptions[gcplb]="Private Load Balancer"
cloudOptions[gcpdb]="Cloud SQL"
cloudOptions[gcpdbmdss]="Mongo DB Atlas"
cloudOptions[gcpredismdss]="Memorystore for Redis"
cloudOptions[gcpregion]="us-central1"



# Ask user for confirmation to proceed
function askProceed () {
  read -p "Continue? [Y/n] " ans
  case "$ans" in
    y|Y|"" )
      echo "proceeding ..."
    ;;
    n|N )
      echo "exiting..."
      exit 1
    ;;
    * )
      echo "invalid response"
      askProceed
    ;;
  esac
}

function askCluster () {
    
    opt1="${LOCATION_PARAM}1"
    opt2="${LOCATION_PARAM}2"
    cloudOpt1=${cloudOptions[$opt1]}
    cloudOpt2=${cloudOptions[$opt2]}

  read -p "Do you want to create the cluster with '$cloudOpt1' or '$cloudOpt2'? [$cloudOpt1/$cloudOpt2] " ans
  case "$ans" in
    $cloudOpt1 )
      echo "Setting variables for $cloudOpt1"
      optClusterSelec=$cloudOpt1
      serverless=false
      persistent=true
    ;;
    $cloudOpt2 )
      echo "Setting variables for $cloudOpt2"
      optClusterSelec=$cloudOpt2
      serverless=true
      persistent=false
    ;;
    * )
      echo "invalid response"
      askCluster
    ;;
  esac
}

function askIPType () {
  read -p "Do you want the load balancer have attached an private or public IP? [Private/Public] " ans
  case "$ans" in
    Private | PRIVATE )
      ipInternal="true"
    ;;
    Public | PUBLIC )
      ipInternal="false"
    ;;
    * )
      echo "invalid response"
      askIPType
    ;;
  esac
}
function askAccess () {

  read -p "Do you have your own access point or want to create an ingress to access? [Own/Ingress] " ans

  case "$ans" in
    Own | OWN )
      if [ "$LOCATION_PARAM" == "local" ];then
        echo "Disabling variables for Ingress, service type ClusterIp"
      else
        echo "Disabling variables for Ingress but it will create a LoadBalancer service type"
        askIPType
      fi
      optAccessSelec="Own"
      ingress_enabled=false
    ;;
    ingress | Ingress )

        if [ "$LOCATION_PARAM" == "local" ];then
          echo "Enabling variables for Ingress, service type ClusterIp"
        else
          echo "Enabling variables for Ingress, service type LoadBalancer"
        fi
        optAccessSelec="Ingress"
        ingress_enabled=true

    ;;
    * )
      echo "invalid response"
      askAccess
    ;;
  esac
}

function askPrivateConnection () {
  read -p "Do you want to create a private connection for the external database? [Yes/No] " ans
  case "$ans" in
    Yes | yes )
        echo "Create a private IP address for the Cloud SQL instance (requires the servicenetworking.services.addPeering permission)"
        echo "When using private connection it can take some minutes for GCP to allow connections from GKE to Cloud SQL"
        privateconnection=true
    ;;
    No | no )
        echo "Private connection won't be created and Cloud SQL Auth Proxy pod will be generated when installing"
        privateconnection=false
    ;;
    * )
        echo "invalid response"
        askPrivateConnection
    ;;
  esac
}

function askDBExternalMDCore () {

    optdb="${LOCATION_PARAM}db"
    cloudOptDB=${cloudOptions[$optdb]}
    
    read -p "Create a PostgreSQL DB in K8S or create $LOCATION $cloudOptDB? [K8S/External] " ans
    case "$ans" in
        k8s | K8S )
            echo "postgres-core service will be created"
            optExtDBSelecMDCore="K8S"
            persistent=true
            externalDB=false
            k8s_db=true
            privateconnection=false
        ;;
        external | External )
            echo "Creating $LOCATION $cloudOptDB and setting db variables"
            optExtDBSelecMDCore=$cloudOptDB
            externalDB=true
            k8s_db=false
            read -p "USERNAME for PostgreSQL DB $LOCATION $cloudOptDB: " db_user
            read -p "PASSWORD for PostgreSQL DB $LOCATION $cloudOptDB: " -s db_password
            echo
            if [ "$LOCATION_PARAM" == "gcp" ];then
              askPrivateConnection
            fi
        ;;
        * )
            echo "invalid response"
            askDBExternalMDCore
        ;;
    esac

}

function askOwnDBMDCore () {
  read -p "Do you want to set credentials for MetaDefender Core with this script? [Yes/No] " ans
  case "$ans" in
    Yes | yes )
      read -p "USERNAME for PostgreSQL DB: " db_user
      read -p "PASSWORD for PostgreSQL DB: " -s db_password
      echo
      read -p "Host url for PostgreSQL DB: " db_host
    ;;
    No | no )
      echo "the following secrets will need to be edited for starting MD Core services"
      echo " - user and password values of secret, mdcore-postgres-cred"
      echo " - DB_HOST configmap for database endpoint"
    ;;
    * )
        echo "invalid response"
        askOwnDBMDCore
    ;;
  esac
}

function askDBMDCore () {

  read -p "Do you have your own or want to create a PostgreSQL DB? [Own/New] " ans
  case "$ans" in
    Own | OWN | own )
      askOwnDBMDCore
      optDBSelecMDCore="Own"
      externalDB=false
      k8s_db=false
      privateconnection=false
    ;;
    new | New | NEW)
        if [ "$LOCATION_PARAM" == "local" ] || [ "${MODE}" == "install" ];then
          echo "We will create an postgreSQL pod in your cluster"
          optExtDBSelecMDCore="K8S"
          persistent=true
          externalDB=false
          k8s_db=true
          privateconnection=false
        else
          askDBExternalMDCore
        fi
        optDBSelecMDCore="New"
    ;;
    * )
      echo "invalid response"
      askDBMDCore
    ;;
  esac
}


function askDBExternalMDSS () {

    optdb="${LOCATION_PARAM}dbmdss"
    cloudOptDBMDSS=${cloudOptions[$optdb]}
    
    read -p "Create a Mongo DB in K8S or create $LOCATION $cloudOptDBMDSS? [K8S/External] " ans
    case "$ans" in
        k8s | K8S )
            echo "Mongo db service will be created in K8S"
            optExtDBSelecMDCore="K8S"
            persistent_mdss=true
            externalDB_mdss=false
            k8s_db_mdss=true
            privateconnection_mdss=false
        ;;
        external | External )
            echo "Creating $LOCATION $cloudOptDBMDSS and setting db variables"
            optExtDBSelecMDSS=$cloudOptDBMDSS
            externalDB_mdss=true
            k8s_db_mdss=false
            read -p "USERNAME for Mongo DB $LOCATION $cloudOptDBMDSS: " db_user_mdss
            read -p "PASSWORD for Mongo DB $LOCATION $cloudOptDBMDSS: " -s db_password_mdss
            echo
        ;;
        * )
            echo "invalid response"
            askDBExternalMDSS
        ;;
    esac

}

function askOwnDBMDSS () {
  read -p "Do you want to set credentials for MetaDefender For Secure Storage Mongo DB with this script? [Yes/No] " ans
  case "$ans" in
    Yes | yes )
      read -p "USERNAME for Mongo DB: " db_user_mdss
      read -p "PASSWORD for Mongo DB: " -s db_password_mdss
      echo
      read -p "Host url for Mongo DB: " db_host_mdss
    ;;
    No | no )
      echo "Edit the following configmap for starting MDSS services"
      echo " - MONGO_URI in mdss-env configmap with the connection string"
    ;;
    * )
        echo "invalid response"
        askOwnDBMDSS
    ;;
  esac
}

function askDBMDSS () {

  read -p "Do you have your own or want to create a Mongo DB? [Own/New] " ans
  case "$ans" in
    Own | OWN | own )
      askOwnDBMDSS
      optDBSelecMDSS="Own"
      externalDB_mdss=false
      k8s_db_mdss=false
      privateconnection_mdss=false
    ;;
    new | New | NEW)
        if [ "$LOCATION_PARAM" == "local" ] || [ "${MODE}" == "install" ];then
          echo "We will create a mongo db pod in your cluster"
          optExtDBSelecMDSS="K8S"
          persistent_mdss=true
          externalDB_mdss=false
          k8s_db_mdss=true
          privateconnection_mdss=false
        else
          askDBExternalMDSS
        fi
        optDBSelecMDSS="New"
    ;;
    * )
      echo "invalid response"
      askDBMDSS
    ;;
  esac
}

function askRedisExternalMDSS () {

    optdb="${LOCATION_PARAM}redismdss"
    cloudOptRedisMDSS=${cloudOptions[$optdb]}
    
    read -p "Create a Redis Service in K8S or create $LOCATION $cloudOptRedisMDSS? [K8S/External] " ans
    case "$ans" in
        k8s | K8S )
            echo "Redis service will be created"
            optExtRedisSelecMDSS="K8S"
            externalRedis_mdss=false
        ;;
        external | External )
            echo "Creating $LOCATION $cloudOptRedisMDSS and setting variables"
            optExtRedisSelecMDSS=$cloudOptRedisMDSS
            externalRedis_mdss=true
        ;;
        * )
            echo "invalid response"
            askRedisExternalMDSS
        ;;
    esac

}

function askOwnRedisMDSS () {
  read -p "Do you want to configure the redis URI for MetaDefender For Secure Storage with this script? [Yes/No] " ans
  case "$ans" in
    Yes | yes )
      read -p "URI for Redis: " redis_uri_mdss
    ;;
    No | no )
      echo "Edit the following configmap for starting MDSS services"
      echo " - CACHE_SERVICE_URI in mdss-env configmap with the connection string"
    ;;
    * )
        echo "invalid response"
        askOwnRedisMDSS
    ;;
  esac
}


function askRedisMDSS () {

  read -p "Do you have your own or want to create a Redis Cache service? [Own/New] " ans
  case "$ans" in
    Own | OWN | own )
      askOwnRedisMDSS
      optRedisSelecMDSS="Own"
      externalRedis_mdss=false
    ;;
    new | New | NEW)
        if [ "$LOCATION_PARAM" == "local" ] || [ "${MODE}" == "install" ];then
          echo "We will create a Redis pod in your cluster"
          optExtRedisSelecMDSS="K8S"
          externalRedis_mdss=false
        else
          askRedisExternalMDSS
        fi
        optRedisSelecMDSS="New"
    ;;
    * )
      echo "invalid response"
      askRedisMDSS
    ;;
  esac
}

function askRabbitExternalMDSS () {

    optdb="${LOCATION_PARAM}rabbitmdss"
    cloudOptRabbitMDSS=${cloudOptions[$optdb]}
    
    if [ "$LOCATION_PARAM" == "aws" ];then
      read -p "Create a Rabbit Service in K8S or create $LOCATION $cloudOptRabbitMDSS? [K8S/External] " ans
      case "$ans" in
        k8s | K8S )
            echo "Rabbit service will be created in K8S"
            optExtRabbitSelecMDSS="K8S"
            externalRabbit_mdss=false
        ;;
        external | External )
            echo "Creating $LOCATION $cloudOptRabbitMDSS and setting variables"
            optExtRabbitSelecMDSS=$cloudOptRabbitMDSS
            externalRabbit_mdss=true
            read -p "USERNAME for Rabbit MQ $LOCATION $cloudOptRabbitMDSS: " rabbit_user_mdss
            read -p "PASSWORD for Rabbit MQ $LOCATION $cloudOptRabbitMDSS: " -s rabbit_password_mdss
            echo
        ;;
        * )
            echo "invalid response"
            askRabbitExternalMDSS
        ;;
      esac
    
    else
        ### Rabbit MQ with HA only supported in AWS
        echo "Rabbit service will be created in K8S"
        optExtRabbitSelecMDSS="K8S"
        externalRabbit_mdss=false
    fi
  
}

function askOwnRabbitMQMDSS () {
  read -p "Do you want to configure the credentials for RabbitMQ with this script? [Yes/No] " ans
  case "$ans" in
    Yes | yes )
      read -p "USERNAME for RabbitMQ: " rabbit_user_mdss
      read -p "PASSWORD for RabbitMQ: " -s rabbit_password_mdss
      echo
      read -p "Host url for RabbitMQ: " rabbit_host_mdss
    ;;
    No | no )
      echo "Edit the following configmap for starting MDSS services"
      echo " - RABBITMQ_URI in mdss-env configmap with the connection string"
      echo " - RABBITMQ_HOST in mdss-env configmap with the host"
      echo " - RABBITMQ_PORT in mdss-env configmap with the port"
      echo " - RABBITMQ_DEFAULT_PASS in mdss-env configmap with the password"
      echo " - RABBITMQ_DEFAULT_USER in mdss-env configmap with the username"
    ;;
    * )
        echo "invalid response"
        askOwnRabbitMQMDSS
    ;;
  esac
}

function askRabbitMQMDSS () {

  read -p "Do you have your own or want to create a RabbitMQ service? [Own/New] " ans
  case "$ans" in
    Own | OWN | own )
      askOwnRabbitMQMDSS
      optRabbitSelecMDSS="Own"
      externalRabbit_mdss=false
    ;;
    new | New | NEW)
        if [ "$LOCATION_PARAM" == "local" ] || [ "${MODE}" == "install" ];then
          echo "We will create a Rabbit MQ pod in your cluster"
          optRabbitSelecMDSS="K8S"
          externalRabbit_mdss=false
        else
          askRabbitExternalMDSS
        fi
        optRabitSelecMDSS="New"
    ;;
    * )
      echo "invalid response"
      askRabbitMQMDSS
    ;;
  esac
}

function ask3rdPartyMDSS () {
  askDBMDSS
  askRedisMDSS
  askRabbitMQMDSS
}

function askAWSCredentials () {
  echo "ERROR: Please export AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY"
  exit 1
}

function askAzureCredentials () {
  echo "ERROR: Please export ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID & ARM_TENANT_ID"
  exit 1
}

function askGCPCredentials () {
  echo "ERROR: Please export GCP_JSON_CREDENTIALS_PATH"
  exit 1
}

function setClusterContext () {
    echo "Listing contexts..."
    kubectl config get-contexts
    read -p "Is the current context correct? [Yes/No] " current
    case "$current" in
    Yes | yes )
      echo "Context set up"
    ;;
    no | No)
      read -p "Indicate name context where to install MD core: " context
      kubectl config set-context $context
      echo "Context "$context" set up"
      echo "Listing contexts..."
      setClusterContext
    ;;
    * )
      echo "invalid response"
      setClusterContext
    ;;
    esac
}

function install(){

    setClusterContext
    askAccess
    if [ "${MDCORE}" == "true" ];then
      askDBMDCore
      echo "SUMMARY OF SELECTIONS MetaDefender Core: "
      echo " - $optAccessSelec access to the cluster"
      echo " - $optDBSelecMDCore PostgreSQL DB $optExtDBSelecMDCore"
    fi

    if [ "${MDSS}" == "true" ];then
      ask3rdPartyMDSS
      echo "SUMMARY OF SELECTIONS MetaDefender For Secure Storage: "
      echo " - $optAccessSelec access to the cluster"
      echo " - $optDBSelecMDSS Mongo DB $optExtDBSelecMDSS"
      echo " - $optRedisSelecMDSS Redis service $optExtRedisSelecMDSS"
      echo " - $optRabbitSelecMDSS Rabbit service $optExtRabbitSelecMDSS"
    fi
    
    
    askProceed

    if [ "${MDCORE}" == "true" ];then
      cd $SCRIPT_PATH
      cd helm_charts/
      installMDCore
      cd $SCRIPT_PATH
    fi

    if [ "${MDSS}" == "true" ];then
      cd $SCRIPT_PATH
      cd helm_charts/
      installMDSS
      cd $SCRIPT_PATH
    fi
    
    if [ "${ICAP}" == "true" ];then
      cd $SCRIPT_PATH
      cd helm_charts/
      installICAP
      cd $SCRIPT_PATH
    fi
}

function installMDCore() {
    echo "Starting to install MD Core inside the K8S cluster"
    
    if [ -z "${MDCORE_LICENSE_KEY}" ]; then
      echo "MDCORE_LICENSE_KEY not found in environment variables"
      read -p "Add MetaDefender License Key: " MDCORE_LICENSE_KEY
    else
        echo "MDCORE_LICENSE_KEY found in the environment variables"
    fi

    echo "Setting up the MetaDefender Core UI credentials"
    read -p "Username MetaDefender Core UI: " mdcore_user
    read -p "Password MetaDefender Core UI: " -s mdcore_password
    echo

    askProceed

    if [ "$LOCATION_PARAM" == "local" ];then

        helm install mdcore mdcore/ --namespace $namespace --create-namespace \
        --set core_ingress.enabled=$ingress_enabled \
        --set mdcore_license_key=$MDCORE_LICENSE_KEY \
        --set deploy_with_core_db=$k8s_db \
        --set core_components.md-core.replicas=$replicas \
        --set mdcore_password=$mdcore_password \
        --set mdcore_user=$mdcore_user \
        --set db_user=$db_user \
        --set db_password=$db_password \
        --set MDCORE_DB_HOST=$db_host \
        --set md-core.image="opswat/metadefendercore-debian:"$MD_CORE_IMAGE

    else

      if [ "$LOCATION_PARAM" == "aws" ];then
          helm_file="mdcore-aws-eks-values.yml"
          if [ "$ipInternal" == "true" ];then
            ipInternal="nlb-ip"
          else
            ipInternal="external"
          fi
          helm install mdcore mdcore/ --namespace $namespace --create-namespace -f $helm_file \
          --set core_ingress.enabled=$ingress_enabled \
          --set mdcore_license_key=$MDCORE_LICENSE_KEY \
          --set deploy_with_core_db=$k8s_db \
          --set core_components.md-core.replicas=$replicas \
          --set mdcore_password=$mdcore_password \
          --set mdcore_user=$mdcore_user \
          --set db_user=$db_user \
          --set db_password=$db_password \
          --set MDCORE_DB_HOST=$db_host \
          --set core_components.md-core.service_annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=$ipInternal \
          --set md-core.image="opswat/metadefendercore-debian:"$MD_CORE_IMAGE

      elif [ "$LOCATION_PARAM" == "azure" ]; then
          helm_file="mdcore-azure-aks-values.yml"

          helm install mdcore mdcore/ --namespace $namespace --create-namespace -f $helm_file \
          --set core_ingress.enabled=$ingress_enabled \
          --set mdcore_license_key=$MDCORE_LICENSE_KEY \
          --set deploy_with_core_db=$k8s_db \
          --set core_components.md-core.replicas=$replicas \
          --set mdcore_password=$mdcore_password \
          --set mdcore_user=$mdcore_user \
          --set db_user=$db_user \
          --set db_password=$db_password \
          --set MDCORE_DB_HOST=$db_host \
          --set core_components.md-core.service_annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"="'"$ipInternal"'" \
          --set md-core.image="opswat/metadefendercore-debian:"$MD_CORE_IMAGE 


      elif [ "$LOCATION_PARAM" == "gcp" ]; then
          if [ "$privateconnection" == "true" ] || [ "$optExtDBSelecMDCore" == "K8S" ];then
            helm_file="mdcore-gcloud-values.yml"
          else
            helm_file="mdcore-gcloud-sqlproxy-values.yml"
            echo "Configuring variables for connecting to the database through the SQL proxy provided by GCP"
            sed -i "s/<CLOUDSQL_CONNECTION_NAME>/$db_host/g" mdcore-gcloud-sqlproxy-values.yml
            db_host="cloud-sql-proxy"
          fi

          if [ "$ipInternal" == "true" ];then

            helm install mdcore mdcore/ --namespace $namespace --create-namespace -f $helm_file \
            --set core_ingress.enabled=$ingress_enabled \
            --set mdcore_license_key=$MDCORE_LICENSE_KEY \
            --set deploy_with_core_db=$k8s_db \
            --set core_components.md-core.replicas=$replicas \
            --set mdcore_password=$mdcore_password \
            --set mdcore_user=$mdcore_user \
            --set db_user=$db_user \
            --set db_password=$db_password \
            --set MDCORE_DB_HOST=$db_host \
            --set core_components.md-core.service_annotations."networking\.gke\.io/load-balancer-type"="Internal" \
            --set md-core.image="opswat/metadefendercore-debian:"$MD_CORE_IMAGE

          else

            helm install mdcore mdcore/ --namespace $namespace --create-namespace -f $helm_file \
            --set core_ingress.enabled=$ingress_enabled \
            --set mdcore_license_key=$MDCORE_LICENSE_KEY \
            --set deploy_with_core_db=$k8s_db \
            --set core_components.md-core.replicas=$replicas \
            --set mdcore_password=$mdcore_password \
            --set mdcore_user=$mdcore_user \
            --set db_user=$db_user \
            --set db_password=$db_password \
            --set MDCORE_DB_HOST=$db_host \
            --set md-core.image="opswat/metadefendercore-debian:"$MD_CORE_IMAGE

          fi
      fi

      ## Install Load Balancer Controller for creating LB in the AWS Account
      if [ "$LOCATION_PARAM" == "aws" ];then
          cd $SCRIPT_PATH
          cd "example_scripts/"
          echo "Configuring variables for creating load balancer controller for AWS LB"
          sed -i "s/<K8S_CLUSTER_NAME>/$cluster_name/g" eks_install_lb_controller.sh
          sed -i "s/<K8S_REGION>/$cluster_region/g" eks_install_lb_controller.sh
          sed -i "s/<K8S_VPC_ID>/$vpc_id/g" eks_install_lb_controller.sh
          read -p "AWS Account ID (without '-'): " -s account_id
          echo
          sed -i "s/<AWS_ACCOUNT_NR>/$account_id/g" eks_install_lb_controller.sh
          echo "Go to https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html and pick up the image for your region ($cluster_region)"
          read -p "IMAGE LB CONTROLLER PER REGION (No spaces): " image
          echo
          image_controller=$image"/amazon/aws-load-balancer-controller"
          echo "Image Controller: "$image_controller
          sed -i "s:<IMAGE_LB_CONTROLLER_REGION>:$image_controller:g" eks_install_lb_controller.sh
          echo "Running script to install AWS Load Balancer Controller"
          askProceed
          chmod +x eks_install_lb_controller.sh
          sed -i -e 's/\r$//' eks_install_lb_controller.sh
          ./eks_install_lb_controller.sh
      fi

    fi

}

function installMDSS () {
    echo "Starting to install MDSS inside the K8S cluster"
    askProceed

    if [ "$LOCATION_PARAM" == "local" ];then
      helm install mdss mdss/ --namespace $namespace --create-namespace \
      --set mdss_ingress.enabled=$ingress_enabled
    else
      if [ "$LOCATION_PARAM" == "aws" ];then
          helm_file="mdss-aws-eks-values.yml"
      elif [ "$LOCATION_PARAM" == "azure" ]; then
          helm_file="mdss-azure-aks-values.yml"
      elif [ "$LOCATION_PARAM" == "gcp" ]; then
          helm_file="mdss-gcloud-values.yml"
      fi
      if $externalRabbit_mdss ;then
        rabbit_replicas=0
        rabbit_mq_port=5671
      else
        rabbit_replicas=1
      fi
      if $externalRedis_mdss ;then
        redis_replicas=0
      else
        redis_replicas=1
      fi



      helm install mdss mdss/ --namespace $namespace --create-namespace -f $helm_file \
      --set mdss_ingress.enabled=$ingress_enabled \
      --set mdss-common-environment.MONGO_URL=$db_url_mdss \
      --set mdss-common-environment.RABBITMQ_URI=$rabbit_url_mdss \
      --set mdss-common-environment.RABBITMQ_HOST=$rabbit_Host_mdss \
      --set mdss-common-environment.CACHE_SERVICE_URI=$redis_uri_mdss \
      --set mdss-common-environment.CACHE_SERVICE_URL=$redis_host_mdss \
      --set mdss_components.rabbitmq.replicas=$rabbit_replicas \
      --set mdss_components.redis.replicas=$redis_replicas \
      --set deploy_with_mdss_db=$k8s_db_mdss 
    fi

}

function installICAP () {
    echo "Starting to install ICAP inside the K8S cluster"
    if [ -z "${MDICAPSRV_LICENSE_KEY}" ]; then
      echo "MDICAPSRV_LICENSE_KEY not found in environment variables"
      read -p "Add ICAP License Key: " MDICAPSRV_LICENSE_KEY
    else
        echo "MDICAPSRV_LICENSE_KEY found in the environment variables"
    fi
    askProceed
    helm install icap icap/ --namespace $namespace --create-namespace \
    --set icap_ingress.enabled=$ingress_enabled \
    --set mdicapsrv_license_key=$MDICAPSRV_LICENSE_KEY

}

function provisionAWS() {

  echo "Running terrafrom apply"

  askProceed

  terraform apply -var-file="variables/variables.tfvars" \
  -var="ACCESS_KEY_ID=$ACCESS_KEY_ID" \
  -var="SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY" \
  -var="MD_CLUSTER_NAME=$cluster_name" \
  -var="MD_CLUSTER_REGION=$region" \
  -var="PERSISTENT_DEPLOYMENT=$persistent" \
  -var="DEPLOY_FARGATE_NODES=$serverless" \
  -var="DEPLOY_RDS_POSTGRES_DB=$externalDB" \
  -var="POSTGRES_USERNAME=$db_user" \
  -var="POSTGRES_PASSWORD=$db_password" \
  -var="DEPLOY_REDIS=$externalRedis_mdss" \
  -var="DEPLOY_MONGO_DB=$externalDB_mdss" \
  -var="MONGO_USERNAME=$db_user_mdss" \
  -var="MONGO_PASSWORD=$db_password_mdss" \
  -var="DEPLOY_RABBITMQ=$externalRabbit_mdss" \
  -var="MQ_USERNAME=$rabbit_user_mdss" \
  -var="MQ_PASSWORD=$rabbit_password_mdss" 

  cluster_name=$(terraform output -raw MD_CLUSTER_NAME)
  echo $cluster_name
  vpc_id=$(terraform output -raw VPC_ID)
  echo $vpc_id
  cluster_region=$(terraform output -raw MD_CLUSTER_REGION)
  echo $cluster_region

  #DB Endpoint
  if [ "${externalDB}" == "true" ];then
    db_host=$(terraform output -raw POSTGRES_ENDPOINT)
    db_host=$(echo $db_host | awk -F ':' '{print $1}')
    echo $db_host
  fi 

  ##3rd Parties MDSS endpoints
  if [ "${externalDB_mdss}" == "true" ];then
    db_host_mdss=$(terraform output -raw MONGO_ENDPOINT)
    tls_config=$(terraform output -raw TLS_MONGO_ENABLED)
    if [ "${tls_config}" == "enabled" ];then
      db_url_mdss="mongodb://"$db_user_mdss":"$db_password_mdss"@"$db_host_mdss":27017/MDCS?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
    else
      db_url_mdss="mongodb://"$db_user_mdss":"$db_password_mdss"@"$db_host_mdss":27017/MDCS?replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
    fi
    echo $db_host_mdss
  fi 
  if [ "${externalRedis_mdss}" == "true" ];then
    redis_host_mdss=$(terraform output -raw REDIS_ENDPOINT)
    redis_uri_mdss=$redis_host_mdss":6379"
    echo $redis_uri_mdss
    redis_port_mdss=6379
  fi 
  if [ "${externalRabbit_mdss}" == "true" ];then
    rabbit_URI_mdss=$(terraform output -raw RABBITMQ_ENDPOINT | awk '{split($0,x,"/"); print x[3]}')
    rabbit_Host_mdss=$(echo $rabbit_URI_mdss | awk '{split($0,x,":"); print x[1]}' )
    echo $rabbit_URI_mdss
    rabbit_url_mdss="amqps://"$rabbit_user_mdss":"$rabbit_password_mdss"@"$rabbit_URI_mdss
    
    
  fi 
  
}

function provisionAzure() {

  echo "Running terrafrom apply"

  askProceed

  terraform apply \
  -var="aks_service_principal_app_id=$ARM_CLIENT_ID" \
  -var="aks_service_principal_client_secret=$ARM_CLIENT_SECRET" \
  -var="cluster_name=$cluster_name" \
  -var="deploy_postgres_db=$externalDB" \
  -var="resource_group_location=$region" \
  -var="postgres_admin=$db_user" \
  -var="postgres_password=$db_password"


  cluster_name=$(terraform output -raw cluster_name)
  echo $cluster_name
  resource_group_name=$(terraform output -raw resource_group_name)
  echo $resource_group_name
  
  #DB Endpoint
  if [ "${externalDB}" == "true" ];then
    db_host=$(terraform output -json db_server_fqdn_postgres)
    echo $db_host
    db_host=$(echo $db_host | tr -d '"')
    echo $db_host
    db_name=$(terraform output -json db_server_name_postgres)
    echo $db_name
    db_name=$(echo $db_name | tr -d '"')
    echo $db_name
    username_postgres=$(terraform output -json db_server_username_postgres)
    echo $username_postgres
  fi 

}
function provisionGCP() {

  echo "Running terrafrom apply"

  askProceed

  terraform apply \
  -var="gcloud_json_key_path=$GCP_JSON_CREDENTIALS_PATH" \
  -var="deploy_cloud_sql=$externalDB" \
  -var="cloud_sql_user=$db_user" \
  -var="cloud_sql_password=$db_password" \
  -var="private_ip_cloud_sql=$privateconnection" \
  -var="project_id=$project_id"

  cluster_name=$(terraform output -raw kubernetes_cluster_name)
  echo $cluster_name
  cluster_location=$(terraform output -raw cluster_location)
  echo $cluster_location

  
  #DB Endpoint
  if [ "${externalDB}" == "true" ];then
    if [ "${privateconnection}" == "true" ];then
      db_host=$(terraform output -raw cloud_sql_private_ip_address)
      echo $db_host
    else
      db_host=$(terraform output -raw cloud_sql_connection_name)
      echo $db_host
    fi
  fi 
  
}

function provision () {
    
    ### Check if the credentials are set up in the env variables for the CSP selected
    if [ "$LOCATION_PARAM" == "aws" ];then
      if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
      echo "Provisioning MD Core in "$LOCATION
      askAWSCredentials
      else
          echo "AWS Credentials detected in environment variables"
          cd terraform/aws/
          ## Ask for K8S cluster type in AWS
          askCluster
      fi
    elif [ "$LOCATION_PARAM" == "azure" ]; then
      if [ -z "${ARM_CLIENT_ID}" ] || [ -z "${ARM_CLIENT_SECRET}" ] || [ -z "${ARM_SUBSCRIPTION_ID}" ] || [ -z "${ARM_TENANT_ID}" ]; then
        echo "Provisioning MD Core in "$LOCATION
        askAzureCredentials
      else
          echo "Azure Credentials detected in environment variables"
          echo "For accesing to the cluster we will use the following public key '~/.ssh/id_rsa.pub'"
          cd terraform/azure/
      fi
    elif [ "$LOCATION_PARAM" == "gcp" ]; then
      if [ -z "${GCP_JSON_CREDENTIALS_PATH}" ]; then
        echo "Provisioning MD Core in "$LOCATION
        echo $GCP_JSON_CREDENTIALS_PATH
        askGCPCredentials
      else
          echo "GCP Credentials detected in environment variables"
          echo $GCP_JSON_CREDENTIALS_PATH
          echo "For accesing to the cluster we will use the following public key '~/.ssh/id_rsa.pub'"
          cd terraform/gcloud/
      fi
    else
      echo "To be developed"
    fi

    askAccess
    if [ "${MDCORE}" == "true" ];then
      askDBMDCore
    fi

    if [ "${MDSS}" == "true" ];then
      ask3rdPartyMDSS
    fi

    echo "SUMMARY OF SELECTIONS: "
    echo " - Create cluster $LOCATION $clusterType with $optClusterSelec"
    echo " - $optAccessSelec access to the cluster"
    echo " - (MD Core) $optDBSelecMDCore PostgreSQL DB $optExtDBSelecMDCore"
    if [ "${MDSS}" == "true" ];then
      echo " - (MDSS) $optDBSelecMDSS Mongo DB $optExtDBSelecMDSS"
      echo " - (MDSS) $optRedisSelecMDSS Redis service $optExtRedisSelecMDSS"
      echo " - (MDSS) $optRabbitSelecMDSS Rabbit service $optExtRabbitSelecMDSS"
    fi

    askProceed

    echo "Initializing terraform"
    terraform init

    if [ "$LOCATION_PARAM" == "aws" ];then
      provisionAWS
      echo "Including context info in the .kube/config"
      #Including context info in the .kube/config
      aws eks update-kubeconfig --region $region --name $cluster_name
    elif [ "$LOCATION_PARAM" == "azure" ];then
      provisionAzure
      echo "Including context info in the .kube/config"
      #Including context info in the .kube/config
      az aks get-credentials --name $cluster_name --overwrite-existing --resource-group $resource_group_name      
    elif [ "$LOCATION_PARAM" == "gcp" ];then
      provisionGCP
      echo "Including context info in the .kube/config"
      #Including context info in the .kube/config
      gcloud auth activate-service-account --key-file=$GCP_JSON_CREDENTIALS_PATH
      gcloud container clusters get-credentials $cluster_name --zone=$cluster_location
    fi

    if [ "${MDCORE}" == "true" ];then
      cd $SCRIPT_PATH
      cd helm_charts/
      installMDCore
      cd $SCRIPT_PATH
    fi

    if [ "${MDSS}" == "true" ];then
      cd $SCRIPT_PATH
      cd helm_charts/
      installMDSS
      cd $SCRIPT_PATH
    fi
    if [ "${ICAP}" == "true" ];then
      cd $SCRIPT_PATH
      cd helm_charts/
      installICAP
      cd $SCRIPT_PATH
    fi

}


function upgradeCluster() {
    echo "Upgrading Cluster from MetaDefender Script Coming Soon"
}


############## Here starts the Main function #############

MODE=$1;shift
# Determine whether provision or upgrade for announce
if [ "$MODE" == "provision" ]; then
  EXPMODE="Provisioning K8S cluster"
elif [ "$MODE" == "install" ]; then
  EXPMODE="Installing MD Core in K8S cluster, we will ask you for choosing between some options"
elif [ "$MODE" == "upgrade" ]; then
  EXPMODE="Upgrading the MD Core in K8S cluster "
else
  printHelp
  exit 1
fi
    while [[ $# -gt 0 ]]; do
      opt="$1";
      shift;
      current_arg="$1"
      if [[ "$current_arg" =~ ^-{1,2}.* ]] || [ "$current_arg" == "" ]; then
        if [ "${opt}" != "--mdss" ] && [ "${opt}" != "--mdcore" ] && [ "${opt}" != "--icap" ];then
            echo "ERROR: You may have left an argument blank. Double check your command." 
            exit 1;
        fi
      fi
      case "$opt" in
        "-l"|"--location")
            if [ "$MODE" == "provision" ] || [ "$MODE" == "install" ]; then
              LOCATION="$1";
              LOCATION_PARAM=$(echo $LOCATION | awk '{print tolower($0)}');
              shift
            else
              echo "Location parameter not supported for this mode ("$MODE")"
              exit 1
            fi
            ;;
        "--image") 
            MD_CORE_IMAGE="$1"; 
            shift;;
        "--region") 
            region="$1"; 
            shift;;
        "--name") 
            cluster_name="$1"; 
            shift;;
        "--namespace") 
            namespace="$1"; 
            shift;;
        "--replicas") 
            replicas="$1"; 
            shift;;
        "--project_id") 
            project_id="$1"; 
            shift;;
        "--mdcore") 
            MDCORE="true";;
        "--mdss") 
            MDSS="true";;
        "--icap") 
            ICAP="true";;
        *) 
        echo "ERROR: Invalid option: \""$opt"\"" >&2
        exit 1;;
      esac
    done

function checkLocation() {
  
  if [ "${LOCATION_PARAM}" == "aws" ] || [ "${LOCATION_PARAM}" == "azure" ] || [ "${LOCATION_PARAM}" == "gcp" ];then
        cluster=${LOCATION_PARAM}"cluster"
        clusterType=${cloudOptions[$cluster]}
        message=${EXPMODE}" "${LOCATION}" "${clusterType}
        if [ -z ${region} ]; then 
          locationregion=${LOCATION_PARAM}"region"
          region=${cloudOptions[$locationregion]}
          echo "Region to be used: "$region
        else 
          echo "Region to be used: "$region
        fi
  else
      if [ "${MODE}" == "provision" ];then
        # Location command is required
        echo "Location parameter is required, options AWS | Azure | GCP "
        printHelp
        exit 0
      fi
      if [ "${MODE}" == "install" ] && [ "${LOCATION_PARAM}" != "local" ];then
        # Location command is required
        echo "Location parameter is required, options AWS | Azure | GCP | Local"
        printHelp
        exit 0
      fi
  fi
}

checkLocation

#Required flags in all modes
if [ "${MDCORE}" == "false" ] && [ "${MDSS}" == "false" ];then
    echo "Product flag required in all modes"
    printHelp
    exit 0
fi

# Announce what was requested
if [ "${MODE}" == "provision" ];then 
  if [ "${MDCORE}" == "true" ];then 
        message=${message}" with the MD Core version '${MD_CORE_IMAGE}'";
  fi
  if [ "${MDSS}" == "true" ];then
        message=${message}" with MDSS";
  fi
  if [ "${ICAP}" == "true" ];then
        message=${message}" with ICAP";
  fi
  echo $message
fi
# ask for confirmation to proceed
askProceed

#Create the MD Core service in the location selected
if [ "${MODE}" == "provision" ]; then ## Generate Artifacts
  if [ "$LOCATION_PARAM" == "gcp" ] && [ -z "$project_id" ];then
      echo "GCP Project ID is required for GCP provisioning"
      printHelp
      exit 0
  fi
  provision
elif [ "${MODE}" == "install" ]; then
  install
elif [ "${MODE}" == "upgrade" ]; then ## Upgrade the network from v1.0.x to v1.1
  upgradeCluster
else
  printHelp
  exit 1
fi
