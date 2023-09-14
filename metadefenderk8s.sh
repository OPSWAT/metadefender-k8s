#!/bin/bash

# Default Image version of MD Core to be installed
MD_CORE_IMAGE="latest"
region="eu-central-1"
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
db_host=postgres-core
project_id=""
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
cloudOptions[azurecluster]="AKS"
cloudOptions[azure1]="VMS"
cloudOptions[azurelb]="Private Load Balancer"
cloudOptions[azuredb]="PostgreSQL"
cloudOptions[gcpcluster]="GKE"
cloudOptions[gcp1]="VMS"
cloudOptions[gcplb]="Private Load Balancer"
cloudOptions[gcpdb]="Cloud SQL"



# Ask user for confirmation to proceed
function askProceed () {
  read -p "\nContinue? [Y/n] " ans
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


function askAccess () {

  read -p "Do you have your own access point or want to create an ingress to access? [Own/Ingress] " ans

  case "$ans" in
    Own | OWN )
      if [ "$LOCATION_PARAM" == "local" ];then
        echo "Disabling variables for Ingress, service type ClusterIp"
      else
        echo "Disabling variables for Ingress but it will create a LoadBalancer service type"
      fi
      optAccessSelec="Own"
      ingress_enabled=false

    ;;
    ingress | Ingress )

        optlb="${LOCATION_PARAM}lb"
        cloudOptlb=${cloudOptions[$optlb]}
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
  read -p "\nDo you want to create a private connection for the external database? [Yes/No] " ans
  case "$ans" in
    Yes | yes )
        echo "Create a private IP address for the Cloud SQL instance (requires the servicenetworking.services.addPeering permission)"
        privateconnection=true
    ;;
    No | no )
        echo "Private connection won't be created"
        privateconnection=false
    ;;
    * )
        echo "invalid response"
        askOwnDB
    ;;
  esac
}

function askDBExternal () {

    optdb="${LOCATION_PARAM}db"
    cloudOptDB=${cloudOptions[$optdb]}
    
    read -p "Create a PostgreSQL DB in K8S or create $LOCATION $cloudOptDB? [K8S/External] " ans
    case "$ans" in
        k8s | K8S )
            echo "postgres-core service will be created"
            optExtDBSelec="K8S"
            persistent=true
            externalDB=false
            k8s_db=true
        ;;
        external | External )
            echo "Creating $LOCATION $cloudOptDB and setting db variables"
            optExtDBSelec=$cloudOptDB
            externalDB=true
            k8s_db=false
            read -p "USERNAME for PostgreSQL DB $LOCATION $cloudOptDB: " db_user
            read -p "PASSWORD for PostgreSQL DB $LOCATION $cloudOptDB: " -s db_password
            if [ "$LOCATION_PARAM" == "gcp" ];then
              askPrivateConnection
            fi
        ;;
        * )
            echo "invalid response"
            askDBExternal
        ;;
    esac

}

function askOwnDB () {
  read -p "Do you want to set credentials for MetaDefender Core with this script? [Yes/No] " ans
  case "$ans" in
    Yes | yes )
      read -p "USERNAME for PostgreSQL DB: " db_user
      read -p "PASSWORD for PostgreSQL DB: " -s db_password
      read -p "Host url for PostgreSQL DB: " db_host
    ;;
    No | no )
      echo "the following secrets will need to be edited for starting MD Core services"
      echo " - user and password values of secret, mdcore-postgres-cred"
      echo " - DB_HOST configmap for database endpoint"
    ;;
    * )
        echo "invalid response"
        askOwnDB
    ;;
  esac
}

function askDB () {

  read -p "Do you have your own or want to create a PostgreSQL DB? [Own/New] " ans
  case "$ans" in
    Own | OWN | own )
      askOwnDB
      optDBSelec="Own"
      externalDB=false
      k8s_db=false
      privateconnection=false
    ;;
    new | New | NEW)
        if [ "$LOCATION_PARAM" == "local" ] || [ "${MODE}" == "install" ];then
          echo "We will create an postgreSQL pod in your cluster"
          optExtDBSelec="K8S"
          persistent=true
          externalDB=false
          k8s_db=true
          privateconnection=false
        else
          askDBExternal
        fi
        optDBSelec="New"
    ;;
    * )
      echo "invalid response"
      askDB
    ;;
  esac
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

    cd helm_charts/
    
    askAccess
    if [ "${MDCORE}" == "true" ];then
      askDB
    fi
    
    echo "SUMMARY OF SELECTIONS: "
    echo " - $optAccessSelec access to the cluster"
    if [ "${MDCORE}" == "true" ];then
      echo " - $optDBSelec PostgreSQL DB $optExtDBSelec"
    fi
    
    askProceed

    if [ "${MDCORE}" == "true" ];then
      installMDCore
    fi

    if [ "${MDSS}" == "true" ];then
      installMDSS
    fi
    
    if [ "${ICAP}" == "true" ];then
      installICAP
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

      elif [ "$LOCATION_PARAM" == "azure" ]; then
          helm_file="mdcore-azure-aks-values.yml"

      elif [ "$LOCATION_PARAM" == "gcp" ]; then
          if [ "$privateconnection" == "true" ];then
            helm_file="mdcore-gcloud-values.yml"
          else
            helm_file="mdcore-gcloud-sqlproxy-values.yml"
          fi
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
      --set md-core.image="opswat/metadefendercore-debian:"$MD_CORE_IMAGE

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
      helm install mdss mdss/ --namespace $namespace --create-namespace -f $helm_file \
      --set mdss_ingress.enabled=$ingress_enabled
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
  -var="POSTGRES_PASSWORD=$db_password"

  cluster_name=$(terraform output -raw MD_CLUSTER_NAME)
  echo $cluster_name

  
  #DB Endpoint
  if [ "${externalDB}" == "true" ];then
    db_host=$(terraform output -raw POSTGRES_ENDPOINT)
    db_host=$(echo $db_host | awk -F ':' '{print $1}')
    echo $db_host
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

function provision() {
    
    if [ "$LOCATION_PARAM" == "aws" ];then
      if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
      echo "Provisioning MD Core in "$LOCATION
      askAWSCredentials
      else
          echo "AWS Credentials detected in environment variables"
          cd terraform/aws/
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
    if [ "$LOCATION_PARAM" == "aws" ];then
      askCluster
    fi

    askAccess
    askDB

    echo "SUMMARY OF SELECTIONS: "
    echo " - Create cluster $LOCATION $clusterType with $optClusterSelec"
    echo " - $optAccessSelec access to the cluster"
    echo " - $optDBSelec PostgreSQL DB $optExtDBSelec"
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
      cd ../../helm_charts/
      installMDCore
      cd -
    fi

    if [ "${MDSS}" == "true" ];then
      cd ../../helm_charts/
      installMDSS
      cd -
    fi
    if [ "${ICAP}" == "true" ];then
      cd ../../helm_charts/
      installICAP
      cd -
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
elif [ "${MODE}" == "install" ]; then ## Upgrade the network from v1.0.x to v1.1
  install
elif [ "${MODE}" == "upgrade" ]; then ## Upgrade the network from v1.0.x to v1.1
  upgradeCluster
else
  printHelp
  exit 1
fi
