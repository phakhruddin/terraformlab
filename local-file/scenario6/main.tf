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
