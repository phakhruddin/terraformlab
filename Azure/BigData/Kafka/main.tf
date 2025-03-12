provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "kafka-eventhub-rg"
  location = "West US 2"
}

# Create an Event Hubs Namespace (acts like a Kafka Cluster)
resource "azurerm_eventhub_namespace" "kafka_ns" {
  name                = "kafka-namespace"
  #namespace_id        = azurerm_eventhub_namespace.kafka_ns.id  # Correctly use `id` instead of `name`
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"  # Standard SKU enables Kafka support
  capacity            = 1           # 1 Throughput Unit (TU) to keep costs low
}

# Create an Event Hub (Kafka Topic)

resource "azurerm_eventhub" "kafka_topic" {
  name                = "my-eventhub"
  namespace_id        = azurerm_eventhub_namespace.kafka_ns.id  # Use `id` instead of `name`
  #resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 2
  message_retention   = 7
}

# Create a Consumer Group
resource "azurerm_eventhub_consumer_group" "consumer_grp" {
  name                = "consumer-group-1"
  namespace_name      = azurerm_eventhub_namespace.kafka_ns.name
  eventhub_name       = azurerm_eventhub.kafka_topic.name
  resource_group_name = azurerm_resource_group.rg.name
}

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
