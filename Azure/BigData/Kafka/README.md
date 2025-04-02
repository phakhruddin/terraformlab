### **Hands-on Apache Kafka on Azure with Terraform (Cost-Optimized)**
We will **deploy Apache Kafka** using **Azure Event Hubs in Kafka mode**, as it is the most cost-effective option.

---

### **📌 What You'll Learn**
1. **Set up Kafka on Azure** using **Azure Event Hubs**.
2. **Produce and consume messages** using Kafka clients.
3. **Manage cost** with auto-scaling and minimal provisioning.

---

## **1️⃣ Architecture Overview**
- **Azure Event Hubs (Kafka Mode)** will act as our **Kafka broker**.
- We will create:
  - **Event Hub Namespace** → The container for Kafka topics.
  - **Event Hub (Topic)** → Our Kafka topic.
  - **Consumer Group** → To process messages.
- **Producers** send messages to the Kafka topic.
- **Consumers** read messages from the topic.

---

## **2️⃣ Terraform Code: Deploy Kafka on Azure Event Hubs**
Here’s a **Terraform script** to deploy a **basic Azure Event Hub setup** with Kafka compatibility.

### **📂 File: `main.tf`**
```hcl
provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "kafka-eventhub-rg"
  location = "East US"
}

# Create an Event Hubs Namespace (acts like a Kafka Cluster)
resource "azurerm_eventhub_namespace" "kafka_ns" {
  name                = "kafka-namespace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"  # Standard SKU enables Kafka support
  capacity            = 1           # 1 Throughput Unit (TU) to keep costs low
  kafka_enabled       = true
}

# Create an Event Hub (Kafka Topic)
resource "azurerm_eventhub" "kafka_topic" {
  name                = "kafka-topic"
  namespace_name      = azurerm_eventhub_namespace.kafka_ns.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2  # Increase partitions for parallel processing
  message_retention   = 1  # 1-day retention to reduce costs
}

# Create a Consumer Group
resource "azurerm_eventhub_consumer_group" "consumer_grp" {
  name                = "consumer-group-1"
  namespace_name      = azurerm_eventhub_namespace.kafka_ns.name
  eventhub_name       = azurerm_eventhub.kafka_topic.name
  resource_group_name = azurerm_resource_group.rg.name
}
```

---

## **3️⃣ Deploy Kafka with Terraform**
Run the following Terraform commands:

```sh
# Initialize Terraform
terraform init

# Plan to see the resources created
terraform plan

# Apply to deploy Kafka on Azure
terraform apply -auto-approve
```

---

## **4️⃣ Test Kafka Producer & Consumer**
Azure Event Hubs supports **Kafka protocol**, so you can use Kafka CLI or Python.

### **🔹 Setup Kafka CLI**
1. Install Kafka CLI:
   ```sh
   sudo apt update && sudo apt install -y kafkacat
   ```

2. Get the Kafka **Broker URL** from Azure:
   ```sh
   echo "Your Event Hub Namespace: kafka-namespace.servicebus.windows.net:9093"
   ```

### **🔹 Send a message to Kafka (Producer)**
Run:
```sh
echo "Hello from Kafka on Azure!" | kafkacat -P -b kafka-namespace.servicebus.windows.net:9093 -t kafka-topic -X security.protocol=SASL_SSL -X sasl.mechanisms=PLAIN -X sasl.username='$ConnectionString' -X sasl.password='<Your_Event_Hub_Connection_String>'
```

### **🔹 Consume a message from Kafka (Consumer)**
Run:
```sh
kafkacat -C -b kafka-namespace.servicebus.windows.net:9093 -t kafka-topic -X security.protocol=SASL_SSL -X sasl.mechanisms=PLAIN -X sasl.username='$ConnectionString' -X sasl.password='<Your_Event_Hub_Connection_String>'
```

---

## **5️⃣ Cost Optimization**
- **Use `Standard` SKU**, not `Premium`.
- **Reduce `message_retention`** to 1 day.
- **Set `capacity = 1`** (Throughput Unit) to minimize costs.
- **Delete unused resources**:
  ```sh
  terraform destroy -auto-approve
  ```

---

## **✅ Summary**
1. **Deployed Kafka on Azure** using **Azure Event Hubs** (cost-effective).
2. **Configured Kafka Producer & Consumer** to send & receive messages.
3. **Optimized cost** by minimizing storage and compute.
4. **Deleted resources** to prevent extra charges.

---
```sh
terraform apply --auto-approve

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_eventhub.kafka_topic will be created
  + resource "azurerm_eventhub" "kafka_topic" {
      + id                  = (known after apply)
      + message_retention   = 7
      + name                = "my-eventhub"
      + namespace_id        = (known after apply)
      + namespace_name      = (known after apply)
      + partition_count     = 2
      + partition_ids       = (known after apply)
      + resource_group_name = (known after apply)
      + status              = "Active"
    }

  # azurerm_eventhub_consumer_group.consumer_grp will be created
  + resource "azurerm_eventhub_consumer_group" "consumer_grp" {
      + eventhub_name       = "my-eventhub"
      + id                  = (known after apply)
      + name                = "consumer-group-1"
      + namespace_name      = "kafka-namespace"
      + resource_group_name = "kafka-eventhub-rg"
    }

  # azurerm_eventhub_namespace.kafka_ns will be created
  + resource "azurerm_eventhub_namespace" "kafka_ns" {
      + auto_inflate_enabled                      = false
      + capacity                                  = 1
      + default_primary_connection_string         = (sensitive value)
      + default_primary_connection_string_alias   = (sensitive value)
      + default_primary_key                       = (sensitive value)
      + default_secondary_connection_string       = (sensitive value)
      + default_secondary_connection_string_alias = (sensitive value)
      + default_secondary_key                     = (sensitive value)
      + id                                        = (known after apply)
      + local_authentication_enabled              = true
      + location                                  = "westus2"
      + minimum_tls_version                       = "1.2"
      + name                                      = "kafka-namespace"
      + network_rulesets                          = (known after apply)
      + public_network_access_enabled             = true
      + resource_group_name                       = "kafka-eventhub-rg"
      + sku                                       = "Standard"
    }

  # azurerm_resource_group.rg will be created
  + resource "azurerm_resource_group" "rg" {
      + id       = (known after apply)
      + location = "westus2"
      + name     = "kafka-eventhub-rg"
    }

  # azurerm_storage_account.function_storage will be created
  + resource "azurerm_storage_account" "function_storage" {
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
      + name                               = "funcstoragedemo123"
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
      + resource_group_name                = "kafka-eventhub-rg"
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

Plan: 5 to add, 0 to change, 0 to destroy.
azurerm_resource_group.rg: Creating...
azurerm_resource_group.rg: Still creating... [10s elapsed]
azurerm_resource_group.rg: Creation complete after 11s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg]
azurerm_eventhub_namespace.kafka_ns: Creating...
azurerm_storage_account.function_storage: Creating...
azurerm_eventhub_namespace.kafka_ns: Still creating... [10s elapsed]
azurerm_storage_account.function_storage: Still creating... [10s elapsed]
azurerm_eventhub_namespace.kafka_ns: Still creating... [20s elapsed]
azurerm_storage_account.function_storage: Still creating... [20s elapsed]
azurerm_eventhub_namespace.kafka_ns: Still creating... [30s elapsed]
azurerm_storage_account.function_storage: Still creating... [30s elapsed]
azurerm_eventhub_namespace.kafka_ns: Creation complete after 36s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.EventHub/namespaces/kafka-namespace]
azurerm_eventhub.kafka_topic: Creating...
azurerm_eventhub.kafka_topic: Creation complete after 3s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.EventHub/namespaces/kafka-namespace/eventhubs/my-eventhub]
azurerm_eventhub_consumer_group.consumer_grp: Creating...
azurerm_storage_account.function_storage: Still creating... [40s elapsed]
azurerm_eventhub_consumer_group.consumer_grp: Creation complete after 3s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.EventHub/namespaces/kafka-namespace/eventhubs/my-eventhub/consumerGroups/consumer-group-1]
azurerm_storage_account.function_storage: Still creating... [50s elapsed]
azurerm_storage_account.function_storage: Still creating... [1m0s elapsed]
azurerm_storage_account.function_storage: Creation complete after 1m5s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.Storage/storageAccounts/funcstoragedemo123]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```




```sh
az resource list --output table                                                      
Name                    ResourceGroup      Location    Type                               Status
----------------------  -----------------  ----------  ---------------------------------  --------
deen-key1               deen_test1         westus2     Microsoft.Compute/sshPublicKeys
NetworkWatcher_westus2  NetworkWatcherRG   westus2     Microsoft.Network/networkWatchers
kafka-namespace         kafka-eventhub-rg  eastus      Microsoft.EventHub/namespaces
bayawchik@Bayas-MacBook-Pro Kafka % az eventhubs namespace show --resource-group kafka-eventhub-rg --name kafka-namespace --query "id"

"/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.EventHub/namespaces/kafka-namespace"

```



To authenticate to an Azure Event Hubs namespace using the `kubectl` command, you'll need to use the Azure Active Directory (AAD) authentication mechanism.

Here are the steps to follow:

1. **Install the Azure CLI**: Make sure you have the Azure CLI installed on your machine. You can download it from the official Azure website.
2. **Login to Azure**: Run the command `az login` to login to your Azure account.
3. **Get the Event Hubs namespace credentials**: Run the command `az eventhubs namespace show --resource-group kafka-eventhub-rg --name kafka-namespace --query "id"` to get the ID of the Event Hubs namespace.
4. **Create a Kubernetes service account**: Run the command `kubectl create sa eventhubs-sa` to create a new Kubernetes service account.
5. **Create a Kubernetes secret**: Run the command `kubectl create secret generic eventhubs-secret --from-literal=EVENTHUBS_NAMESPACE=<namespace-id> --from-literal=EVENTHUBS_SAS_KEY=<sas-key>` to create a new Kubernetes secret. Replace `<namespace-id>` with the ID of the Event Hubs namespace and `<sas-key>` with the SAS key for the namespace.
6. **Create a Kubernetes config file**: Run the command `kubectl config set-credentials eventhubs-sa --token=<token>` to create a new Kubernetes config file. Replace `<token>` with the token obtained from the Azure CLI.
7. **Use the Kubernetes config file**: Run the command `kubectl --kubeconfig=<config-file> get pods` to use the Kubernetes config file to authenticate to the Event Hubs namespace.

Here's an example of the complete command sequence:
```bash
az login
az eventhubs namespace show --resource-group kafka-eventhub-rg --name kafka-namespace --query "id"
kubectl create sa eventhubs-sa
kubectl create secret generic eventhubs-secret --from-literal=EVENTHUBS_NAMESPACE=<namespace-id> --from-literal=EVENTHUBS_SAS_KEY=<sas-key>
kubectl config set-credentials eventhubs-sa --token=$(az account get-access-token --resource https://management.azure.com/ --query "accessToken" -o tsv)
kubectl --kubeconfig=<config-file> get pods
```
Note that you'll need to replace `<namespace-id>`, `<sas-key>`, and `<config-file>` with the actual values for your Event Hubs namespace.

Also, make sure that you have the correct permissions to access the Event Hubs namespace. You can check the permissions by running the command `az role assignment list --resource-group kafka-eventhub-rg --namespace kafka-namespace`.

---


### **🚀 Next Steps: Adding Kafka Streaming Analytics with Azure Functions**

Now that we have **Apache Kafka running on Azure Event Hubs**, let's extend it by **processing Kafka messages in real-time using Azure Functions**. This will allow us to **consume messages, analyze them, and store the results** in a database or another service.

---

## **🔹 Overview: Kafka + Azure Functions Architecture**
1. **Kafka Producer** → Sends messages to **Azure Event Hubs (Kafka Mode)**.
2. **Azure Function (Trigger: Event Hub Kafka Messages)** → Processes messages.
3. **Azure Storage / Cosmos DB / SQL** (Optional) → Stores processed data.

---

## **1️⃣ Modify Terraform to Deploy Azure Function**
We'll use **Terraform** to create an **Azure Function App** that listens to Kafka messages.

### **📂 File: `main.tf` (Updated)**
```hcl
# Create a Storage Account for Function App
resource "azurerm_storage_account" "function_storage" {
  name                     = "funcstoragedemo123"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create an Azure Function App
resource "azurerm_linux_function_app" "kafka_function" {
  name                       = "func-kafka-processor"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.function_plan.id

  app_settings = {
    "AzureWebJobsFeatureFlags"         = "EnableWorkerIndexing"
    "FUNCTIONS_WORKER_RUNTIME"         = "python"
    "EVENT_HUB_CONNECTION_STRING"      = azurerm_eventhub_namespace.kafka_ns.default_primary_connection_string
    "EVENT_HUB_NAME"                   = azurerm_eventhub.kafka_topic.name
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }
}

# Create an App Service Plan for the Function
resource "azurerm_service_plan" "function_plan" {
  name                = "function-app-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption Plan (Cost-Effective)
}
```

---
```sh
terraform apply --auto-approve  
azurerm_resource_group.rg: Refreshing state... [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg]
azurerm_eventhub_namespace.kafka_ns: Refreshing state... [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.EventHub/namespaces/kafka-namespace]
azurerm_storage_account.function_storage: Refreshing state... [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.Storage/storageAccounts/funcstoragedemo123]
azurerm_eventhub.kafka_topic: Refreshing state... [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.EventHub/namespaces/kafka-namespace/eventhubs/my-eventhub]
azurerm_eventhub_consumer_group.consumer_grp: Refreshing state... [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.EventHub/namespaces/kafka-namespace/eventhubs/my-eventhub/consumerGroups/consumer-group-1]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_linux_function_app.kafka_function will be created
  + resource "azurerm_linux_function_app" "kafka_function" {
      + app_settings                                   = {
          + "AzureWebJobsFeatureFlags"    = "EnableWorkerIndexing"
          + "EVENT_HUB_CONNECTION_STRING" = (sensitive value)
          + "EVENT_HUB_NAME"              = "my-eventhub"
          + "FUNCTIONS_WORKER_RUNTIME"    = "python"
        }
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
      + name                                           = "func-kafka-processor"
      + outbound_ip_address_list                       = (known after apply)
      + outbound_ip_addresses                          = (known after apply)
      + possible_outbound_ip_address_list              = (known after apply)
      + possible_outbound_ip_addresses                 = (known after apply)
      + public_network_access_enabled                  = true
      + resource_group_name                            = "kafka-eventhub-rg"
      + service_plan_id                                = (known after apply)
      + site_credential                                = (sensitive value)
      + storage_account_access_key                     = (sensitive value)
      + storage_account_name                           = "funcstoragedemo123"
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
              + python_version              = "3.9"
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
      + name                            = "function-app-plan"
      + os_type                         = "Linux"
      + per_site_scaling_enabled        = false
      + premium_plan_auto_scale_enabled = false
      + reserved                        = (known after apply)
      + resource_group_name             = "kafka-eventhub-rg"
      + sku_name                        = "Y1"
      + worker_count                    = (known after apply)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
azurerm_service_plan.function_plan: Creating...
azurerm_service_plan.function_plan: Still creating... [10s elapsed]
azurerm_service_plan.function_plan: Creation complete after 14s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.Web/serverFarms/function-app-plan]
azurerm_linux_function_app.kafka_function: Creating...
azurerm_linux_function_app.kafka_function: Still creating... [10s elapsed]
azurerm_linux_function_app.kafka_function: Still creating... [20s elapsed]
azurerm_linux_function_app.kafka_function: Still creating... [30s elapsed]
azurerm_linux_function_app.kafka_function: Still creating... [40s elapsed]
azurerm_linux_function_app.kafka_function: Still creating... [50s elapsed]
azurerm_linux_function_app.kafka_function: Still creating... [1m0s elapsed]
azurerm_linux_function_app.kafka_function: Still creating... [1m10s elapsed]
azurerm_linux_function_app.kafka_function: Still creating... [1m20s elapsed]
azurerm_linux_function_app.kafka_function: Creation complete after 1m30s [id=/subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/kafka-eventhub-rg/providers/Microsoft.Web/sites/func-kafka-processor]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```


---

## **2️⃣ Create the Azure Function (Python Code)**
Now, let's create the **Azure Function App code** to consume Kafka messages.

### **📂 File: `function_app/__init__.py`**
```python
import logging
import azure.functions as func

def main(event: func.EventHubEvent):
    message_body = event.get_body().decode('utf-8')
    logging.info(f"Received Kafka message: {message_body}")
```

### **📂 File: `function_app/function.json`**
```json
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "name": "event",
      "type": "eventHubTrigger",
      "direction": "in",
      "eventHubName": "%EVENT_HUB_NAME%",
      "connection": "EVENT_HUB_CONNECTION_STRING",
      "cardinality": "many",
      "consumerGroup": "$Default"
    }
  ]
}
```

### **📂 File: `requirements.txt`**
```txt
azure-functions
```

---

## **3️⃣ Deploy the Function Code to Azure**
Once the Terraform resources are provisioned, **deploy the function code** using Azure CLI:

```sh
# Zip the function code
zip -r function.zip function_app/

# Deploy to Azure
az functionapp deployment source config-zip \
  --resource-group kafka-eventhub-rg \
  --name func-kafka-processor \
  --src function.zip
```
---

```sh
ls
README.md                       main.tf                         terraform.tfstate
function_app                    requirements.txt                terraform.tfstate.backup
```
```sh
zip -r function.zip function_app/
  adding: function_app/ (stored 0%)
  adding: function_app/function.json (deflated 43%)
  adding: function_app/__init__.py (deflated 27%)
Kafka % az functionapp deployment source config-zip --resource-group kafka-eventhub-rg --name func-kafka-processor --src function.zip
App settings have been redacted. Use `az webapp/logicapp/functionapp config appsettings list` to view.
```

---

## **4️⃣ Test the Kafka + Azure Function Integration**
Now that our **Azure Function is deployed**, let’s test if it correctly **receives and processes Kafka messages**.

Get the username and sasl.password with 
```sh
az eventhubs namespace authorization-rule keys list --resource-group kafka-eventhub-rg --namespace-name kafka-namespace --name RootManageSharedAccessKey
```
```sh
{
  "keyName": "RootManageSharedAccessKey",
  "primaryConnectionString": "Endpoint=sb://kafka-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=XYX",
  "primaryKey": "xYX",
  "secondaryConnectionString": "Endpoint=sb://kafka-namespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=XYX",
  "secondaryKey": "XyX"
}
```

### **🔹 Send a Kafka Message**
```sh
echo "Hello from Kafka!" | kafkacat -P -b kafka-namespace.servicebus.windows.net:9093 -t kafka-topic \
-X security.protocol=SASL_SSL -X sasl.mechanisms=PLAIN -X sasl.username='$ConnectionString' -X sasl.password='<Your_Event_Hub_Connection_String>'
```

### **🔹 View Logs of Azure Function**
To verify that the function **processed the Kafka message**, check logs:
```sh
az functionapp log tail --name func-kafka-processor --resource-group kafka-eventhub-rg
```
You should see:
```
Received Kafka message: Hello from Kafka!
```

---

## **✅ Summary**
1. **Deployed Azure Functions** using **Terraform**.
2. **Configured Kafka Event Hubs** to trigger the function.
3. **Wrote a Python function** to process Kafka messages.
4. **Sent a Kafka message** and **verified processing** in Azure logs.

---

## **🚀 Next Steps**
- Store processed messages in **Azure Storage, Cosmos DB, or SQL**.
- Apply **real-time filtering & transformations** on messages.
- Implement **Azure Monitor & alerts** for Kafka failures.


