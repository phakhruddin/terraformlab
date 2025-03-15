provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Create Resource Group
resource "azurerm_resource_group" "func_rg" {
  name     = "simple-function-rg"
  location = "West US 2"
}

# Create Storage Account for Function
resource "azurerm_storage_account" "func_storage" {
  name                     = "funcsimplestorage"
  resource_group_name      = azurerm_resource_group.func_rg.name
  location                 = azurerm_resource_group.func_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create Function App Service Plan
resource "azurerm_service_plan" "function_plan" {
  name                = "simple-function-plan"
  resource_group_name = azurerm_resource_group.func_rg.name
  location            = azurerm_resource_group.func_rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan (serverless)
}

# Create Linux Function App
resource "azurerm_linux_function_app" "simple_function" {
  name                       = "func-simple-test"
  resource_group_name        = azurerm_resource_group.func_rg.name
  location                   = azurerm_resource_group.func_rg.location
  service_plan_id            = azurerm_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key

  site_config {
    application_stack {
      python_version = "3.8"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"  = "python"
    "AzureWebJobsStorage"       = azurerm_storage_account.func_storage.primary_connection_string
  }
}
