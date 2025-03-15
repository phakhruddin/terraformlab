
This Terraform configuration creates a Python Azure Function with comprehensive logging capabilities that can be easily monitored. Here's what it sets up:

1. **A Function App with Application Insights integration** for detailed logging
2. **A Python HTTP trigger function** that:
   - Generates logs at various levels (debug, info, warning, error, critical)
   - Allows customizing log messages via query parameters
   - Returns an HTML page with instructions on how to view the logs

## Deployment Instructions

1. Save the Terraform configuration to a file (`main.tf`)
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Apply the configuration:
   ```bash
   terraform apply
   ```
4. Capture the output of the `terraform output` command to a variable (example below):
    ```bash
    application_insights_name = "appinsights-func-log"
    function_app_name = "func-logs-8xdy7f57"
    function_url = "https://func-logs-8xdy7f57.azurewebsites.net/api/LoggingFunction"
    log_query_command = "az webapp log tail --name func-logs-8xdy7f57 --resource-group rg-function-logs"    
    ```
4. Update the function:
    ```bash
    az functionapp deployment source config-zip --resource-group rg-function-logs --name func-logs-8xdy7f57 --src function_app.zip
    ```

## Viewing the Logs

After deployment, you can view the logs in several ways:

### Method 1: Azure Portal (UI)
1. Navigate to your Function App in the Azure Portal
2. Click on "Functions" → "LoggingFunction" → "Monitor"
3. View the logs in the Logs tab

### Method 2: Application Insights
1. Go to the Application Insights resource
2. Click on "Logs"
3. Run a query like:
   ```kusto
   traces
   | where cloud_RoleName == "func-logs-[random-string]"
   | where timestamp > ago(1h)
   | order by timestamp desc
   ```

### Method 3: Azure CLI (Command Line)
```bash
az webapp log tail --name func-logs-[random-string] --resource-group rg-function-logs
```

## Generating Different Log Levels

To test different log levels, access the function URL with query parameters:
- `?level=debug&message=Custom debug message`
- `?level=info&message=Custom info message`
- `?level=warning&message=Custom warning message`
- `?level=error&message=Custom error message`
- `?level=critical&message=Custom critical message`

The function will return an HTML page with instructions and generate both your custom log and some random sample logs at various levels.

The Terraform output will provide:
- Your function URL
- The name of your Application Insights resource
- The Azure CLI command to stream logs

## Sample Ouput

Overview:
<img width="1706" alt="Image" src="https://github.com/user-attachments/assets/bfc61d3d-e895-4d21-84ba-808c1871671b" />

Sample page with:
```
https://func-logs-8xdy7f57.azurewebsites.net/api/LoggingFunction?level=debug&message=Custom debug message
```
<img width="1488" alt="Image" src="https://github.com/user-attachments/assets/37fff57c-b9b4-4ae4-8b63-6317da6dd838" />


Metrics, Invocations, Logs, and Query:
<img width="1700" alt="Image" src="https://github.com/user-attachments/assets/e6df86ff-b957-45f7-83fb-1456acfe8802" />
<img width="1700" alt="Image" src="https://github.com/user-attachments/assets/e2c18779-d0bf-41be-b29a-feec49627112" />
<img width="1681" alt="Image" src="https://github.com/user-attachments/assets/d49ba606-ed2c-4e05-8f40-c90e2db1b507" />
<img width="1706" alt="Image" src="https://github.com/user-attachments/assets/a34884c9-b731-4cfb-8f25-c6300cc70801" />