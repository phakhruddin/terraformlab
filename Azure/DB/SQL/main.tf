provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "sql_rg" {
  name     = "sql-resource-group"
  location = "West US 2"
}

# Create SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "deen-sql-server"
  resource_group_name          = azurerm_resource_group.sql_rg.name
  location                     = azurerm_resource_group.sql_rg.location
  version                      = "12.0"
  administrator_login          = "adminuser"
  administrator_login_password = "YourStrongPassword123!"
}

# Create SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name                = "deen-database"
  server_id          = azurerm_mssql_server.sql_server.id
  collation          = "SQL_Latin1_General_CP1_CI_AS"
  license_type       = "LicenseIncluded"
  max_size_gb        = 2
  sku_name           = "Basic"
}

# Allow Public IP Access (Replace with Your IP)
resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  name             = "AllowMyIP"
  server_id       = azurerm_mssql_server.sql_server.id
  start_ip_address = "73.97.154.189"
  end_ip_address   = "73.97.154.189"
}