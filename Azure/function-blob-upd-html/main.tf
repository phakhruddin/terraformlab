provider "azurerm" {
  features {}
}

# Variables
variable "location" {
  description = "The Azure region to deploy resources"
  default     = "West US 2"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "rg-function-vm-demo"
}

variable "vm_admin_username" {
  description = "Admin username for the VM"
  default     = "azureadmin"
}

variable "vm_admin_password" {
  description = "Admin password for the VM"
  default     = "P@ssw0rd1234!"  # In production, use a secure method to handle passwords
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnets
resource "azurerm_subnet" "function_subnet" {
  name                 = "snet-function"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Web"]
  delegation {
    name = "delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Network Security Group for VM
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "nsg-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw_pip" {
  name                = "pip-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP for VM (for SSH access)
resource "azurerm_public_ip" "vm_pip" {
  name                = "pip-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface for VM
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "vm_nsg_association" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# VM to host the web server
resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "vm-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  disable_password_authentication = false
  
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # Install Apache web server
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    
    # Create a directory for the web server
    mkdir -p /var/www/html
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    # Create index.html with a placeholder
    echo "<html><body><h1>Hello World - Waiting for update from Azure Function</h1></body></html>" > /var/www/html/index.html
    
    # Ensure apache is running
    systemctl enable apache2
    systemctl start apache2
  EOF
  )
}

# Random string for unique names
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

# Storage account for Function App and Function code
resource "azurerm_storage_account" "storage" {
  name                     = "st${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container for the function zip
resource "azurerm_storage_container" "function_container" {
  name                  = "function-code"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# Local file for function code - to be zipped and uploaded
resource "local_file" "init_py" {
  content = <<EOF
import datetime
import logging
import os
import paramiko
import azure.functions as func

def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc).isoformat()
    logging.info('Python timer trigger function ran at %s', utc_timestamp)
    
    # Get current time
    now = datetime.datetime.now()
    formatted_time = now.strftime("%Y-%m-%d %H:%M:%S")
    
    # HTML content
    html_content = f"""
    <html>
    <head>
        <title>Hello World with Current Time</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                margin: 0;
                padding: 20px;
                background-color: #f0f0f0;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
            }}
            .container {{
                text-align: center;
                padding: 30px;
                background-color: white;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                border-radius: 8px;
            }}
            h1 {{
                color: #333;
            }}
            .time {{
                color: #0066cc;
                font-size: 24px;
                margin: 20px 0;
            }}
            .update-info {{
                color: #666;
                font-size: 14px;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Hello World</h1>
            <div class="time">{formatted_time}</div>
            <div class="update-info">Updated by Azure Function from Blob Storage Zip</div>
        </div>
    </body>
    </html>
    """
    
    # Connect to VM and update index.html
    try:
        # Get VM details from env variables
        vm_ip = os.environ['VM_IP']
        vm_username = os.environ['VM_USERNAME']
        vm_password = os.environ['VM_PASSWORD']
        
        # Create SSH client
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Connect to VM
        ssh.connect(hostname=vm_ip, username=vm_username, password=vm_password)
        
        # Write HTML content to index.html
        ssh_command = f'echo \'{html_content}\' > /var/www/html/index.html'
        stdin, stdout, stderr = ssh.exec_command(ssh_command)
        
        # Close SSH connection
        ssh.close()
        
        logging.info('Successfully updated index.html on VM')
    except Exception as e:
        logging.error(f'Error updating VM: {str(e)}')
EOF
  filename = "${path.module}/UpdateWebPage/__init__.py"
}

resource "local_file" "function_json" {
  content = <<EOF
{
  "bindings": [
    {
      "name": "mytimer",
      "type": "timerTrigger",
      "direction": "in",
      "schedule": "0 */15 * * * *"
    }
  ]
}
EOF
  filename = "${path.module}/UpdateWebPage/function.json"
}

resource "local_file" "requirements_txt" {
  content = <<EOF
azure-functions
paramiko
EOF
  filename = "${path.module}/requirements.txt"
}

resource "local_file" "host_json" {
  content = <<EOF
{
  "version": "2.0",
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[3.*, 4.0.0)"
  }
}
EOF
  filename = "${path.module}/host.json"
}

# Create archive of function app
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}"
  output_path = "${path.module}/function_app.zip"
  excludes    = ["terraform.tfstate", "terraform.tfstate.backup", ".terraform", "main.tf", "terraform.tfvars"]
  
  depends_on = [
    local_file.init_py,
    local_file.function_json,
    local_file.requirements_txt,
    local_file.host_json
  ]
}

# Upload zip to blob storage
resource "azurerm_storage_blob" "function_blob" {
  name                   = "function_app.zip"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.function_container.name
  type                   = "Block"
  source                 = data.archive_file.function_zip.output_path
}

# Generate SAS URL for the function zip
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

# App Service Plan for Function App
resource "azurerm_service_plan" "function_plan" {
  name                = "plan-function-app"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
}

# Function App
resource "azurerm_linux_function_app" "update_web_app" {
  name                = "func-update-web-${random_string.random.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  service_plan_id            = azurerm_service_plan.function_plan.id

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "WEBSITE_RUN_FROM_PACKAGE"     = "https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.function_container.name}/function_app.zip${data.azurerm_storage_account_blob_container_sas.sas.sas}"
    "VM_IP"                        = azurerm_network_interface.vm_nic.private_ip_address
    "VM_USERNAME"                  = var.vm_admin_username
    "VM_PASSWORD"                  = var.vm_admin_password
    "WEBSITE_TIME_ZONE"            = "Eastern Standard Time"
  }
  
  depends_on = [
    azurerm_storage_blob.function_blob
  ]
}

# Application Gateway
resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-web"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name         = "vm-backend-pool"
    ip_addresses = [azurerm_network_interface.vm_nic.private_ip_address]
  }

  backend_http_settings {
    name                  = "http-backend-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "vm-backend-pool"
    backend_http_settings_name = "http-backend-settings"
    priority                   = 100
  }
}

# Outputs
output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "vm_public_ip" {
  value = azurerm_public_ip.vm_pip.ip_address
}

output "function_app_name" {
  value = azurerm_linux_function_app.update_web_app.name
}

output "function_app_default_hostname" {
  value = azurerm_linux_function_app.update_web_app.default_hostname
}

output "function_code_blob_url" {
  value = "https://${azurerm_storage_account.storage.name}.blob.core.windows.net/${azurerm_storage_container.function_container.name}/function_app.zip"
}