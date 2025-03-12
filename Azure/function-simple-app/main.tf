provider "azurerm" {
  features {}
}

# Random string for uniqueness
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-hello-world"
  location = "West US 2"
}

# Create a Storage Account for the Function App
resource "azurerm_storage_account" "storage" {
  name                     = "sthelloworld${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a Storage Container for Function Code
resource "azurerm_storage_container" "function_container" {
  name                  = "function-code"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

# Create a Zip Archive of the Function Code
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/hello"
  output_path = "${path.module}/function_app.zip"
}

# Upload the Zip File to Blob Storage
resource "azurerm_storage_blob" "function_blob" {
  name                   = "function_app.zip"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.function_container.name
  type                   = "Block"
  source                 = data.archive_file.function_zip.output_path
}

# Generate a SAS URL for the Function Zip
data "azurerm_storage_account_blob_container_sas" "sas" {
  connection_string = azurerm_storage_account.storage.primary_connection_string
  container_name    = azurerm_storage_container.function_container.name
  
  start  = "2023-01-01"
  expiry = "2025-01-01"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

# Create a Serverless Consumption-based App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "plan-hello-world"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

# Create the Azure Function App
resource "azurerm_linux_function_app" "function_app" {
  name                = "func-hello-world-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  service_plan_id            = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "WEBSITE_RUN_FROM_PACKAGE"     = "https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.function_container.name}/function_app.zip${data.azurerm_storage_account_blob_container_sas.sas.sas}"
  }

  depends_on = [
    azurerm_storage_blob.function_blob
  ]
}

# Output the Function App Name and URL
output "function_app_name" {
  value = azurerm_linux_function_app.function_app.name
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.function_app.default_hostname
}