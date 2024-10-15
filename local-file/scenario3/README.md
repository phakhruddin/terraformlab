Terraform Lab - Scenario 3 (condition within for_each)
=============================================================

In **Scenario 3**, we build upon **Scenario 2** by adding a condition that ensures files are only created if the environment is set to `prod`. This time, however, the files will be created under a **subdirectory (`result/`)** within the project structure.

Table of Contents
-----------------

1.  [Overview](#overview)
2.  [Prerequisites](#prerequisites)
3.  [YAML Input File](#yaml-input-file)
4.  [Terraform Configuration](#terraform-configuration)
5.  [How to Run](#how-to-run)
6.  [Expected Output](#expected-output)
7.  [Clean Up](#clean-up)
8.  [Troubleshooting](#troubleshooting)

* * *

Overview
--------

This scenario introduces:

*   **Conditional logic** in the `for_each` loop to ensure files are only created in a `prod` environment.
*   **Subdirectory file creation**: Files will be created in the `result/` subdirectory based on the `env` variable.

### Key Concepts:

*   **YAML parsing**: Reading file names and permissions from a YAML input file.
*   **Conditional logic in `for_each`**: Ensuring resources are created only if `env=prod`.
*   **File creation in a subdirectory**: The files will be placed in the `result/` subdirectory.

* * *

Prerequisites
-------------

Ensure you have the following:

1.  **Terraform**: Installed on your local machine.
    
    ```bash
    brew install terraform
    ```
    
2.  **YAML file**: Define the file names and permissions as described below.
3.  **Basic understanding of Terraform**.

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
    permission: "640"
```

This file contains the names of files and their permissions that will be used to create resources in the `prod` environment.

* * *

Terraform Configuration
-----------------------

In **Scenario 3**, we add a condition directly within the `for_each` expression to control the creation of files based on the `env` variable, and ensure the files are created under the `result/` subdirectory.

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
```

### Explanation of Changes:

1.  **Conditional `for_each`**:
    
    *   The `for_each` loop now includes a condition that checks if `env == "prod"`.
    *   If `env=prod`, it creates files using the parsed YAML data. If not, it returns an empty map `{}`, and no resources are created.
2.  **Subdirectory Creation**:
    
    *   The `filename` attribute has been modified to create the files under the `result/` subdirectory by using `${path.module}/result/${each.value.name}`.
3.  **Outputs**:
    
    *   The `output` block lists the files that were created, but only if `env=prod`.

* * *

How to Run
----------

1.  **Create the Subdirectory**: First, ensure that the `result/` subdirectory exists where the files will be created:
    
    ```bash
    mkdir -p result
    ```
    
2.  **Initialize Terraform**: Initialize the working directory by running the following command:
    
    ```bash
    terraform init
    ```
    
3.  **Run the Plan**:
    
    *   If the environment is set to `dev`, Terraform should not create any files:
        
        ```bash
        terraform plan -var="env=dev"
        ```
        
    *   To simulate production (`env=prod`):
        
        ```bash
        terraform plan -var="env=prod"
        ```
        
4.  **Apply the Configuration**: Run the following command to apply the configuration and create the files:
    
    ```bash
    terraform apply -var="env=prod"
    ```
    

* * *

Expected Output
---------------

*   **In a `prod` environment**: The files listed in the YAML (`config-prod.txt`, `secrets-prod.txt`) will be created under the `result/` subdirectory with the specified permissions.
*   **In a `dev` environment**: No files will be created, and the output will reflect that no resources were provisioned.

### Example Output:

```bash
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
created_files = [
  "/path/to/your/project/result/config-prod.txt",
  "/path/to/your/project/result/secrets-prod.txt",
]
```

* * *

Clean Up
--------

To clean up the created files, run the following command:

```bash
terraform destroy -var="env=prod"
```

This will remove any resources created by Terraform during the lab.

* * *

Troubleshooting
---------------

*   **File Not Created in `prod`**:
    
    *   Ensure that the `env` variable is explicitly set to `prod` when applying the configuration:
        
        ```bash
        terraform apply -var="env=prod"
        ```
        
*   **Directory Missing**:
    
    *   Ensure that the `result/` subdirectory exists before running Terraform:
        
        ```bash
        mkdir -p result
        ```
        
*   **File Permissions**:
    
    *   Make sure the YAML file contains valid permissions for each file (e.g., `"600"` for read-write by owner only).

* * *

### Conclusion

In **Scenario 3**, we introduced conditional logic within the `for_each` loop to create resources only when `env=prod`. We also ensured the files are created under the `result/` subdirectory, demonstrating how to dynamically specify file paths in Terraform. This approach is useful for ensuring that sensitive resources are only created in production environments.
