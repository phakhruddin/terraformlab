### 🚀 **Scenario: Processing Background Tasks with Azure Queue Storage and Azure Function**

## **🛠 Overview**
We will create an **Azure Queue Storage** to store tasks, and an **Azure Function** that listens to the queue and processes the messages. This is useful for **asynchronous processing**, such as:
- **Image processing**
- **Data transformation**
- **Background task execution**

---

## **📌 Plan**
1. **Create an Azure Queue Storage** (to enqueue messages)
2. **Deploy an Azure Function** that triggers on new queue messages
3. **Process the message inside the function**
4. **Test by sending messages and observing logs**
5. **Store function code in Azure Blob Storage**

---

## **1️⃣ Terraform Configuration**
### **Define Infrastructure in `main.tf`**
```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "queue_rg" {
  name     = "queue-resource-group"
  location = "West US 2"
}

# Create Storage Account for Queue
resource "azurerm_storage_account" "queue_storage" {
  name                     = "queueprocessstorage"
  resource_group_name      = azurerm_resource_group.queue_rg.name
  location                 = azurerm_resource_group.queue_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a Queue inside Storage Account
resource "azurerm_storage_queue" "task_queue" {
  name                 = "task-queue"
  storage_account_name = azurerm_storage_account.queue_storage.name
}

# Create Function App Service Plan
resource "azurerm_service_plan" "function_plan" {
  name                = "queue-function-plan"
  resource_group_name = azurerm_resource_group.queue_rg.name
  location            = azurerm_resource_group.queue_rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
}

# Create Function App (without ZIP file upload)
resource "azurerm_linux_function_app" "queue_function" {
  name                       = "func-queue-processor"
  resource_group_name        = azurerm_resource_group.queue_rg.name
  location                   = azurerm_resource_group.queue_rg.location
  service_plan_id            = azurerm_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.queue_storage.name
  storage_account_access_key = azurerm_storage_account.queue_storage.primary_access_key

  app_settings = {
    "AzureWebJobsStorage"       = azurerm_storage_account.queue_storage.primary_connection_string
    "QUEUE_NAME"                = azurerm_storage_queue.task_queue.name
    "FUNCTIONS_WORKER_RUNTIME"  = "python"
  }
}
```
---
Output: 

```sh
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_linux_function_app.queue_function will be created
  + resource "azurerm_linux_function_app" "queue_function" {
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
      + name                                           = "func-queue-processor"
      + outbound_ip_address_list                       = (known after apply)
      + outbound_ip_addresses                          = (known after apply)
      + possible_outbound_ip_address_list              = (known after apply)
      + possible_outbound_ip_addresses                 = (known after apply)
      + public_network_access_enabled                  = true
      + resource_group_name                            = "queue-resource-group"
      + service_plan_id                                = (known after apply)
      + site_credential                                = (sensitive value)
      + storage_account_access_key                     = (sensitive value)
      + storage_account_name                           = "queueprocessstorage"
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

  # azurerm_resource_group.queue_rg will be created
  + resource "azurerm_resource_group" "queue_rg" {
      + id       = (known after apply)
      + location = "westus2"
      + name     = "queue-resource-group"
    }

  # azurerm_service_plan.function_plan will be created
  + resource "azurerm_service_plan" "function_plan" {
      + id                              = (known after apply)
      + kind                            = (known after apply)
      + location                        = "westus2"
      + maximum_elastic_worker_count    = (known after apply)
      + name                            = "queue-function-plan"
      + os_type                         = "Linux"
      + per_site_scaling_enabled        = false
      + premium_plan_auto_scale_enabled = false
      + reserved                        = (known after apply)
      + resource_group_name             = "queue-resource-group"
      + sku_name                        = "Y1"
      + worker_count                    = (known after apply)
    }

  # azurerm_storage_account.queue_storage will be created
  + resource "azurerm_storage_account" "queue_storage" {
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
      + name                               = "queueprocessstorage"
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
      + resource_group_name                = "queue-resource-group"
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

  # azurerm_storage_queue.task_queue will be created
  + resource "azurerm_storage_queue" "task_queue" {
      + id                   = (known after apply)
      + name                 = "task-queue"
      + resource_manager_id  = (known after apply)
      + storage_account_name = "queueprocessstorage"
    }

Plan: 5 to add, 0 to change, 0 to destroy.
azurerm_resource_group.queue_rg: Creating...
azurerm_resource_group.queue_rg: Still creating... [10s elapsed]
azurerm_resource_group.queue_rg: Creation complete after 12s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/queue-resource-group]
azurerm_service_plan.function_plan: Creating...
azurerm_storage_account.queue_storage: Creating...
azurerm_service_plan.function_plan: Still creating... [10s elapsed]
azurerm_storage_account.queue_storage: Still creating... [10s elapsed]
azurerm_service_plan.function_plan: Creation complete after 16s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/queue-resource-group/providers/Microsoft.Web/serverFarms/queue-function-plan]
azurerm_storage_account.queue_storage: Still creating... [20s elapsed]
azurerm_storage_account.queue_storage: Still creating... [30s elapsed]
azurerm_storage_account.queue_storage: Still creating... [40s elapsed]
azurerm_storage_account.queue_storage: Still creating... [50s elapsed]
azurerm_storage_account.queue_storage: Still creating... [1m0s elapsed]
azurerm_storage_account.queue_storage: Creation complete after 1m10s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/queue-resource-group/providers/Microsoft.Storage/storageAccounts/queueprocessstorage]
azurerm_storage_queue.task_queue: Creating...
azurerm_storage_queue.task_queue: Creation complete after 1s [id=https://queueprocessstorage.queue.core.windows.net/task-queue]
azurerm_linux_function_app.queue_function: Creating...
azurerm_linux_function_app.queue_function: Still creating... [10s elapsed]
azurerm_linux_function_app.queue_function: Still creating... [20s elapsed]
azurerm_linux_function_app.queue_function: Still creating... [30s elapsed]
azurerm_linux_function_app.queue_function: Still creating... [40s elapsed]
azurerm_linux_function_app.queue_function: Still creating... [50s elapsed]
azurerm_linux_function_app.queue_function: Still creating... [1m0s elapsed]
azurerm_linux_function_app.queue_function: Still creating... [1m10s elapsed]
azurerm_linux_function_app.queue_function: Still creating... [1m20s elapsed]
azurerm_linux_function_app.queue_function: Still creating... [1m30s elapsed]
azurerm_linux_function_app.queue_function: Creation complete after 1m38s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/queue-resource-group/providers/Microsoft.Web/sites/func-queue-processor]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

---

## **2️⃣ Create Function Locally**
📄 **`queue-function/__init__.py`**
```python
import logging
import azure.functions as func

def main(msg: func.QueueMessage) -> None:
    message_body = msg.get_body().decode('utf-8')
    logging.info(f"Processing task: {message_body}")
```

📄 **`queue-function/function.json`**
```json
{
  "bindings": [
    {
      "name": "msg",
      "type": "queueTrigger",
      "direction": "in",
      "queueName": "task-queue",
      "connection": "AzureWebJobsStorage"
    }
  ]
}
```

 **`queue-function/requirements.txt`**
```
azure-functions
```

---

## **3️⃣ Package Function Locally**
```sh
cd queue-function
zip -r ../queue-function.zip .
cd ..
```

---

## **4️⃣ Deploy Infrastructure with Terraform**
```sh
terraform init
terraform apply -auto-approve
```

---

##5️⃣ Deploy the Function Code Using `az`**
```sh
az functionapp deployment source config-zip \
  --resource-group queue-resource-group \
  --name func-queue-processor \
  --src queue-function.zip
```

---

## 6️⃣ Send a Test Message**
Once deployed, send a message to the queue:
```sh
az storage message put \
  --account-name queueprocessstorage \
  --queue-name task-queue \
  --content "Process this task"
```

Check the **Azure Function Logs**:
```sh
az functionapp log tail --name func-queue-processor --resource-group queue-resource-group
```

---

## **✅ Expected Output**
In logs, you should see:
```
Processing task: Process this task
```

---

## **🚀 Next Steps**
-  Automate ZIP deployment with a **GitHub Action** or **CI/CD pipeline**.
-  Add **more processing logic**, such as **database writes**.
-  Use **Service Bus** instead of Queue Storage for more advanced messaging.

---

## **🚀 Next Steps**
-  Integrate **Event Grid** to trigger processing when data is uploaded
-  Store **processed results in Cosmos DB**
-  Use **Service Bus** for more advanced messaging
---

## ✨ **References**
- [Terraform](https://www.terraform.io/)
- [Azure Functions](https://azure.microsoft.com/en-us/services/functions/)
- [Azure Queue Storage](https://azure.microsoft.com/en-us/services/storage/queues/)
- [Azure Blob Storage](https://azure.microsoft.com/en-us/services/storage/blobs/)
- [Azure Functions](https://azure.microsoft.com/en-us/services/functions/)
-  [Azure – Queue Storage vs. Service Bus](https://www.youtube.com/watch?v=3q3Qq3Q3Q3Q)