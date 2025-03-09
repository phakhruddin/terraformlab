variable "instances" {
  description = "A map of instance names and types"
  type        = map(string)
  default     = {
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