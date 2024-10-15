For **Scenario 2**, we'll introduce a YAML file to define **file names and permissions**. We'll also add logic to use Terraform's `for_each` loop to create resources based on the YAML input, and ensure the logic only executes when the environment is `prod`.

### Lab Overview:

1.  **YAML input**: Define files and their respective permissions.
2.  **Terraform `for_each` loop**: Dynamically create resources based on the input file.
3.  **Environment check (`env=prod`)**: The resources will only be created if the environment is set to `prod`.

* * *

## Initial

### Step 1: YAML Input File

Create a YAML file named `files_config.yaml` in the `files/` directory. This file will define the file names and permissions.

#### File: `files/files_config.yaml`

```yaml
files:
  - name: "config-prod.txt"
    permission: "600"
  - name: "secrets-prod.txt"
    permission: "640"
```

### Step 2: Update Terraform Configuration (`main.tf`)

Now, modify the Terraform code to read the YAML file, loop over the files, and only create resources if the environment is set to `prod`.

#### File: `main.tf`

```hcl
provider "local" {}

# Define the environment variable
variable "env" {
  description = "The environment (prod or dev)"
  type        = string
  default     = "dev"  # Default to "dev", change to "prod" as needed
}

# Read the YAML file containing file names and permissions
data "local_file" "files_yaml" {
  filename = "${path.module}/files/files_config.yaml"
}

# Parse the YAML content
locals {
  files_config = yamldecode(data.local_file.files_yaml.content).files
}

# Create files only if the environment is "prod"
resource "local_file" "managed_files" {
  for_each = { for file in local.files_config : file.name => file }

  # This will only execute if the environment is "prod"
  count = var.env == "prod" ? 1 : 0

  filename = each.value.name
  content  = "This is a managed file for ${each.value.name} in the ${var.env} environment."
  file_permission = each.value.permission
}

# Outputs
output "created_files" {
  value = [for file in local_file.managed_files : file.filename]
}
```

### Step 3: Explanation of Key Components

1.  **YAML Decoding**:
    
    *   The `data "local_file"` block reads the YAML file.
    *   The `yamldecode()` function parses the file and extracts the `name` and `permission` values for each file.
2.  **Environment Check**:
    
    *   The `count` is set to `1` if `var.env == "prod"`, meaning resources will only be created when the environment is set to `prod`. If the environment is not `prod`, the resource creation is skipped (`count = 0`).
3.  **Resource Creation**:
    
    *   The `local_file` resource creates files dynamically based on the parsed YAML input (`for_each` loop), using the `name` and `permission` values from the YAML file.
4.  **Output**:
    
    *   The `output` block lists the files that were created in the `prod` environment.

### Step 4: Add Input Variables

In **variables.tf**, define the environment variable that the user can pass to specify whether the environment is `prod` or `dev`.

#### File: `variables.tf`

```hcl
variable "env" {
  description = "The environment (prod or dev)"
  type        = string
  default     = "dev"
}
```

### Step 5: Running the Lab

1.  **Initialize Terraform**:
    
    ```bash
    terraform init
    ```
    
2.  **Run the Plan**: To check what will be created (nothing will happen in `dev`):
    
    ```bash
    terraform plan -var="env=dev"
    ```
    
    To apply the changes in `prod`:
    
    ```bash
    terraform apply -var="env=prod"
    ```
    
3.  **Output**: After running in `prod`, the output will list the files that were created based on the YAML input.
    

### Step 6: Clean Up Resources

To remove the created files after testing, run:

```bash
terraform destroy -var="env=prod"
```

* * *

### Conclusion

This lab demonstrates how to:

*   Read a YAML file for dynamic resource creation in Terraform.
*   Use the `for_each` loop to create multiple files based on user input.
*   Apply logic that only creates resources when the environment is set to `prod`.

This scenario can be expanded to include additional configurations or conditions as needed.

## _main.rf_error1_

The error you're encountering (`The "count" and "for_each" meta-arguments are mutually-exclusive`) means you can't use both `count` and `for_each` together in the same resource block. To fix this, we need to remove the `count` argument and conditionally handle the logic using `for_each` only.

Here’s how to modify the configuration to use **only `for_each`**, while conditionally creating resources based on the `env` variable.

### Updated `main.tf`

```hcl
provider "local" {}

# Define the environment variable
variable "env" {
  description = "The environment (prod or dev)"
  type        = string
  default     = "dev"  # Default to "dev", change to "prod" as needed
}

# Read the YAML file containing file names and permissions
data "local_file" "files_yaml" {
  filename = "${path.module}/files/files_config.yaml"
}

# Parse the YAML content
locals {
  files_config = yamldecode(data.local_file.files_yaml.content).files
}

# Filter out files if the environment is not prod
locals {
  files_to_create = var.env == "prod" ? local.files_config : {}
}

# Create files using for_each
resource "local_file" "managed_files" {
  for_each = { for file in local.files_to_create : file.name => file }

  filename       = each.value.name
  content        = "This is a managed file for ${each.value.name} in the ${var.env} environment."
  file_permission = each.value.permission
}

# Outputs
output "created_files" {
  value = [for file in local_file.managed_files : file.filename]
}
```

### Explanation:

1.  **Conditionally Filtering Files**:
    
    *   Instead of using `count`, I created a new local value `files_to_create`. This local will be empty (`{}`) if the environment is not `prod`. If the environment is `prod`, it will contain the list of files from the YAML file.
2.  **Using `for_each`**:
    
    *   The `for_each` loop now directly loops over the filtered `files_to_create` list, ensuring that no files are created if `env != "prod"`.
3.  **Outputs**:
    
    *   The `output` block will return the list of files that were created.

### How to Apply the Updated Code

1.  **Initialize Terraform**:
    
    ```bash
    terraform init
    ```
    
2.  **Run the Plan**: To simulate and check the actions that will be taken:
    
    ```bash
    terraform plan -var="env=dev"
    ```
    
    To apply the changes in the `prod` environment:
    
    ```bash
    terraform apply -var="env=prod"
    ```
    

This setup resolves the conflict between `count` and `for_each` by using `for_each` exclusively and conditionally filtering the input to ensure resources are only created when the environment is set to `prod`.

## _main.tf_error2_

### Terraform Error: Inconsistent Conditional Result Types

You received the following error while running Terraform:

```plaintext
Error: Inconsistent conditional result types

  on main.tf line 22, in locals:
  22:   files_to_create = var.env == "prod" ? local.files_config : {}
    ├────────────────
    │ local.files_config is tuple with 2 elements
    │ var.env is "prod"

The true and false result expressions must have consistent types. 
The 'true' value is tuple, but the 'false' value is object.
```

### Explanation:

This error occurs because Terraform expects both the `true` and `false` branches of a conditional expression to return the **same type**. In your case:

*   `local.files_config` is a **tuple** (a list or array).
*   `{}` is an **object** (a map).

Terraform cannot handle a mismatch between a **tuple** and an **object**.

### Solution:

To fix this, ensure that both branches return the same type. Since `local.files_config` is a tuple, the false branch should return an empty tuple (`[]`) instead of an empty object (`{}`).

### Corrected Code:

```hcl
locals {
  files_to_create = var.env == "prod" ? local.files_config : []
}
```

This ensures that both the `true` and `false` expressions return a tuple (either the actual list of files or an empty list).

The error you're seeing (`Inconsistent conditional result types`) occurs because the `true` and `false` branches of a Terraform conditional expression must return the same type. In your case, `local.files_config` is a **list/tuple**, while `{}` is an **empty object/map**. Terraform requires both branches of the `? :` operator to have consistent types.

### Solution:

You need to return the same data type (either a list or an empty list) when filtering the files to be created.

### Updated Code

Here’s how you can update your Terraform configuration to fix the type mismatch by returning an empty list (`[]`) instead of an empty map (`{}`):

```hcl
provider "local" {}

# Define the environment variable
variable "env" {
  description = "The environment (prod or dev)"
  type        = string
  default     = "dev"  # Default to "dev", change to "prod" as needed
}

# Read the YAML file containing file names and permissions
data "local_file" "files_yaml" {
  filename = "${path.module}/files/files_config.yaml"
}

# Parse the YAML content
locals {
  files_config = yamldecode(data.local_file.files_yaml.content).files
}

# Filter out files if the environment is not prod
locals {
  files_to_create = var.env == "prod" ? local.files_config : []
}

# Create files using for_each
resource "local_file" "managed_files" {
  for_each = { for file in local.files_to_create : file.name => file }

  filename       = each.value.name
  content        = "This is a managed file for ${each.value.name} in the ${var.env} environment."
  file_permission = each.value.permission
}

# Outputs
output "created_files" {
  value = [for file in local_file.managed_files : file.filename]
}
```

### Key Changes:

1.  **Consistent Types in Conditional Expression**:
    *   When `var.env == "prod"`, `local.files_config` (a list of files) is returned.
    *   When `var.env != "prod"`, we now return an empty list (`[]`) instead of an empty map (`{}`).

### Steps to Run:

1.  **Initialize Terraform**:
    
    ```bash
    terraform init
    ```
    
2.  **Run the Plan**:
    
    ```bash
    terraform plan -var="env=dev"
    ```
    
3.  **Apply the Configuration** in production:
    
    ```bash
    terraform apply -var="env=prod"
    ```
    

This should fix the type mismatch error, and your configuration will now work as expected, creating files only when the environment is set to `prod`. Let me know if you encounter any other issues!