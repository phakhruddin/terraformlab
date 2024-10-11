Terraform Lab Testing Guide
===========================

This repository contains a collection of Terraform modules and testing logic that demonstrate how to provision infrastructure, configure resources using user-input YAML files, and test Terraform's functionality in different scenarios. The modules are designed to cover various use cases, including Kubernetes deployments, cloud resources provisioning, and dynamic configuration using the `for_each` loop with YAML inputs.

* * *

Table of Contents
-----------------

1.  [Introduction](#introduction)
2.  [Prerequisites](#prerequisites)
3.  [Directory Structure](#directory-structure)
4.  [Scenarios Overview](#scenarios-overview)
5.  [Testing Modules and Logic](#testing-modules-and-logic)
    *   [Scenario 1: YAML Input Validation](#scenario-1-yaml-input-validation)
    *   [Scenario 2: Resource Creation from YAML Input](#scenario-2-resource-creation-from-yaml-input)
    *   [Scenario 3: Idempotency Test with YAML Updates](#scenario-3-idempotency-test-with-yaml-updates)
    *   [Scenario 4: Handling Invalid YAML Files](#scenario-4-handling-invalid-yaml-files)
    *   [Scenario 5: Remote YAML Integration](#scenario-5-remote-yaml-integration)
6.  [Running the Tests](#running-the-tests)
7.  [Cleaning Up Resources](#cleaning-up-resources)
8.  [Conclusion](#conclusion)

* * *

Introduction
------------

This lab is designed to help you practice and test different aspects of Terraform configuration using real-world scenarios. The focus is on using Terraform to manage infrastructure and configure resources based on user-input YAML files, leveraging the `for_each` loop, and automating resource creation dynamically. The tests cover common scenarios encountered in infrastructure management.

Prerequisites
-------------

Ensure you have the following installed on your machine:

*   Terraform
*   Kubernetes
*   Minikube (if using local Kubernetes)
*   Docker (optional for running containers)

Directory Structure
-------------------

```bash
terraform-lab/
├── modules/
│   └── kubernetes-pod/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── test/
│   ├── test_scenario_1.md
│   ├── test_scenario_2.md
│   ├── test_scenario_3.md
│   ├── test_scenario_4.md
│   └── test_scenario_5.md
├── terraform.tfvars
├── README.md
└── pods_config.yaml
```

### Key Directories:

*   `modules/`: Contains reusable Terraform modules. The `kubernetes-pod` module provisions Kubernetes pods based on user input.
*   `test/`: Contains markdown files that describe how to test each scenario, with detailed instructions and expected outcomes.
*   `terraform.tfvars`: Variables file to manage input variables for the Terraform configuration.
*   `pods_config.yaml`: The YAML file used as input for Kubernetes pod creation.

* * *

Scenarios Overview
------------------

Each scenario demonstrates a specific use case of the Terraform module. These scenarios use different configurations, testing various parts of the module to ensure that the logic behaves correctly with different inputs.

* * *

Testing Modules and Logic
-------------------------

### Scenario 1: YAML Input Validation

This scenario tests whether the Terraform module can correctly parse and validate the user-input YAML file.

*   **Objective**: Ensure that valid YAML files are parsed correctly, and invalid files are rejected.
*   **Key Files**:
    *   `pods_config.yaml`
    *   `main.tf`
*   **Expected Outcome**: Terraform should validate the input and reject any malformed YAML file with an appropriate error message.
*   **Instructions**: Scenario 1 Detailed Steps

### Scenario 2: Resource Creation from YAML Input

In this scenario, Terraform reads the YAML input file to create Kubernetes pods dynamically.

*   **Objective**: Verify that the module creates resources as described in the YAML file.
*   **Key Files**:
    *   `main.tf`
    *   `pods_config.yaml`
*   **Expected Outcome**: Terraform should create Kubernetes pods with the specifications from the YAML file.
*   **Instructions**: Scenario 2 Detailed Steps

### Scenario 3: Idempotency Test with YAML Updates

This test focuses on ensuring that Terraform is idempotent when updating resources based on changes in the YAML file.

*   **Objective**: Ensure that only changes in the YAML file are applied, without recreating the resources unnecessarily.
*   **Key Files**:
    *   `pods_config.yaml`
    *   `main.tf`
*   **Expected Outcome**: Terraform applies only changes, keeping the rest of the resource configuration intact.
*   **Instructions**: Scenario 3 Detailed Steps

### Scenario 4: Handling Invalid YAML Files

This scenario tests how the module handles invalid YAML files, such as those with missing parameters or syntax errors.

*   **Objective**: Ensure Terraform gracefully handles YAML syntax errors and missing required fields.
*   **Key Files**:
    *   `invalid_pods_config.yaml`
    *   `main.tf`
*   **Expected Outcome**: Terraform should return an error indicating the issues in the YAML file.
*   **Instructions**: Scenario 4 Detailed Steps

### Scenario 5: Remote YAML Integration

In this scenario, the YAML file is stored in a remote location, such as an S3 bucket or a public URL, and Terraform fetches it to create resources.

*   **Objective**: Validate that the module can read and use remote YAML files to create resources.
*   **Key Files**:
    *   `remote_config.yaml`
    *   `main.tf`
*   **Expected Outcome**: Terraform should successfully fetch the YAML file and create the necessary resources.
*   **Instructions**: Scenario 5 Detailed Steps

* * *

Running the Tests
-----------------

1.  **Initialize Terraform**:
    
    ```bash
    terraform init
    ```
    
2.  **Validate the Configuration**:
    
    ```bash
    terraform validate
    ```
    
3.  **Apply the Terraform Plan**:
    
    ```bash
    terraform apply
    ```
    
4.  **Check the Results**:
    
    *   Use `kubectl` to verify the created pods.
    
    ```bash
    kubectl get pods
    ```
    

### Testing with Terratest (Optional)

*   For more automated testing, you can use Terratest to create Go-based tests for the Terraform modules. Instructions for setting this up are provided in each test scenario.

* * *

Cleaning Up Resources
---------------------

To clean up all the resources created by the tests, run:

```bash
terraform destroy
```

This will ensure that all Kubernetes pods and any other resources provisioned by the module are removed.

* * *

Conclusion
----------


This Terraform lab provides a comprehensive guide to testing modules that read YAML files and dynamically create resources. It allows you to practice real-world scenarios, ensuring that your Terraform logic works as expected in different cases.


## Additional Notes

Create a `.gitignore` file that ignores all `.terraform` directories or files across all directories and subdirectories.

```gitignore
# Ignore all .terraform directories and any file or directory that starts with .terraform
**/.terraform*
```

### Explanation:

*   `**/.terraform*`: This will match any `.terraform` directory or file that starts with `.terraform` (e.g., `.terraform.lock.hcl`) in all directories and their subdirectories.

You can place this `.gitignore` file in the root of your repository to ensure Terraform-related local state, provider plugins, and lock files do not get committed to version control.

### Additional Considerations:

You might also want to ignore other files like Terraform plan files (`*.tfplan`) or auto-generated state files (`*.tfstate`) that you don’t want to track:

```gitignore
# Ignore Terraform state files
*.tfstate
*.tfstate.backup

# Ignore Terraform plan files
*.tfplan

# Ignore the .terraform directory and files
**/.terraform*
```

This ensures you keep your repository clean from temporary or generated Terraform files while still committing essential configuration files (`*.tf`, `*.tfvars` files).
