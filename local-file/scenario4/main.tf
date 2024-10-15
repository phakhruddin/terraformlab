provider "local" {}

# Define the environment variable
variable "env" {
  description = "The environment (prod or dev)"
  type        = string
  default     = "dev"  # Default to "dev", change to "prod" for production
}

# Read the YAML file containing file names and permissions
data "local_file" "files_yaml" {
  filename = "${path.module}/files/files_config.yaml"
}

# Parse the YAML content
locals {
  files_config = yamldecode(data.local_file.files_yaml.content).files
}

# Use a module to create files only if the environment is "prod"
module "file_creator" {
  for_each = var.env == "prod" ? { for file in local.files_config : file.name => file } : {}

  source = "./modules/file_creator"

  filename   = each.value.name
  content    = "This is a managed file for ${each.value.name} in the ${var.env} environment."
  
  # Use the can() function to handle missing or empty permissions
  permission = can(each.value.permission) && length(trimspace(each.value.permission)) > 0 ? each.value.permission : "644"
  
}
