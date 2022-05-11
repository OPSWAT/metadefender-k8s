data "external" "os" {
  working_dir = path.module
  program     = ["printf", "{\"os\": \"Linux\"}"]
}

locals {
  os = data.external.os.result.os
  #   check = local.os == "Windows" ? "We are on Windows" : "We are on Linux"
}