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
  content = <<EOF
import logging
import time
import random
import datetime
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    # Configure logging
    logging.info('Python HTTP trigger function processed a request')
    
    # Get query parameter
    log_level = req.params.get('level', 'info').lower()
    log_message = req.params.get('message', 'This is a test log message')
    
    # Current timestamp
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Generate some logs at different levels based on the parameter
    if log_level == 'debug':
        logging.debug(f"[{timestamp}] DEBUG: {log_message}")
    elif log_level == 'info':
        logging.info(f"[{timestamp}] INFO: {log_message}")
    elif log_level == 'warning':
        logging.warning(f"[{timestamp}] WARNING: {log_message}")
    elif log_level == 'error':
        logging.error(f"[{timestamp}] ERROR: {log_message}")
    elif log_level == 'critical':
        logging.critical(f"[{timestamp}] CRITICAL: {log_message}")
    else:
        logging.info(f"[{timestamp}] INFO: {log_message}")
    
    # Generate a few random logs for demonstration
    log_types = ['DEBUG', 'INFO', 'WARNING', 'ERROR']
    actions = ['User login', 'Data processed', 'Authentication attempt', 'Database query', 'File operation']
    statuses = ['successful', 'failed', 'partial', 'timeout', 'denied']
    
    for _ in range(3):
        log_type = random.choice(log_types)
        action = random.choice(actions)
        status = random.choice(statuses)
        
        if log_type == 'DEBUG':
            logging.debug(f"[{timestamp}] {action} {status}, execution time: {random.randint(10, 500)}ms")
        elif log_type == 'INFO':
            logging.info(f"[{timestamp}] {action} {status}, items: {random.randint(1, 100)}")
        elif log_type == 'WARNING':
            logging.warning(f"[{timestamp}] {action} {status}, retry attempt: {random.randint(1, 3)}")
        elif log_type == 'ERROR':
            logging.error(f"[{timestamp}] {action} {status}, error code: {random.randint(400, 500)}")
    
    # Return response with logging instructions
    html_response = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Function Logs Demo</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                line-height: 1.6;
                margin: 20px;
                color: #333;
                max-width: 800px;
                margin: 0 auto;
                padding: 20px;
            }}
            h1 {{
                color: #0066cc;
            }}
            .card {{
                background-color: #f5f5f5;
                border-left: 4px solid #0066cc;
                padding: 15px;
                margin-bottom: 20px;
            }}
            code {{
                background-color: #f0f0f0;
                padding: 2px 5px;
                border-radius: 4px;
                font-family: Consolas, monospace;
            }}
            .log-command {{
                background-color: #333;
                color: white;
                padding: 10px;
                border-radius: 4px;
                font-family: Consolas, monospace;
                overflow-x: auto;
            }}
            .tip {{
                background-color: #e6f7ff;
                border-left: 4px solid #1890ff;
                padding: 15px;
                margin-bottom: 20px;
            }}
        </style>
    </head>
    <body>
        <h1>Function Logs Generated</h1>
        <div class="card">
            <p>Timestamp: {timestamp}</p>
            <p>Primary Log: {log_level.upper()} - {log_message}</p>
            <p>Additional random logs were also generated.</p>
        </div>
        
        <h2>How to View Logs</h2>
        
        <h3>Method 1: Azure Portal</h3>
        <ol>
            <li>Go to your Function App in the Azure Portal</li>
            <li>Click on "Functions" in the left menu</li>
            <li>Select your function (LoggingFunction)</li>
            <li>Click on "Monitor" in the left menu</li>
            <li>View logs in the "Logs" tab</li>
        </ol>
        
        <h3>Method 2: Application Insights</h3>
        <ol>
            <li>Go to your Application Insights resource</li>
            <li>Click on "Logs" in the left menu</li>
            <li>Run a query like:</li>
        </ol>
        <div class="log-command">
            traces<br>
            | where cloud_RoleName == "func-logs-{random_string.random.result}"<br>
            | where timestamp > ago(1h)<br>
            | order by timestamp desc
        </div>
        
        <h3>Method 3: Azure CLI</h3>
        <p>Use the following command to stream logs:</p>
        <div class="log-command">
            az webapp log tail --name func-logs-{random_string.random.result} --resource-group rg-function-logs
        </div>
        
        <div class="tip">
            <strong>Tip:</strong> You can generate logs with different levels by adding query parameters:
            <ul>
                <li><code>?level=debug&message=Custom debug message</code></li>
                <li><code>?level=info&message=Custom info message</code></li>
                <li><code>?level=warning&message=Custom warning message</code></li>
                <li><code>?level=error&message=Custom error message</code></li>
                <li><code>?level=critical&message=Custom critical message</code></li>
            </ul>
        </div>
    </body>
    </html>
    """
    
    return func.HttpResponse(
        html_response,
        mimetype="text/html"
    )
EOF
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