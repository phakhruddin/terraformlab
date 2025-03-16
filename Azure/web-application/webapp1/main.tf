# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-web-demo-${random_string.suffix.result}"
  location = "westus2"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-web-demo-${random_string.suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet for Application Gateway
resource "azurerm_subnet" "frontend_subnet" {
  name                 = "frontend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet for VM Scale Set
resource "azurerm_subnet" "backend_subnet" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw_pip" {
  name                = "appgw-pip-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# User-Assigned Managed Identity for Application Gateway
resource "azurerm_user_assigned_identity" "appgw_identity" {
  name                = "appgw-identity-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Key Vault for Certificate
resource "azurerm_key_vault" "kv" {
  name                        = "kv-webdemo-${random_string.suffix.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
}

# Key Vault Access Policy for Terraform Principal
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault_access_policy" "kv_policy_terraform" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id


  certificate_permissions = ["Get", "List", "Create", "Import", "Update", "Delete"]
  key_permissions         = ["Get", "List", "Create"]
  secret_permissions      = ["Get", "List", "Set", "Delete"]
}

# Self-signed certificate
resource "azurerm_key_vault_certificate" "cert" {
  name         = "webdemo-cert-${random_string.suffix.result}"
  key_vault_id = azurerm_key_vault.kv.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      subject            = "CN=webdemo-${random_string.suffix.result}.example.com"
      validity_in_months = 12
      key_usage = ["digitalSignature", "keyEncipherment"]
    }
  }

  depends_on = [azurerm_key_vault_access_policy.kv_policy_terraform]
}

# Application Gateway (Load Balancer)
resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-webdemo-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.appgw_identity.id]  
    }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.frontend_subnet.id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "public-ip-config"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-setting"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "public-ip-config"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "webdemo-cert-${random_string.suffix.result}"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-setting"
    priority                   = 100
  }

  ssl_certificate {
    name                = "webdemo-cert-${random_string.suffix.result}"
    key_vault_secret_id = azurerm_key_vault_certificate.cert.secret_id
  }
}

# Key Vault Access Policy for Application Gateway (Applied after AppGW creation)
resource "azurerm_key_vault_access_policy" "kv_policy_appgw" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  #object_id    = azurerm_application_gateway.appgw.identity[0].principal_id
  object_id     = azurerm_user_assigned_identity.appgw_identity.principal_id


  certificate_permissions = ["Get"]
  secret_permissions      = ["Get"]

  depends_on = [azurerm_application_gateway.appgw]
}

# Network Security Group for VMs
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-webdemo-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

data "azurerm_ssh_public_key" "ssh_key" {
  name                = "deen-key1"
  resource_group_name = "deen_test1"
}


# VM Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-webdemo-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = "adminuser"

  # Use SSH key authentication instead of password
  admin_ssh_key {
    username   = "adminuser"
    public_key = data.azurerm_ssh_public_key.ssh_key.public_key  # Use fetched SSH key
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "nic-vmss"
    primary = true

    ip_configuration {
      name                                   = "internal"
      subnet_id                              = azurerm_subnet.backend_subnet.id
      #application_gateway_backend_address_pool_ids = [azurerm_application_gateway.appgw.backend_address_pool[0].id]
      application_gateway_backend_address_pool_ids = [for pool in azurerm_application_gateway.appgw.backend_address_pool : pool.id]
    }
    network_security_group_id = azurerm_network_security_group.nsg.id
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx python3-pip
    pip3 install flask pymongo
    echo "<h1>Welcome to Web Demo</h1><p>Data: <span id='data'></span></p><script>fetch('/api/data').then(r => r.json()).then(d => document.getElementById('data').innerText = d.message);</script>" > /var/www/html/index.html
    cat << 'PY' > /home/adminuser/app.py
    from flask import Flask, jsonify
    import pymongo
    app = Flask(__name__)
    client = pymongo.MongoClient(f"mongodb://{azurerm_cosmosdb_account.cosmos.name}:{azurerm_cosmosdb_account.cosmos.primary_master_key}@{azurerm_cosmosdb_account.cosmos.endpoint}:10255/?ssl=true&replicaSet=globaldb&retrywrites=false")
    db = client["demo_db"]
    collection = db["demo_collection"]
    @app.route('/api/data')
    def get_data():
        data = collection.find_one({"key": "test"}) or {"message": "No data"}
        return jsonify({"message": data.get("message", "No data")})
    if __name__ == "__main__":
        app.run(host="0.0.0.0", port=80)
    PY
    python3 /home/adminuser/app.py &
  EOF
  )

  upgrade_mode = "Manual"

}

# Auto-Scaling based on CPU
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale-webdemo-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "default"
    capacity {
      default = 2
      minimum = 2
      maximum = 5
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

# Cosmos DB with MongoDB API
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cosmos-webdemo-${random_string.suffix.result}"
  #name                = azurerm_cosmosdb_account.cosmos.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_mongo_database" "db" {
  name                = "demo_db"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_mongo_collection" "collection" {
  name                = "demo_collection"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_mongo_database.db.name

  index {
    keys   = ["_id"]
    unique = true
  }
}

# Output the Application Gateway URL
output "appgw_url" {
  value = "https://${azurerm_public_ip.appgw_pip.ip_address}"
}
