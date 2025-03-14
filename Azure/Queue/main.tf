provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "queue_rg" {
  name     = "queue-resource-group"
  location = "West US 2"
}

# 🔹 Create Storage Account for Queue
resource "azurerm_storage_account" "queue_storage" {
  name                     = "queueprocessstorage"
  resource_group_name      = azurerm_resource_group.queue_rg.name
  location                 = azurerm_resource_group.queue_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 🔹 Create a Queue inside Storage Account
resource "azurerm_storage_queue" "task_queue" {
  name                 = "task-queue"
  storage_account_name = azurerm_storage_account.queue_storage.name
}

# 🔹 Create Function App Service Plan
resource "azurerm_service_plan" "function_plan" {
  name                = "queue-function-plan"
  resource_group_name = azurerm_resource_group.queue_rg.name
  location            = azurerm_resource_group.queue_rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
}

# 🔹 Create Function App (without ZIP file upload)
resource "azurerm_linux_function_app" "queue_function" {
  name                       = "func-queue-processor"
  resource_group_name        = azurerm_resource_group.queue_rg.name
  location                   = azurerm_resource_group.queue_rg.location
  service_plan_id            = azurerm_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.queue_storage.name
  storage_account_access_key = azurerm_storage_account.queue_storage.primary_access_key

  site_config {
    application_stack {
      python_version = "3.8"
    }
  }

  app_settings = {
    "AzureWebJobsStorage"       = azurerm_storage_account.queue_storage.primary_connection_string
    "QUEUE_NAME"                = azurerm_storage_queue.task_queue.name
    "FUNCTIONS_WORKER_RUNTIME"  = "python"
  }
}