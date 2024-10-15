variable "instances" {
  description = "A map of instance names and types"
  type        = map(string)
  default = {
    instance1 = "t2.micro"
    instance2 = "t3.micro"
  }
}

resource "null_resource" "print_parameter" {
  for_each = var.instances

  provisioner "local-exec" {
    command = "echo 'Instance Name: ${each.key}, Instance Type: ${each.value}'"
  }
}

# display messages sequentially across multiple resources
resource "null_resource" "step_log" {
  for_each = var.instances

  provisioner "local-exec" {
    command = "echo 'Processing ${each.key} with type ${each.value}'"
  }

  depends_on = [null_resource.print_parameter]
}

output "instance_details" {
  value = { for key, value in var.instances : key => "Instance type is ${value}" }
}

#external yaml file example

provider "local" {}

# Read the YAML file containing the AMI configurations
data "local_file" "ami_config" {
  filename = "${path.module}/input.yaml"
}

# Decode the YAML file content
locals {
  ami_data = yamldecode(data.local_file.ami_config.content).amis
}

# Iterate over the AMI numbers and architectures from the YAML file
resource "null_resource" "print_ami_info" {
  for_each = { for ami_info in local.ami_data : ami_info.ami => ami_info }

  provisioner "local-exec" {
    command = "echo 'AMI: ${each.value.ami}, Architecture: ${each.value.architecture}'"
  }
}

# Output the AMI and architecture details after execution
output "ami_architecture_details" {
  value = { for ami_info in local.ami_data : ami_info.ami => "Architecture: ${ami_info.architecture}" }
}
