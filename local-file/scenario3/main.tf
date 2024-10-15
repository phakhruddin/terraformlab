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

# Create files only if the environment is "prod" and place them in the "result" subdirectory
resource "local_file" "managed_files" {
  for_each = var.env == "prod" ? { for file in local.files_config : file.name => file } : {}

  filename       = "${path.module}/result/${each.value.name}"
  content        = "This is a managed file for ${each.value.name} in the ${var.env} environment."
  file_permission = each.value.permission
}

# Outputs
output "created_files" {
  value = [for file in local_file.managed_files : file.filename]
}