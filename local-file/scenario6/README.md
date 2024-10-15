<script src="https://gist.github.com/xero/7af221436757237cbb76990377f330ef.js"></script>

To make Terraform display a parameter or value for each loop iteration during a `for_each` loop, you can use the **`local-exec` provisioner** inside a `null_resource` or print values using **`output`** blocks. These techniques can help you display a parameter or message for each resource in a loop.

### Option 1: Using `local-exec` in a `null_resource`

You can use the `local-exec` provisioner with `null_resource` and access the values of parameters inside the loop. Here's an example that prints a parameter for each iteration of the loop:

```hcl
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
```

In this example:

*   The `null_resource` iterates over the `instances` map.
*   The `local-exec` provisioner is used to print the instance name and type for each iteration.

### Option 2: Use Terraform `output` to Display Parameters after Plan or Apply

If you want to print out the values after `terraform plan` or `terraform apply`, you can use the `output` block to display the parameters.

```hcl
output "instance_details" {
  value = { for key, value in var.instances : key => "Instance type is ${value}" }
}
```

This output block will display the instance names and their types after Terraform has executed the plan or applied the changes.

### Example Output:

When running `terraform apply`, this output might look like:

```bash
instance_details = {
  instance1 = "Instance type is t2.micro"
  instance2 = "Instance type is t3.micro"
}
```

### Option 3: Using `null_resource` with `depends_on` (For Loop Sequence Control)

If you want to display messages sequentially across multiple resources, you can use `depends_on` to ensure that Terraform executes each loop in order, displaying values as needed.

```hcl
resource "null_resource" "step_log" {
  for_each = var.instances

  provisioner "local-exec" {
    command = "echo 'Processing ${each.key} with type ${each.value}'"
  }

  depends_on = [null_resource.previous_step]
}
```

This method ensures that logs are displayed in sequence based on dependencies between loop steps.

### Conclusion

To display parameters for each loop iteration in Terraform, the **`local-exec`** provisioner is the most common approach. It prints values during each iteration of the loop. You can also use **`output`** blocks to display the values after `plan` or `apply`.
