🚀 **Next Steps: Integrating Azure Function to Write Data to Cosmos DB (MongoDB API)**


---

## **🛠 Plan**
1. **Create an Azure Function** (Python-based) that listens to HTTP requests.
2. **Parse incoming JSON data** and write it to **Cosmos DB**.
3. **Deploy the function** using **Terraform** and store the function code in **Azure Blob Storage**.
4. **Test the Function** via `curl` or a REST client.

---

## **📌 Terraform Configuration**
We will create:
- **Azure Function App** (`func-write-cosmos`)
- **Blob Storage** for function deployment
- **Function Code** to insert data into CosmosDB

### **1️⃣ Deploy Infrastructure with Terraform**
Add this to your **Terraform `main.tf`**:

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "cosmos_rg" {
  name     = "cosmos-resource-group"
  location = "West US 2"
}

resource "azurerm_storage_account" "func_storage" {
  name                     = "funcstoragewrite"
  resource_group_name      = azurerm_resource_group.cosmos_rg.name
  location                 = azurerm_resource_group.cosmos_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "func_container" {
  name                  = "function-code"
  storage_account_name  = azurerm_storage_account.func_storage.name
  container_access_type = "private"
}

resource "azurerm_service_plan" "function_plan" {
  name                = "func-write-plan"
  resource_group_name = azurerm_resource_group.cosmos_rg.name
  location            = azurerm_resource_group.cosmos_rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
}

resource "azurerm_linux_function_app" "func_write" {
  name                       = "func-write-cosmos"
  resource_group_name        = azurerm_resource_group.cosmos_rg.name
  location                   = azurerm_resource_group.cosmos_rg.location
  service_plan_id            = azurerm_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key
  app_settings = {
    "COSMOS_CONNECTION_STRING" = azurerm_cosmosdb_account.cosmos_account.primary_master_key
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "AzureWebJobsStorage"      = azurerm_storage_account.func_storage.primary_connection_string
  }
}

resource "azurerm_storage_blob" "function_code_blob" {
  name                   = "write-function.zip"
  storage_account_name   = azurerm_storage_account.func_storage.name
  storage_container_name = azurerm_storage_container.func_container.name
  type                   = "Block"
  source                 = "write-function.zip"  # Ensure this zip exists locally before running terraform apply
}
```

---

### **2️⃣ Function Code (Python)**
Create the **Azure Function app code** in a folder called `write-function`:

**`write-function/__init__.py`**
```python
import logging
import azure.functions as func
import pymongo
import os
import json

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Received a request to insert data into Cosmos DB.")

    try:
        req_body = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid JSON payload", status_code=400)

    connection_string = os.environ["COSMOS_CONNECTION_STRING"]
    client = pymongo.MongoClient(connection_string)
    database = client["deen-mongo-db"]
    collection = database["deen-collection"]

    collection.insert_one(req_body)
    
    return func.HttpResponse(f"Data inserted: {json.dumps(req_body)}", status_code=200)
```

**`write-function/requirements.txt`**
```
azure-functions
pymongo[srv]
```

**Zip the function:**
```sh
cd write-function
zip -r ../write-function.zip .
cd ..
```

---

### **3️⃣ Apply Terraform**
Now, deploy everything:
```sh
terraform init
terraform apply -auto-approve
```

---

```sh
terraform apply --auto-approve
azurerm_resource_group.cosmos_rg: Refreshing state... [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/cosmos-resource-group]
azurerm_cosmosdb_account.cosmos_account: Refreshing state... [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/cosmos-resource-group/providers/Microsoft.DocumentDB/databaseAccounts/deen-cosmos-account]
azurerm_cosmosdb_mongo_database.cosmos_db: Refreshing state... [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/cosmos-resource-group/providers/Microsoft.DocumentDB/databaseAccounts/deen-cosmos-account/mongodbDatabases/deen-mongo-db]
data.azurerm_cosmosdb_account.cosmos_conn: Reading...
azurerm_cosmosdb_mongo_collection.cosmos_collection: Refreshing state... [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/cosmos-resource-group/providers/Microsoft.DocumentDB/databaseAccounts/deen-cosmos-account/mongodbDatabases/deen-mongo-db/collections/deen-collection]
data.azurerm_cosmosdb_account.cosmos_conn: Read complete after 2s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/cosmos-resource-group/providers/Microsoft.DocumentDB/databaseAccounts/deen-cosmos-account]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_linux_function_app.func_write will be created
  + resource "azurerm_linux_function_app" "func_write" {
      + app_settings                                   = (known after apply)
      + builtin_logging_enabled                        = true
      + client_certificate_enabled                     = false
      + client_certificate_mode                        = "Optional"
      + content_share_force_disabled                   = false
      + custom_domain_verification_id                  = (sensitive value)
      + daily_memory_time_quota                        = 0
      + default_hostname                               = (known after apply)
      + enabled                                        = true
      + ftp_publish_basic_authentication_enabled       = true
      + functions_extension_version                    = "~4"
      + hosting_environment_id                         = (known after apply)
      + https_only                                     = false
      + id                                             = (known after apply)
      + key_vault_reference_identity_id                = (known after apply)
      + kind                                           = (known after apply)
      + location                                       = "westus2"
      + name                                           = "func-write-cosmos"
      + outbound_ip_address_list                       = (known after apply)
      + outbound_ip_addresses                          = (known after apply)
      + possible_outbound_ip_address_list              = (known after apply)
      + possible_outbound_ip_addresses                 = (known after apply)
      + public_network_access_enabled                  = true
      + resource_group_name                            = "cosmos-resource-group"
      + service_plan_id                                = (known after apply)
      + site_credential                                = (sensitive value)
      + storage_account_access_key                     = (sensitive value)
      + storage_account_name                           = "funcstoragewrite"
      + storage_uses_managed_identity                  = false
      + vnet_image_pull_enabled                        = false
      + webdeploy_publish_basic_authentication_enabled = true
      + zip_deploy_file                                = (known after apply)

      + site_config {
          + always_on                               = (known after apply)
          + app_scale_limit                         = (known after apply)
          + container_registry_use_managed_identity = false
          + default_documents                       = (known after apply)
          + detailed_error_logging_enabled          = (known after apply)
          + elastic_instance_minimum                = (known after apply)
          + ftps_state                              = "Disabled"
          + http2_enabled                           = false
          + ip_restriction_default_action           = "Allow"
          + linux_fx_version                        = (known after apply)
          + load_balancing_mode                     = "LeastRequests"
          + managed_pipeline_mode                   = "Integrated"
          + minimum_tls_version                     = "1.2"
          + pre_warmed_instance_count               = (known after apply)
          + remote_debugging_enabled                = false
          + remote_debugging_version                = (known after apply)
          + scm_ip_restriction_default_action       = "Allow"
          + scm_minimum_tls_version                 = "1.2"
          + scm_type                                = (known after apply)
          + scm_use_main_ip_restriction             = false
          + use_32_bit_worker                       = false
          + vnet_route_all_enabled                  = false
          + websockets_enabled                      = false
          + worker_count                            = (known after apply)

          + application_stack {
              + python_version              = "3.8"
              + use_dotnet_isolated_runtime = false
            }
        }
    }

  # azurerm_service_plan.function_plan will be created
  + resource "azurerm_service_plan" "function_plan" {
      + id                              = (known after apply)
      + kind                            = (known after apply)
      + location                        = "westus2"
      + maximum_elastic_worker_count    = (known after apply)
      + name                            = "func-write-plan"
      + os_type                         = "Linux"
      + per_site_scaling_enabled        = false
      + premium_plan_auto_scale_enabled = false
      + reserved                        = (known after apply)
      + resource_group_name             = "cosmos-resource-group"
      + sku_name                        = "Y1"
      + worker_count                    = (known after apply)
    }

  # azurerm_storage_account.func_storage will be created
  + resource "azurerm_storage_account" "func_storage" {
      + access_tier                        = (known after apply)
      + account_kind                       = "StorageV2"
      + account_replication_type           = "LRS"
      + account_tier                       = "Standard"
      + allow_nested_items_to_be_public    = true
      + cross_tenant_replication_enabled   = false
      + default_to_oauth_authentication    = false
      + dns_endpoint_type                  = "Standard"
      + https_traffic_only_enabled         = true
      + id                                 = (known after apply)
      + infrastructure_encryption_enabled  = false
      + is_hns_enabled                     = false
      + large_file_share_enabled           = (known after apply)
      + local_user_enabled                 = true
      + location                           = "westus2"
      + min_tls_version                    = "TLS1_2"
      + name                               = "funcstoragewrite"
      + nfsv3_enabled                      = false
      + primary_access_key                 = (sensitive value)
      + primary_blob_connection_string     = (sensitive value)
      + primary_blob_endpoint              = (known after apply)
      + primary_blob_host                  = (known after apply)
      + primary_blob_internet_endpoint     = (known after apply)
      + primary_blob_internet_host         = (known after apply)
      + primary_blob_microsoft_endpoint    = (known after apply)
      + primary_blob_microsoft_host        = (known after apply)
      + primary_connection_string          = (sensitive value)
      + primary_dfs_endpoint               = (known after apply)
      + primary_dfs_host                   = (known after apply)
      + primary_dfs_internet_endpoint      = (known after apply)
      + primary_dfs_internet_host          = (known after apply)
      + primary_dfs_microsoft_endpoint     = (known after apply)
      + primary_dfs_microsoft_host         = (known after apply)
      + primary_file_endpoint              = (known after apply)
      + primary_file_host                  = (known after apply)
      + primary_file_internet_endpoint     = (known after apply)
      + primary_file_internet_host         = (known after apply)
      + primary_file_microsoft_endpoint    = (known after apply)
      + primary_file_microsoft_host        = (known after apply)
      + primary_location                   = (known after apply)
      + primary_queue_endpoint             = (known after apply)
      + primary_queue_host                 = (known after apply)
      + primary_queue_microsoft_endpoint   = (known after apply)
      + primary_queue_microsoft_host       = (known after apply)
      + primary_table_endpoint             = (known after apply)
      + primary_table_host                 = (known after apply)
      + primary_table_microsoft_endpoint   = (known after apply)
      + primary_table_microsoft_host       = (known after apply)
      + primary_web_endpoint               = (known after apply)
      + primary_web_host                   = (known after apply)
      + primary_web_internet_endpoint      = (known after apply)
      + primary_web_internet_host          = (known after apply)
      + primary_web_microsoft_endpoint     = (known after apply)
      + primary_web_microsoft_host         = (known after apply)
      + public_network_access_enabled      = true
      + queue_encryption_key_type          = "Service"
      + resource_group_name                = "cosmos-resource-group"
      + secondary_access_key               = (sensitive value)
      + secondary_blob_connection_string   = (sensitive value)
      + secondary_blob_endpoint            = (known after apply)
      + secondary_blob_host                = (known after apply)
      + secondary_blob_internet_endpoint   = (known after apply)
      + secondary_blob_internet_host       = (known after apply)
      + secondary_blob_microsoft_endpoint  = (known after apply)
      + secondary_blob_microsoft_host      = (known after apply)
      + secondary_connection_string        = (sensitive value)
      + secondary_dfs_endpoint             = (known after apply)
      + secondary_dfs_host                 = (known after apply)
      + secondary_dfs_internet_endpoint    = (known after apply)
      + secondary_dfs_internet_host        = (known after apply)
      + secondary_dfs_microsoft_endpoint   = (known after apply)
      + secondary_dfs_microsoft_host       = (known after apply)
      + secondary_file_endpoint            = (known after apply)
      + secondary_file_host                = (known after apply)
      + secondary_file_internet_endpoint   = (known after apply)
      + secondary_file_internet_host       = (known after apply)
      + secondary_file_microsoft_endpoint  = (known after apply)
      + secondary_file_microsoft_host      = (known after apply)
      + secondary_location                 = (known after apply)
      + secondary_queue_endpoint           = (known after apply)
      + secondary_queue_host               = (known after apply)
      + secondary_queue_microsoft_endpoint = (known after apply)
      + secondary_queue_microsoft_host     = (known after apply)
      + secondary_table_endpoint           = (known after apply)
      + secondary_table_host               = (known after apply)
      + secondary_table_microsoft_endpoint = (known after apply)
      + secondary_table_microsoft_host     = (known after apply)
      + secondary_web_endpoint             = (known after apply)
      + secondary_web_host                 = (known after apply)
      + secondary_web_internet_endpoint    = (known after apply)
      + secondary_web_internet_host        = (known after apply)
      + secondary_web_microsoft_endpoint   = (known after apply)
      + secondary_web_microsoft_host       = (known after apply)
      + sftp_enabled                       = false
      + shared_access_key_enabled          = true
      + table_encryption_key_type          = "Service"
    }

  # azurerm_storage_blob.function_code_blob will be created
  + resource "azurerm_storage_blob" "function_code_blob" {
      + access_tier            = (known after apply)
      + content_type           = "application/octet-stream"
      + id                     = (known after apply)
      + metadata               = (known after apply)
      + name                   = "write-function.zip"
      + parallelism            = 8
      + size                   = 0
      + source                 = "write-function.zip"
      + storage_account_name   = "funcstoragewrite"
      + storage_container_name = "function-code"
      + type                   = "Block"
      + url                    = (known after apply)
    }

  # azurerm_storage_container.func_container will be created
  + resource "azurerm_storage_container" "func_container" {
      + container_access_type             = "private"
      + default_encryption_scope          = (known after apply)
      + encryption_scope_override_enabled = true
      + has_immutability_policy           = (known after apply)
      + has_legal_hold                    = (known after apply)
      + id                                = (known after apply)
      + metadata                          = (known after apply)
      + name                              = "function-code"
      + resource_manager_id               = (known after apply)
      + storage_account_id                = (known after apply)
    }

Plan: 5 to add, 0 to change, 0 to destroy.
azurerm_service_plan.function_plan: Creating...
azurerm_storage_account.func_storage: Creating...
azurerm_service_plan.function_plan: Still creating... [10s elapsed]
azurerm_storage_account.func_storage: Still creating... [10s elapsed]
azurerm_service_plan.function_plan: Creation complete after 15s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/cosmos-resource-group/providers/Microsoft.Web/serverFarms/func-write-plan]
azurerm_storage_account.func_storage: Still creating... [20s elapsed]
azurerm_storage_account.func_storage: Still creating... [30s elapsed]
azurerm_storage_account.func_storage: Still creating... [40s elapsed]
azurerm_storage_account.func_storage: Still creating... [50s elapsed]
azurerm_storage_account.func_storage: Still creating... [1m0s elapsed]
azurerm_storage_account.func_storage: Still creating... [1m10s elapsed]
azurerm_storage_account.func_storage: Creation complete after 1m11s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/cosmos-resource-group/providers/Microsoft.Storage/storageAccounts/funcstoragewrite]
azurerm_storage_container.func_container: Creating...
azurerm_linux_function_app.func_write: Creating...
azurerm_storage_container.func_container: Creation complete after 2s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/cosmos-resource-group/providers/Microsoft.Storage/storageAccounts/funcstoragewrite/blobServices/default/containers/function-code]
azurerm_storage_blob.function_code_blob: Creating...
azurerm_storage_blob.function_code_blob: Creation complete after 1s [id=https://funcstoragewrite.blob.core.windows.net/function-code/write-function.zip]
azurerm_linux_function_app.func_write: Still creating... [10s elapsed]
azurerm_linux_function_app.func_write: Still creating... [20s elapsed]
azurerm_linux_function_app.func_write: Still creating... [30s elapsed]
azurerm_linux_function_app.func_write: Still creating... [40s elapsed]
azurerm_linux_function_app.func_write: Still creating... [50s elapsed]
azurerm_linux_function_app.func_write: Still creating... [1m0s elapsed]
azurerm_linux_function_app.func_write: Still creating... [1m10s elapsed]
azurerm_linux_function_app.func_write: Still creating... [1m20s elapsed]
azurerm_linux_function_app.func_write: Still creating... [1m30s elapsed]
azurerm_linux_function_app.func_write: Creation complete after 1m30s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/cosmos-resource-group/providers/Microsoft.Web/sites/func-write-cosmos]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

---

### **4️⃣ Test the Function**
Once the deployment is done, get the **function URL**:
```sh
az functionapp function show \
  --name func-write-cosmos \
  --resource-group cosmos-resource-group \
  --query "invokeUrlTemplate" -o tsv
```

#### **Send a test request**
```sh
curl -X POST "https://func-write-cosmos.azurewebsites.net/api/insert" \
     -H "Content-Type: application/json" \
     -d '{"name": "Azure Function", "type": "demo"}'
```

---

### **🚀 What's Next?**
✅ **Verify Data in Cosmos DB**
Run:
```sh
mongosh "mongodb://adminuser:YourPassword@deen-cosmos-account.mongo.cosmos.azure.com:10255/?tls=true&replicaSet=globaldb&retrywrites=false" --eval 'db.deen-collection.find().pretty()'
```

---
## ✅ **📚 References**
- [Terraform](https://www.terraform.io/)
- [Azure Functions](https://azure.microsoft.com/en-us/services/functions/)
- [Azure Cosmos DB](https://azure.microsoft.com/en-us/services/cosmos-db/)
- [Azure Blob Storage](https://azure.microsoft.com/en-us/services/storage/blobs/)
- [Azure Functions Python](https://azure.microsoft.com/en-us/products/functions/)
-  [Azure Cosmos DB – Python](https://github.com/Azure/azure-sdk-for-python/tree/master/sdk/cosmos/azure-cosmos)
-  [Azure Cosmos DB – Python](https://github.com/Azure/azure-sdk-for-python/tree/master/sdk/cosmos/azure-cosmos)
-  [Azure Cosmos DB – Python](https://github.com/Azure/azure-sdk-for-python/tree/master/sdk/cosmos/azure-cosmos)
-   [Azure Cosmos DB – 101](https://docs.microsoft.com/en-us/azure/cosmos-db/introduction)
-    [Azure Cosmos DB – 102](https://docs.microsoft.com/en-us/azure/cosmos-db/sql-api-introduction)