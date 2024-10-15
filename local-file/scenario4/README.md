Terraform Lab - Scenario 4 (with Modules and `can` Condition)
=============================================================

This repository contains **Scenario 4**, which builds upon previous scenarios by introducing **modules** and using the **`can` function** to handle cases where the `file_permission` value is empty or missing. This scenario enhances flexibility and reusability while ensuring proper file permission management.

Table of Contents
-----------------

1.  [Overview](#overview)
2.  [Prerequisites](#prerequisites)
3.  [YAML Input File](#yaml-input-file)
4.  [Module Structure](#module-structure)
5.  [Main Terraform Configuration](#main-terraform-configuration)
6.  [How to Run](#how-to-run)
7.  [Expected Output](#expected-output)
8.  [Clean Up](#clean-up)
9.  [Troubleshooting](#troubleshooting)

* * *

Overview
--------

This scenario introduces:

*   **Modules**: Reusable Terraform code encapsulated in a module to handle file creation.
*   **`can` function**: Used to handle cases where the `file_permission` field in the YAML file is missing or empty. If no permission is specified, a default value will be applied.

* * *

Prerequisites
-------------

Ensure you have the following:

1.  **Terraform**: Installed on your local machine.
    
    ```bash
    brew install terraform
    ```
    
2.  **YAML file**: Define the file names and permissions as described below.
3.  **Basic understanding of Terraform and Modules**.

* * *

YAML Input File
---------------

Create a YAML file (`files_config.yaml`) in the `files/` directory that defines the files and their respective permissions.

### File: `files/files_config.yaml`

```yaml
files:
  - name: "config-prod.txt"
    permission: "600"
  - name: "secrets-prod.txt"
    permission: ""  # Missing or empty permission
```

* * *

Module Structure
----------------

Create a module that will handle the creation of files. The module will accept the file name, content, and permission, and it will use a default permission value if the permission is missing or empty.

### File: `modules/file_creator/main.tf`

```hcl
# Module to create a file with given filename, content, and permission
resource "local_file" "file" {
  filename       = "${path.module}/../../result/${var.filename}"
  content        = var.content
  file_permission = var.permission
}
```

### File: `modules/file_creator/variables.tf`

```hcl
variable "filename" {
  description = "The name of the file to be created"
  type        = string
}

variable "content" {
  description = "Content to be written to the file"
  type        = string
}

variable "permission" {
  description = "The permission of the file"
  type        = string
  default     = "644"  # Default file permission
}
```

### File: `modules/file_creator/outputs.tf`

```hcl
output "created_file" {
  value = local_file.file.filename
}
```

* * *

Main Terraform Configuration
----------------------------

### File: `main.tf`

```hcl
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

# Outputs
output "created_files" {
  value = [for file in module.file_creator : file.value["created_file"]]
}
```

### Explanation:

1.  **Module Usage**: The `file_creator` module is called for each file, allowing the file creation logic to be modular and reusable.
2.  **`can` Function**: The `permission` argument uses the `can()` function to check if the `file_permission` value is valid:
    *   If the `permission` value is missing, empty, or invalid, it defaults to `"644"`.
    *   `trimspace()` ensures that even if the permission is an empty string (e.g., `" "`), it defaults to `"644"`.

* * *

How to Run
----------

1.  **Create the Subdirectory**: Ensure that the `result/` subdirectory exists where the files will be created:
    
    ```bash
    mkdir -p result
    ```
    
2.  **Initialize Terraform**: Initialize the working directory by running:
    
    ```bash
    terraform init
    ```
    
3.  **Run the Plan**:
    
    *   For `dev` environment (no files created):
        
        ```bash
        terraform plan -var="env=dev"
        ```
        
    *   For `prod` environment (files created):
        
        ```bash
        terraform plan -var="env=prod"
        ```
        
4.  **Apply the Configuration**: Apply the configuration and create the files in the `prod` environment:
    
    ```bash
    terraform apply -var="env=prod"
    ```
    

* * *

Expected Output
---------------

*   **In a `prod` environment**: Files will be created in the `result/` directory with permissions:
    *   `config-prod.txt` with permission `600`.
    *   `secrets-prod.txt` with default permission `644` (since the YAML entry was empty).
    *   `default-permissions.txt` with default permission `644` (since the YAML entry was null).

### Example Output:

```bash
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:
created_files = [
  "/path/to/project/result/config-prod.txt",
  "/path/to/project/result/secrets-prod.txt",
  "/path/to/project/result/default-permissions.txt"
]
```

* * *

Clean Up
--------

To clean up the created files, run the following command:

```bash
terraform destroy -var="env=prod"
```

This will remove all resources created by Terraform.

* * *

Troubleshooting
---------------

*   **File Not Created in `prod`**:
    
    *   Ensure the environment variable is explicitly set to `prod` when applying the configuration:
        
        ```bash
        terraform apply -var="env=prod"
        ```
        
*   **Directory Missing**:
    
    *   Ensure the `result/` subdirectory exists before running Terraform:
        
        ```bash
        mkdir -p result
        ```
        

* * *

### Conclusion

In **Scenario 4**, we introduced the use of **modules** and the **`can` function** to handle cases where file permissions are missing or empty. The use of modules promotes reusability, and the `can` function ensures robustness by allowing default values to be applied in case of missing or invalid inputs.