Let’s create a simple Python Azure Function using Terraform that logs a message and allows you to view its logs via Application Insights. This setup will include a Resource Group, Storage Account, App Service Plan, Function App, and Application Insights. I’ll provide the Terraform code, the Python function, and instructions to view the logs.

---

### **Terraform Configuration (`main.tf`)**
This deploys the infrastructure with Application Insights enabled for logging.

```hcl
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
}
```

---

### **Python Function Code**
Create a directory (e.g., `logging_function`) with these files:

#### **`logging_function/function.json`**
Defines an HTTP trigger:
```json
{
  "scriptFile": "__init__.py",
  "bindings": [
    {
      "authLevel": "anonymous",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get"],
      "route": "log_message"
    },
    {
      "type": "http",
      "direction": "out",
      "name": "$return"
    }
  ]
}
```

#### **`logging_function/__init__.py`**
A simple function that logs a message:
```python
import logging
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("This is a test log message from the Python function!")
    return func.HttpResponse("Function executed. Check logs in Application Insights.", status_code=200)
```

#### **`host.json`**
Configures logging with Application Insights (place in the root directory):
```json
{
  "version": "2.0",
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true
      },
      "logLevel": {
        "default": "Information"
      }
    }
  }
}
```

#### **`requirements.txt`**
Lists dependencies:
```
azure-functions
```

---

### **Deployment Steps**

#### **1. Initialize and Apply Terraform**
- Save the Terraform code as `main.tf`.
- Run:
  ```bash
  terraform init
  terraform apply
  ```
- Confirm with `yes`. This deploys the resources.

#### **2. Package the Function**
- In the directory with `logging_function`, `host.json`, and `requirements.txt`, create a zip file:
  ```bash
  zip -r function_app.zip .
  ```

#### **3. Deploy the Function**
- Use the Function App name from the Terraform output (e.g., `func-logging-xxxx`):
  ```bash
  az functionapp deployment source config-zip \
    --resource-group rg-logging-function \
    --name func-logging-<suffix> \
    --src function_app.zip
  ```
  Replace `<suffix>` with the random string from the output.

#### **4. Test the Function**
- Get the hostname from the Terraform output (e.g., `func-logging-xxxx.azurewebsites.net`).
- Trigger the function:
  ```bash
  curl http://func-logging-xxxx.azurewebsites.net/api/log_message
  ```
- Expected response: `Function executed. Check logs in Application Insights.`

---

### **Viewing Logs in Application Insights**

#### **Option 1: Azure Portal**
1. Go to **Azure Portal** > **Application Insights** > `ai-logging-function`.
2. Click **Logs** (under Monitoring).
3. Run this query to see the log messages:
   ```kql
   traces
   | where timestamp > ago(1h)
   | where message contains "test log message"
   ```
4. You should see entries like:
   ```
   This is a test log message from the Python function!
   ```

#### **Option 2: Live Metrics**
- In Application Insights > **Live Metrics**, watch logs stream in real-time as you trigger the function with `curl`.

#### **Option 3: Azure CLI**
- Query logs programmatically:
  ```bash
  az monitor app-insights query \
    --app ai-logging-function \
    --resource-group rg-logging-function \
    --analytics-query "traces | where timestamp > ago(1h) | where message contains 'test log message'"
  ```

---

### **Explanation**
- **Terraform**:
  - Creates a Function App with a Consumption plan (`Y1`) and links it to Application Insights via `APPINSIGHTS_INSTRUMENTATIONKEY`.
  - Uses a random suffix for unique resource names.
- **Python Function**:
  - Logs an `INFO`-level message using Python’s `logging` module, which Application Insights captures.
  - Responds to HTTP GET requests at `/api/log_message`.
- **Logs**:
  - Application Insights collects and stores logs, making them queryable or viewable in real-time.

---

### **Troubleshooting**
- **No Logs Visible**:
  - Ensure the function executed successfully (`curl` returns 200).
  - Check `APPINSIGHTS_INSTRUMENTATIONKEY` is set correctly in the Function App settings:
    ```bash
    az functionapp config appsettings list --name func-logging-<suffix> --resource-group rg-logging-function
    ```
  - Wait a few minutes—there can be a slight delay in log ingestion.
- **Deployment Fails**:
  - Verify the zip file includes all required files and the deployment command succeeds.

---

### **Next Steps**
- Deploy this and trigger the function with `curl`.
- Check the logs in Application Insights and let me know what you see!