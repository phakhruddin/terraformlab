provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = false
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://localhost:4566"
    apigatewayv2   = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    ec2            = "http://localhost:4566"
    es             = "http://localhost:4566"
    elasticache    = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    rds            = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    route53        = "http://localhost:4566"
    s3             = "http://s3.localhost.localstack.cloud:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "test-bucket" {
  bucket = "my-bucket-1"
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
  for_each = { for buckets in local.bucket_config : buckets.name => buckets }
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

  bucket = each.key
  key    = each.value[0].destination
  source = each.value[0].source
}


# Output the bucket names
#output "s3_bucket_names" {
#  value = aws_s3_bucket.buckets[*].bucket
#}
