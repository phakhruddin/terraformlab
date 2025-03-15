provider "azurerm" {
  features {}
}

# Random string for unique names
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-function-logs"
  location = "West US 2"
}

# Storage Account for Function App
resource "azurerm_storage_account" "sa" {
  name                     = "stfunclog${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Application Insights for Function monitoring and logging
resource "azurerm_application_insights" "appinsights" {
  name                = "appinsights-func-log"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

# App Service Plan (Consumption plan)
resource "azurerm_service_plan" "asp" {
  name                = "asp-function-logs"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan (serverless)
}

# Function App
resource "azurerm_linux_function_app" "function_app" {
  name                = "func-logs-${random_string.random.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      python_version = "3.9"
    }
    application_insights_key = azurerm_application_insights.appinsights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.appinsights.connection_string
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.appinsights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string
    "WEBSITE_RUN_FROM_PACKAGE"     = "1"
    "LOG_LEVEL"                    = "Information" # Options: Trace, Debug, Information, Warning, Error, Critical
    "ENABLE_ORYX_BUILD"            = "true"
  }
}

# Create function code files
resource "local_file" "init_py" {
  content = templatefile("${path.module}/function_template.py", {
    app_name = "func-logs-${random_string.random.result}"
  })
  filename = "${path.module}/LoggingFunction/__init__.py"
}

resource "local_file" "function_json" {
  content = <<EOF
{
  "bindings": [
    {
      "authLevel": "anonymous",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": [
        "get",
        "post"
      ]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "$return"
    }
  ]
}
EOF
  filename = "${path.module}/LoggingFunction/function.json"
}

resource "local_file" "host_json" {
  content = <<EOF
{
  "version": "2.0",
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "excludedTypes": "Request"
      }
    },
    "logLevel": {
      "default": "Information",
      "Host.Results": "Information",
      "Function": "Information",
      "Host.Aggregator": "Information"
    }
  },
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[3.*, 4.0.0)"
  }
}
EOF
  filename = "${path.module}/host.json"
}

resource "local_file" "requirements_txt" {
  content = <<EOF
azure-functions
EOF
  filename = "${path.module}/requirements.txt"
}

# Create a zip file of function code
data "archive_file" "function_app_zip" {
  type        = "zip"
  source_dir  = "${path.module}"
  output_path = "${path.module}/function_app.zip"
  excludes    = ["terraform.tfstate", "terraform.tfstate.backup", ".terraform", "*.tf"]
  
  depends_on = [
    local_file.init_py,
    local_file.function_json,
    local_file.host_json,
    local_file.requirements_txt
  ]
}


/*
# Deploy function code
resource "azurerm_function_app_function" "logging_function" {
  name            = "LoggingFunction"
  function_app_id = azurerm_linux_function_app.function_app.id
  language        = "Python"
  config_json     = local_file.host_json.content
  
  file {
    name    = "function.json"
    content = local_file.function_json.content
  }
  
  file {
    name    = "__init__.py"
    content = local_file.init_py.content
  }
}
*/

# Outputs
output "function_app_name" {
  value = azurerm_linux_function_app.function_app.name
}

output "function_url" {
  value = "https://${azurerm_linux_function_app.function_app.default_hostname}/api/LoggingFunction"
}

output "application_insights_name" {
  value = azurerm_application_insights.appinsights.name
}

output "log_query_command" {
  value = "az webapp log tail --name ${azurerm_linux_function_app.function_app.name} --resource-group ${azurerm_resource_group.rg.name}"
}