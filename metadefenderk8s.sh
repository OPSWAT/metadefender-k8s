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
db_host=postgres-core

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  md_core.sh provision|install|upgrade -l|--location <location> --mdcore|--mdss [-i|--image <image_version>] [--region <region>] [--name <name>] [--namespace <namespace>] [--replicas] "
  echo "  md_core.sh -h|--help (print this message)"
  echo "    <mode> - one of 'provision', 'install' or 'upgrade'"
  echo "      - 'provision' - Generate resources in the CSP selected in --location"
  echo "      - 'install' - Install MD Core, use --mdss if you want to install mdss too"
  echo "      - 'upgrade'  - upgrade the MD Core version installed"
  echo "    -l <location> - Cloud Provider or Local Cluster [AWS | Azure | GCP ] - Required on provision mode"
  echo "    -mdss|--mdss - When flag included OPSWAT MDSS will be installed"
  echo "    -mdcore|--mdcore - When flag included on provision mode it will also install MD Core"
  echo "    -i | --image <image_version> - the image version of MD Core to be installed in the K8S Cluster (default: \"$MD_CORE_IMAGE\")"
  echo "    --region <region> - Region where the K8S Cluster will be created (default: \"$region\")"
  echo "    --name <name> - Name of the K8S Cluster that will be created (default: \"$cluster_name\")"
  echo "    --namespace <namespace> - Name of the namespace where to install the products in the K8S Cluster (default: \"default\")"
  echo "    --replicas <replicas> - Number of replicas of MD Core service (default: 1)"
  echo
  echo "Typically, one would first provision the cluster selecting the location option "
  echo "that will guide you through the options to select"
  echo
  echo "	md_core.sh provision -l AWS -i 5.0.1 --mdcore"
  echo "	md_core.sh provision -l AWS -i 5.0.1 --mdcore --mdss"
  echo
}

declare -A cloudOptions
# add key/value string literals without quote
cloudOptions[awscluster]="EKS"
cloudOptions[aws1]="EC2"
cloudOptions[aws2]="Fargate"
cloudOptions[awslb]="Application Load Balancer (ALB)"
cloudOptions[awsdb]="RDS"
cloudOptions[azurecluster]="AKS"
cloudOptions[azure1]="VMS"
cloudOptions[azure2]="Containers"
cloudOptions[azurelb]="Application Gateway"
cloudOptions[azuredb]="PostgreSQL"



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


function askAccess () {

  read -p "Do you have your own access point or want to create an ingress to access? [Own/Ingress] " ans

  case "$ans" in
    Own | OWN )
      echo "Disabling variables for Ingress"
      optAccessSelec="Own"
      ingressMDCORE=false
      ingressMDSS=false
      lb_enabled=false

    ;;
    ingress | Ingress )

        optlb="${LOCATION_PARAM}lb"
        cloudOptlb=${cloudOptions[$optlb]}

        echo "Enabling variables for Ingress"
        echo "It will generate an $cloudOptlb in your $LOCATION account"
        optAccessSelec="Ingress"

        #As Ingress was selected we will create the load balancer for MD Core as default
        ingressMDCORE=true
        lb_enabled=true
        if [ "$MDCORE" == "true" ];then
          echo "An ingress controller for MD Core product will be installed"
        fi
        if [ "$MDSS" == "true" ];then
          ingressMDSS=true
          echo "An ingress controller for MDSS product will be installed"
        else
          ingressMDSS=false
        fi

    ;;
    * )
      echo "invalid response"
      askAccess
    ;;
  esac
}


function askDBExternal () {


    if [ "$LOCATION_PARAM" == "local" ];then
        read -p "We will create an external database for, select bewteen AWS or Azure? [AWS/Azure] " location
        LOCATION_PARAM=$(echo $LOCATION | awk '{print tolower($0)}'); 
    fi
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
            read -p "PASSWORD for PostgreSQL DB $LOCATION $cloudOptDB: " db_password

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
      read -p "PASSWORD for PostgreSQL DB: " db_password
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

    ;;
    new | New | NEW)
        if [ "$LOCATION_PARAM" == "local" ];then
          echo "We will create an postgreSQL pod in your cluster"
          optExtDBSelec="K8S"
          persistent=true
          externalDB=false
          k8s_db=true
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
    LOCATION_PARAM="local"
    
    askAccess
    askDB

    echo "SUMMARY OF SELECTIONS: "
    echo " - $optAccessSelec access to the cluster"
    echo " - $optDBSelec PostgreSQL DB $optExtDBSelec"
    askProceed

    if [ "${MDCORE}" == "true" ];then
      installMDCore
    fi

    if [ "${MDSS}" == "true" ];then
      installMDSS
    fi
}

function installMDCore() {
    echo "Starting to install MD Core inside the K8S cluster"
    askProceed


    if [ "$LOCATION_PARAM" == "aws" ];then
        helm_file="mdcore-aws-eks-values.yml"
        
        if [ "$optAccessSelec" == "Ingress" ];then
            helm install mdcore mdcore/ --wait --namespace $namespace --create-namespace -f $helm_file \
            --set core_ingress.enabled=$lb_enabled \
            --set environment=aws_eks_fargate \
            --set aws-load-balancer-controller.enabled=$lb_enabled \
            --set aws-load-balancer-controller.clusterName=$cluster_name \
            --set aws-load-balancer-controller.region=$region \
            --set aws-load-balancer-controller.vpcId=$vpc_id \
            --set aws-load-balancer-controller.serviceAccount.name=$serviceAccountName \
            --set aws-load-balancer-controller.serviceAccount.annotations\\.eks\\.amazonaws\\.com/role-arn=$serviceAccountNameRoleARN \
            --set mdcore_target_group_arn=$mdCoreTarget \
            --set mdcore_license_key=$MDCORE_LICENSE_KEY \
            --set deploy_with_core_db=$k8s_db \
            --set core_components.md-core.replicas=$replicas \
            --set db_user=$db_user \
            --set db_password=$db_password \
            --set MDCORE_DB_HOST=$db_host \
            --set md-core.image="opswat/metadefendercore-debian:"$MD_CORE_IMAGE
        else
            helm install mdcore mdcore/ --wait --namespace $namespace --create-namespace -f $helm_file \
            --set mdcore_license_key=$MDCORE_LICENSE_KEY \
            --set deploy_with_core_db=$k8s_db \
            --set core_ingress.enabled=false \
            --set core_components.md-core.replicas=$replicas \
            --set db_user=$db_user \
            --set db_password=$db_password \
            --set MDCORE_DB_HOST=$db_host
            --set md-core.image="opswat/metadefendercore-debian:"$MD_CORE_IMAGE
        fi
    elif [ "$LOCATION_PARAM" == "azure" ]; then
        helm_file="mdcore-azure-aks-values.yml"
        echo "Not ready yet"
        exit 1
    else
        helm_file="mdcore-generic-values.yml"
        helm install mdcore mdcore/ --wait --namespace $namespace --create-namespace -f $helm_file \
        --set mdcore_license_key=$MDCORE_LICENSE_KEY \
        --set deploy_with_core_db=$k8s_db \
        --set core_components.md-core.replicas=$replicas \
        --set db_user=$db_user \
        --set db_password=$db_password \
        --set MDCORE_DB_HOST=$db_host
    fi

}

function installMDSS () {
    echo "Starting to install MDSS inside the K8S cluster"
    askProceed

    if [ "$LOCATION_PARAM" == "aws" ];then
        helm_file="mdss-aws-eks-values.yml"
    elif [ "$LOCATION_PARAM" == "azure" ]; then
        helm_file="mdss-azure-aks-values.yml"
    else
        echo "Will create generic environment"
    fi

    if [ "$LOCATION_PARAM" == "aws" ];then

      helm install mdss mdss/ --wait --namespace $namespace --create-namespace -f $helm_file \
      --set environment=aws_eks_fargate \
      --set aws-load-balancer-controller.enabled=$lb_enabled \
      --set aws-load-balancer-controller.clusterName=$cluster_name \
      --set aws-load-balancer-controller.region=$region \
      --set aws-load-balancer-controller.vpcId=$vpc_id \
      --set aws-load-balancer-controller.serviceAccount.name=$serviceAccountName \
      --set aws-load-balancer-controller.serviceAccount.annotations\\.eks\\.amazonaws\\.com/role-arn=$serviceAccountNameRoleARN \
      --set webclient_target_group_arn=$webclient_target_group_arn \
      --set systemchecks_target_group_arn=$systemchecks_target_group_arn
    else

      helm install mdss mdss/ --wait --namespace $namespace --create-namespace

    fi

}

function provisionAWS() {

  echo "Running terrafrom apply"

  askProceed

  terraform apply -auto-approve -var-file="variables/variables.tfvars" \
  -var="ACCESS_KEY_ID=$ACCESS_KEY_ID" \
  -var="SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY" \
  -var="MD_CLUSTER_NAME=$cluster_name" \
  -var="MD_CLUSTER_REGION=$region" \
  -var="PERSISTENT_DEPLOYMENT=$persistent" \
  -var="DEPLOY_FARGATE_NODES=$serverless" \
  -var="DEPLOY_MDSS_INGRESS=$ingressMDSS" \
  -var="DEPLOY_MDCORE_INGRESS=$ingressMDCORE" \
  -var="DEPLOY_RDS_POSTGRES_DB=$externalDB" \
  -var="POSTGRES_USERNAME=$db_user" \
  -var="POSTGRES_PASSWORD=$db_password"


  cluster_name=$(terraform output -raw MD_CLUSTER_NAME)
  echo $cluster_name
  vpc_id=$(terraform output -raw VPC_ID)
  echo $vpc_id
  serviceAccountName=$(terraform output -raw LOAD_BALANCER_SERVICE_ACCOUNT_NAME)
  echo $serviceAccountName
  serviceAccountNameRoleARN=$(terraform output -raw LOAD_BALANCER_SERVICE_ACCOUNT_ROLE_ARN)
  echo $serviceAccountNameRoleARN

  mdCoreTarget=$(terraform output -raw MDCORE_TARGET_GROUP_ARN)
  echo $mdCoreTarget
  
  #MDSS target groups (ADD CONTROL)
  if [ "${MDSS}" == "true" ];then
    webclient_target_group_arn=$(terraform output -raw WEBCLIENT_TARGET_GROUP_ARN)
    echo $webclient_target_group_arn
    systemchecks_target_group_arn=$(terraform output -raw SYSTEMCHECKS_TARGET_GROUP_ARN)
    echo $systemchecks_target_group_arn
  fi
  
  #DB Endpoint
  if [ "${externalDB}" == "true" ];then
    db_host=$(terraform output -raw POSTGRES_ENDPOINT)
    db_host=$(echo $db_host | awk -F ':' '{print $1}')
    echo $db_host
  fi 
  

  
  if [ "$ingressMDCORE" == "true" ];then
    status_alb="$(aws elbv2 describe-load-balancers --names $cluster_name"-mdcore-load-balancer" | jq ".LoadBalancers[].State.Code")"
    echo $status_alb
    until [ "$status_alb" = "\"active\"" ];
    do
        echo "Checking availabilty of load balancer.... Try number "$x
        sleep 6s
        ((x=x+1))
        if [ x == 10 ];then
            echo "Tried "$x" times for checking the availability of the alb for setting up the target for MD Core service"
            exit 1
        fi
    done
  fi

}

function provision() {
    
    if [ "$LOCATION_PARAM" == "aws" ];then
      if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
      echo "Provisioning MD Core in "$LOCATION
      askAWSCredentials
      else
          echo "AWS Credentials detected in environment variables"
      fi
    elif [ "$LOCATION_PARAM" == "azure" ]; then
      echo "Azure provision is in development, you cannot use this script for Azure yet"
      exit 1
      #askAzureCredentials
    else
      echo "To be developed"
    fi

    askCluster
    askAccess
    askDB

    echo "SUMMARY OF SELECTIONS: "
    echo " - Create cluster $LOCATION $clusterType with $optClusterSelec"
    echo " - $optAccessSelec access to the cluster"
    echo " - $optDBSelec PostgreSQL DB $optExtDBSelec"
    askProceed

    cd terraform/aws/
    echo "Starting terraform"
    terraform init

    if [ "$LOCATION_PARAM" == "aws" ];then
      provisionAWS
      echo "Including context info in the .kube/config"
      #Including context info in the .kube/config
      aws eks update-kubeconfig --region $region --name $cluster_name
    fi

    if [ "${MDCORE}" == "true" ];then
      cd ../../helm_charts/
      installMDCore
      cd -
    fi

    if [ "${MDSS}" == "true" ];then
      cd ../../helm_charts/
      installMDSS
    fi

}


function upgradeCluster() {
    echo "Upgrading Cluster"
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
        if [ "${opt}" != "--mdss" ] && [ "${opt}" != "--mdcore" ];then
            echo "ERROR: You may have left an argument blank. Double check your command." 
            exit 1;
        fi
      fi
      case "$opt" in
        "-l"|"--location")
            if [ "$MODE" == "provision" ]; then
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
        "--mdcore") 
            MDCORE="true";;
        "--mdss") 
            MDSS="true";;
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
      if [ "${MODE}" == "provision" ] ;then
        # Location command is required
        echo "Location parameter is required, options AWS | Azure | GCP"
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
  echo $message
fi
# ask for confirmation to proceed
askProceed

#Create the MD Core service in the location selected
if [ "${MODE}" == "provision" ]; then ## Generate Artifacts
  provision
elif [ "${MODE}" == "install" ]; then ## Upgrade the network from v1.0.x to v1.1
  install
elif [ "${MODE}" == "upgrade" ]; then ## Upgrade the network from v1.0.x to v1.1
  upgradeCluster
else
  printHelp
  exit 1
fi
