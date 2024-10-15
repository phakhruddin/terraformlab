Terraform Lab - Scenario 1
==========================

This repository contains a simple Terraform lab designed to demonstrate the use of local files for configuring resources using **Terraform**. In this scenario, Terraform reads and processes the contents of a local file to provision resources dynamically.

Table of Contents
-----------------

1.  [Overview](#overview)
2.  [Prerequisites](#prerequisites)
3.  [Lab Structure](#lab-structure)
4.  [How to Run](#how-to-run)
5.  [Expected Output](#expected-output)
6.  [Clean Up](#clean-up)
7.  [Troubleshooting](#troubleshooting)

Overview
--------

In this scenario, Terraform is used to read a local file containing key-value data. Based on the file contents, Terraform provisions resources dynamically. The primary objective of this lab is to showcase how Terraform interacts with local files and uses them for infrastructure provisioning.

### Key Concepts Demonstrated:

*   Reading local files using the `local_file` data source.
*   Dynamic resource creation based on the contents of the local file.
*   Applying Terraform best practices for modular infrastructure provisioning.

Prerequisites
-------------

Before you can run this lab, ensure that you have the following:

1.  **Terraform** installed. You can download it here.
2.  **AWS CLI** configured, if using AWS resources.
3.  A basic understanding of **Terraform** and **HCL** (HashiCorp Configuration Language).

Lab Structure
-------------

```bash
terraformlab/
├── main.tf                # Primary Terraform configuration file
├── variables.tf           # Input variables for the lab
├── output.tf              # Outputs to display after execution
└── files/
    └── input.txt          # Local file containing input data
```

### Files Description:

*   **main.tf**: The main Terraform configuration file where resources are defined and local files are processed.
*   **variables.tf**: Contains variable definitions, allowing dynamic configuration based on user input.
*   **output.tf**: Defines the outputs after Terraform applies the configuration.
*   **files/input.txt**: A local file containing key-value pairs used by Terraform to configure resources.

How to Run
----------

1.  **Clone the repository**:
    
    ```bash
    git clone https://github.com/phakhruddin/terraformlab.git
    cd terraformlab/local-file/scenario1
    ```
    
2.  **Initialize Terraform**: Initialize the working directory and download the required providers:
    
    ```bash
    terraform init
    ```
    
3.  **Plan the infrastructure**: Preview the changes that will be applied based on the local file inputs:
    
    ```bash
    terraform plan
    ```
    
4.  **Apply the configuration**: Create the infrastructure based on the input file:
    
    ```bash
    terraform apply
    ```
    
5.  **Provide confirmation** when prompted by typing `yes`.
    

Expected Output
---------------

Once the configuration is applied, you should see output related to the created resources, which were dynamically created based on the contents of the local file (`files/input.txt`). You can expect the following:

*   List of resources provisioned.
*   Outputs defined in the `output.tf` file, which may include resource IDs, IP addresses, or any other relevant data.

Clean Up
--------

To avoid any unnecessary charges or to clean up your environment, you can destroy the resources that were created by Terraform:

```bash
terraform destroy
```

Confirm with `yes` when prompted to delete the resources.

Troubleshooting
---------------

### Common Issues:

1.  **File Not Found**: Ensure that the `input.txt` file exists in the correct location (`files/input.txt`). If the file is missing or misnamed, Terraform will fail to read it.
    
2.  **Incorrect AWS Configuration**: If you're using AWS resources, ensure that your AWS CLI is properly configured. Run `aws configure` to set up your credentials.
    
3.  **Terraform Init Fails**: Ensure that your internet connection is stable, and that you have write access to the working directory.
    

* * *

For further information, feel free to explore the Terraform documentation. If you encounter any issues or have questions, feel free to open an issue in this repository.