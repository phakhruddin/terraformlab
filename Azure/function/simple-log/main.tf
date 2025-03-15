# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "rg-logging-function"
  location = "westus2"  # Change to your preferred region
}

# Create a storage account (required for Function App)
resource "azurerm_storage_account" "storage" {
  name                     = "stloggingfunc${random_string.suffix.result}"  # Unique name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create an App Service Plan (Consumption plan)
resource "azurerm_service_plan" "plan" {
  name                = "plan-logging-function"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"  # Python requires Linux
  sku_name            = "Y1"     # Consumption (serverless)
}

# Create Application Insights for logging
resource "azurerm_application_insights" "app_insights" {
  name                = "ai-logging-function"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

# Create the Function App
resource "azurerm_linux_function_app" "function" {
  name                       = "func-logging-${random_string.suffix.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  site_config {
    application_stack {
      python_version = "3.9"  # Supported Python version
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "WEBSITE_RUN_FROM_PACKAGE"       = "1"  # Zip deployment
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app_insights.instrumentation_key
  }
}

# Output the Function App hostname
output "function_app_hostname" {
  value = azurerm_linux_function_app.function.default_hostname
}

# Output the Application Insights key for reference
output "app_insights_key" {
  value = azurerm_application_insights.app_insights.instrumentation_key
  sensitive = true
}