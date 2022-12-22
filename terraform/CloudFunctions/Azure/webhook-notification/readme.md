Getting started:

This is an example of how to deploy an Azure Function App that calls the RTP webhook in MDSS. This example uses a Python function triggered by an EventGrid event and deploys all the necessary resources into a new Resource group. The folder structure is as follows: 
    - scripts - Scripts for preparing your local environment
    - src - Source code for the Python function
    - terraform - Terraform scripts for deploying all the necessary resources

Prerequisites:
    - Terraform 1.3.1+
    - An Azure account with permissions to deploy Azure Function App, Resource Group, Storage Account, App Service Plan, SAS Key, Event Grid System topic, Event Subscription
    - Python 3.9 (optional)
    - Git
    - Knowledge on provisioning resources in Azure

Deployment steps:
    - Clone this repo locally 
    - Modify example.tfvars with the values that suit your needs:
        fn_name: Function App name
        fn_resource_group_name: The name of the resource group in which the function app will be created."
        fn_service_plan_name:  The name of the app service plan
        fn_location: Resources location
        fn_storage_account_name: The name of the storage account to be created for the function. This is needed for the function to operate
        fn_site_config_always_on: Set to true so the function will not idle
        STORAGECLIENTID: MDSS Storage client ID. Can be found in MDSS under Storage Units
        APIKEY: MDSS Apikey. Can be generated in MDSS under Settings -> Users -> ... -> Configure Api Key
        APIENDPOINT: MDSS Api Endpoint. Should point to http(s)://{MDSS-ADDRESS}/api/webhook/realtime
        STORAGE_RG: The resource group where the storage account that triggers the function is
        STORAGE_ACCOUNT: The storage account name where the container triggers the function is
        STORAGE_CONTAINERNAME: The container name that triggers the function
    - from the terraform folder run the following commands:
        terraform init
        terraform plan
        terraform apply --var-file=example.tfvars

Once you run terraform apply, the terraform script will do the following:
    1. Check if you have the correct Python version installed
    2. If Python is outdated or missing, will download and extract a temporary Python instance. This will not overwrite or modify any older Python version already installed (if any)
    3. Generate .python_packages needed for the function to start
    4. Create a zip file with the contents of the "src" folder
    5. Create a resource group with a minimum set of resources needed for the function to start
    6. Copy the function ZIP package
    7. Configure the function to run from that ZIP package

Known Limitations:
    Due to Azure's way of handling events, we are currently supporting only Block Blobs. Page Blobs and Append blobs are not supported because the event is sent when the file is created instead of when the file if fully committed to the storage. This results in the event being sent to MDSS before the upload is finished.
