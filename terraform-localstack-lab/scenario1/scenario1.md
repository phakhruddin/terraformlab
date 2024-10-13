### Terraform Lab: Creating Multiple S3 Buckets and Copying Objects Using `for_each` with YAML Input

This lab will guide you through creating multiple **S3 buckets** and copying objects into each bucket using **Terraform**. The buckets and objects will be dynamically defined in a YAML file, and Terraform will use the `for_each` loop to provision them.

### Lab Objectives:

1.  Use a **YAML file** to define multiple S3 buckets and their respective objects.
2.  Use the **`for_each`** loop in Terraform to create these S3 buckets and copy objects into them.
3.  Apply and validate the setup using AWS S3.

* * *

Step 1: Prerequisites
---------------------

Ensure you have the following:

*   **Terraform**: Installed on your local machine.
    
    ```bash
    brew install terraform
    ```
    
*   **AWS CLI**: Installed and configured on your machine for accessing your AWS account.
    
    ```bash
    aws configure
    ```
    

* * *

Step 2: Create the YAML Input File
----------------------------------

This YAML file defines multiple S3 buckets and the objects to copy into each bucket.

### File: `s3_buckets.yaml`

```yaml
buckets:
  - name: "my-bucket-1"
    region: "us-east-1"
    objects:
      - source: "./files/file1.txt"
        destination: "file1.txt"
  - name: "my-bucket-2"
    region: "us-west-1"
    objects:
      - source: "./files/file2.txt"
        destination: "file2.txt"
  - name: "my-bucket-3"
    region: "us-east-2"
    objects:
      - source: "./files/file3.txt"
        destination: "file3.txt"
```

This YAML file defines:

*   Multiple S3 buckets (`my-bucket-1`, `my-bucket-2`, etc.).
*   Each bucket can have one or more objects that need to be copied from local storage to the S3 bucket.

* * *

Step 3: Create the Terraform Configuration
------------------------------------------

The following Terraform configuration uses the YAML file as input, creates the S3 buckets, and uploads objects to each bucket.

### File: `main.tf`

```hcl
provider "aws" {
  region = "us-east-1"  # Default region
}

# Read the YAML file
data "local_file" "s3_yaml" {
  filename = "${path.module}/s3_buckets.yaml"
}

# Parse YAML to extract bucket information
locals {
  bucket_config = yamldecode(data.local_file.s3_yaml.content).buckets
}

# Create S3 buckets
resource "aws_s3_bucket" "buckets" {
  for_each = { for bucket in local.bucket_config : bucket.name => bucket }

  bucket = each.value.name

  tags = {
    Name = each.value.name
    Environment = "Terraform Lab"
  }
}

# Upload objects to each bucket
resource "aws_s3_object" "objects" {
  for_each = { 
    for bucket in local.bucket_config : 
    bucket.name => bucket.objects 
  }

  for object in each.value : object.source => object

  bucket = each.key
  key    = object.destination
  source = object.source
}

# Output the bucket names
output "s3_bucket_names" {
  value = aws_s3_bucket.buckets[*].bucket
}
```

### Explanation:

1.  **YAML Decoding**:
    
    *   The `data "local_file"` block reads the YAML file (`s3_buckets.yaml`).
    *   The `yamldecode()` function parses the YAML content into a usable format in Terraform.
2.  **`for_each` Loop**:
    
    *   The `aws_s3_bucket` resource block uses the `for_each` loop to iterate through each bucket defined in the YAML file.
    *   The `aws_s3_object` resource block loops over the objects within each bucket and copies them into the respective S3 bucket.

* * *

Step 4: Set Up Local Files
--------------------------

Before applying the Terraform configuration, ensure you have the files you want to upload. Create a `files` directory and add some files to it:

```bash
mkdir files
echo "This is file 1" > files/file1.txt
echo "This is file 2" > files/file2.txt
echo "This is file 3" > files/file3.txt
```

* * *

Step 5: Initialize and Apply the Terraform Configuration
--------------------------------------------------------

1.  **Initialize Terraform**: Initialize the Terraform working directory, which downloads the necessary providers:
    
    ```bash
    terraform init
    ```
    
2.  **Apply the Configuration**: Run `terraform apply` to create the S3 buckets and copy the files into the buckets:
    
    ```bash
    terraform apply
    ```
    
    Confirm with `yes` when prompted.
    

* * *

Step 6: Verify the Setup
------------------------

After the Terraform run is complete, verify that the S3 buckets and files have been created:

1.  **List the S3 Buckets**:
    
    ```bash
    aws s3 ls
    ```
    
    You should see the created buckets (`my-bucket-1`, `my-bucket-2`, and `my-bucket-3`).
    
2.  **Verify the Objects in Each Bucket**:
    
    ```bash
    aws s3 ls s3://my-bucket-1
    aws s3 ls s3://my-bucket-2
    aws s3 ls s3://my-bucket-3
    ```
    
    Ensure that the corresponding files (`file1.txt`, `file2.txt`, `file3.txt`) are present in their respective buckets.
    

* * *

Step 7: Clean Up Resources
--------------------------

Once you're done testing, you can clean up the created S3 buckets and objects by running:

```bash
terraform destroy
```

* * *

Conclusion
----------

This lab demonstrates how to use **Terraform** with **YAML** inputs to dynamically create multiple **S3 buckets** and copy objects into those buckets using the `for_each` loop. This setup is ideal for scenarios where you need to provision multiple resources based on external configuration files like YAML.