
# These examples demonstrate how MetaDefender for Secure Storage can be configured in Terraform using the existing REST API
# More advanced API examples can be found in the official MDSS API reference here: https://docs.opswat.com/mdss/metadefender-for-secure-storage-api/ref
# Using the http provider, all MDSS API operations can also be implemented in Terraform

terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
      version = "3.2.1"
    }
  }
}

variable "mdss_base_url" {
  description = "URL to the MDSS deployment"
  default = "https://xx.xx.xx.xx"
}

variable "mdss_username" {
  description = "MDSS username for registration and API requests"
  default = "admin"
}

variable "mdss_email" {
  description = "MDSS email for registration"
  default = "admin@admin"
}

variable "mdss_full_name" {
  description = "MDSS full name for registration"
  default = "admin"
}

variable "mdss_password" {
  description = "MDSS password for registration and API requests"
  default = "<SET_PASSWORD>"
}

variable "mdss_ignore_tls" {
  description = "Ignores any TLS certificate issues"
  default = false
}

variable "mdss_license_key" {
  description = "MDSS license key used for online activation"
  default = "<SET_LICENSE_KEY>"
}

# First we need to register a new user for onboarding if this is a new instance of MDSS
data "http" "mdss_register" {
  url    = "${var.mdss_base_url}/api/user/register"
  method = "POST"
  insecure = var.mdss_ignore_tls

   request_headers = {
    Content-Type = "application/json"
  }

  request_body = <<EOF
  {
  "userName": "${var.mdss_username}",
  "password": "${var.mdss_password}",
  "email": "${var.mdss_email}",
  "fullName": "${var.mdss_full_name}"
  }
  EOF
}

locals {
  register_response = jsondecode(data.http.mdss_register.response_body)
}

# Next we need to login and get the authentication token for this session (which expires after one hour)
data "http" "mdss_auth" {
  url    = "${var.mdss_base_url}/api/User/authenticate"
  method = "POST"
  insecure = var.mdss_ignore_tls

   request_headers = {
    Content-Type = "application/json"
  }

  request_body = <<EOF
  {  "userName": "${var.mdss_username}", "password": "${var.mdss_password}"}
  EOF
}

# Save the auth token and header for further requests
locals {
  token = jsondecode(data.http.mdss_auth.response_body).accessToken
}
locals {
  mdss_request_headers = {
    Content-Type = "application/json"
    Authorization = "Bearer ${local.token}"
  }
}

# Activating MDSS
data "http" "mdss_activate" {
  url    = "${var.mdss_base_url}/api/Settings/admin/license/activate/online"
  method = "POST"
  insecure = var.mdss_ignore_tls

  request_headers = local.mdss_request_headers
  request_body = <<EOF
  {
  "key": "${var.mdss_license_key}"
  }
  EOF
}

locals {
  activate_response = jsondecode(data.http.mdss_activate.response_body)
}

# Adding a new MD Core instance
# the url and apikey need to be replaced in the request body
data "http" "mdss_add_core" {
  url    = "${var.mdss_base_url}/api/MetaDefenderCore"
  method = "POST"
  insecure = var.mdss_ignore_tls

  request_headers = local.mdss_request_headers
  request_body = <<EOF
  {
  "url": "{string}",
  "apiKey": "{string}"
  }
  EOF
}

locals {
  add_core_response = jsondecode(data.http.mdss_add_core.response_body)
}

# Listing all MD Core pools and instances
data "http" "mdss_core_pool" {
  url    = "${var.mdss_base_url}/api/CorePool"
  method = "GET"
  insecure = var.mdss_ignore_tls

  request_headers = local.mdss_request_headers
}

locals {
  core_pools = jsondecode(data.http.mdss_core_pool.response_body).entries
  core_pool_id = [for id in local.core_pools: id.id]
}

# Listing all configured storage units
data "http" "mdss_all_storages" {
  url    = "${var.mdss_base_url}/api/Storage/all"
  method = "GET"
  insecure = var.mdss_ignore_tls

  request_headers = local.mdss_request_headers
}

locals {
  storages = jsondecode(data.http.mdss_all_storages.response_body)
}

# Adding a new Amazon S3 bucket storage unit in mdss
# storageVendorType needs to be replaced with one of the following depending on the storage type: 
#   0 = AmazonS3, 1 = OneDrive, 2 = Box, 3 = DellIsilon, 4 = AzureFiles, 5 = SmbCompatible, 6 = S3Compatible, 7 = AzureBlob, 8 = AlibabaCloud, 9 = GoogleCloud
# More details on how to add different storage types can be found here: https://docs.opswat.com/mdss/3.1.2/metadefender-for-secure-storage-api/ref
data "http" "mdss_add_s3_storage" {
  url    = "${var.mdss_base_url}/api/Storage/amazons3"
  method = "POST"
  insecure = var.mdss_ignore_tls

  request_headers = local.mdss_request_headers

  request_body = jsonencode(
  {
  "name": "{string}",
  "corePoolId": local.core_pool_id[0] # In this configuration the storage is added to the first core pool ID
  "serviceUrl": "{string}",
  "accessKeyId": "{string}",
  "secretAccessKey": "{string}",
  "regionEndpoint": "{string}",
  "bucketName": "{string}",
  "folderLocation": "{string}",
  "useIamRole": "{boolean}",
  "assumeRoleArn": "{string}",
  "storageVendorType": "{int32}"
  })
  }

# In case one of the values from the json body is not correct, you can troubleshoot using the response message from the output below

output "mdss_add_storage_response_body" {
  value = data.http.mdss_add_s3_storage.response_body
}

locals {
  add_s3_response = jsondecode(data.http.mdss_add_s3_storage.response_body)
}
