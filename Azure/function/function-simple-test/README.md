### 🚀 **Simple Azure Function (HTTP Trigger) with Terraform**
This setup will:
1. **Create an Azure Function App using Terraform** ✅
2. **Allow HTTP requests to trigger the function** ✅
3. **Enable logging so you can inspect the logs via Azure Portal/UI** ✅

---

## **🛠 Plan**
- **Terraform** provisions:
  - **Azure Resource Group**
  - **Storage Account** (required for Function Apps)
  - **Function App Service Plan** (Consumption-based)
  - **Linux-based Function App** (Python)
- **Deploy Function Code** using `az` CLI
- **Test Function via UI & Logs**

---

## 1️⃣ Terraform Configuration**
📄 **`main.tf`**
```hcl
provider "azurerm" {
  features {}
}

# 🔹 Create Resource Group
resource "azurerm_resource_group" "func_rg" {
  name     = "simple-function-rg"
  location = "West US 2"
}

# 🔹 Create Storage Account for Function
resource "azurerm_storage_account" "func_storage" {
  name                     = "funcsimplestorage"
  resource_group_name      = azurerm_resource_group.func_rg.name
  location                 = azurerm_resource_group.func_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 🔹 Create Function App Service Plan
resource "azurerm_service_plan" "function_plan" {
  name                = "simple-function-plan"
  resource_group_name = azurerm_resource_group.func_rg.name
  location            = azurerm_resource_group.func_rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan (serverless)
}

# 🔹 Create Linux Function App
resource "azurerm_linux_function_app" "simple_function" {
  name                       = "func-simple-test"
  resource_group_name        = azurerm_resource_group.func_rg.name
  location                   = azurerm_resource_group.func_rg.location
  service_plan_id            = azurerm_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"  = "python"
    "AzureWebJobsStorage"       = azurerm_storage_account.func_storage.primary_connection_string
  }
}
```

---

## **2️⃣ Create Function Code (Python)**
📄 **`simple-function/__init__.py`**
```python
import logging
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Function triggered via HTTP request.")

    name = req.params.get("name")
    if not name:
        try:
            req_body = req.get_json()
            name = req_body.get("name")
        except ValueError:
            pass

    if name:
        return func.HttpResponse(f"Hello, {name}!")
    else:
        return func.HttpResponse(
            "Please pass a name in the query string or request body",
            status_code=400
        )
```

📄 **`simple-function/function.json`**
```json
{
  "bindings": [
    {
      "authLevel": "anonymous",
      "type": "httpTrigger",
      "direction": "in",
      "methods": ["get", "post"],
      "name": "req"
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    }
  ]
}
```

📄 **`simple-function/requirements.txt`**
```
azure-functions
```

---

##  3️⃣ Package the Function Code**
Run:
```sh
cd simple-function
zip -r ../simple-function.zip .
cd ..
```

---

##  4️⃣ Deploy Terraform Infrastructure**
```sh
terraform init
terraform apply -auto-approve
```

---

## 5️⃣ Deploy the Function Code Using `az`**
```sh
az functionapp deployment source config-zip \
  --resource-group simple-function-rg \
  --name func-simple-test \
  --src simple-function.zip
```

---

## 6️⃣ Get Function URL & Test**
Retrieve function URL:
```sh
az functionapp function show \
  --name func-simple-test \
  --resource-group simple-function-rg \
  --function-name HttpTrigger \
  --query "invokeUrlTemplate" -o tsv
```

Use `curl` to test:
```sh
curl "https://func-simple-test.azurewebsites.net/api/HttpTrigger?name=Azure"
```

Expected output:
```
Hello, Azure!
```

---

## 7️⃣ View Logs in Azure Portal**
1. Open **Azure Portal** → **Function App** (`func-simple-test`).
2. Navigate to **Logs** under **Monitoring**.
3. You should see **"Function triggered via HTTP request."**

Alternatively, use `az` CLI:
```sh
az functionapp log tail --name func-simple-test --resource-group simple-function-rg
```

---

## ✅ Done!**
- **You can test the function via the Azure UI and logs.**
- **The logs will show function execution in real-time.**
- **Terraform will create the resources in the Azure environment.**
- **Terraform will destroy the resources in the Azure environment.**