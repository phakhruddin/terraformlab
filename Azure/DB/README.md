### 🚀 **Deploy a Managed Database (SQL or NoSQL) on Azure using Terraform**  
We will deploy **Azure SQL Database** (relational) and **Azure Cosmos DB** (NoSQL) using Terraform.

---

## **✅ Option 1: Deploy Azure SQL Database (Relational)**
### **📌 What This Will Do:**
- Creates an **Azure SQL Server**
- Deploys an **Azure SQL Database**
- Configures a **firewall rule** to allow your IP to connect

---

### **📜 Terraform Code for Azure SQL Database**
Create a new Terraform file **`main.tf`** and paste the following:

```hcl
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
  max_size_gb        = 5
  sku_name           = "Basic"
}

# Allow Public IP Access (Replace with Your IP)
resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  name             = "AllowMyIP"
  server_id       = azurerm_mssql_server.sql_server.id
  start_ip_address = "YOUR_IP_HERE"
  end_ip_address   = "YOUR_IP_HERE"
}
```

---

### **🌟 Deploy the SQL Database**
Run the following Terraform commands:

```sh
terraform init
terraform apply -auto-approve
```

After the deployment, you can connect to the database using **Azure Data Studio** or **SQL Server Management Studio (SSMS)**.

---

## **✅ Option 2: Deploy Azure Cosmos DB (NoSQL)**
### **📌 What This Will Do:**
- Creates an **Azure Cosmos DB Account**
- Deploys a **Cosmos DB Database**
- Creates a **NoSQL Container (MongoDB API)**

---

### **📜 Terraform Code for Azure Cosmos DB (MongoDB API)**
Create a new Terraform file **`cosmosdb.tf`**:

```hcl
provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "cosmos_rg" {
  name     = "cosmos-resource-group"
  location = "East US"
}

# Create Cosmos DB Account (MongoDB API)
resource "azurerm_cosmosdb_account" "cosmos_account" {
  name                = "deen-cosmos-account"
  location            = azurerm_resource_group.cosmos_rg.location
  resource_group_name = azurerm_resource_group.cosmos_rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.cosmos_rg.location
    failover_priority = 0
  }
}

# Create Cosmos DB Database
resource "azurerm_cosmosdb_mongo_database" "cosmos_db" {
  name                = "deen-mongo-db"
  resource_group_name = azurerm_resource_group.cosmos_rg.name
  account_name        = azurerm_cosmosdb_account.cosmos_account.name
}

# Create a NoSQL Collection (MongoDB API)
resource "azurerm_cosmosdb_mongo_collection" "cosmos_collection" {
  name                = "deen-collection"
  resource_group_name = azurerm_resource_group.cosmos_rg.name
  account_name        = azurerm_cosmosdb_account.cosmos_account.name
  database_name       = azurerm_cosmosdb_mongo_database.cosmos_db.name
  default_ttl_seconds = -1

  index {
    keys   = ["_id"]
    unique = true
  }
}
```

---

### **🌟 Deploy the Cosmos DB**
Run the following Terraform commands:

```sh
terraform init
terraform apply -auto-approve
```

After deployment, you can connect to the **MongoDB API** with a MongoDB client:

```sh
mongo "deen-cosmos-account.mongo.cosmos.azure.com:10255" --username adminuser --password "YourPassword"
```

---

## **🚀 Which One Should You Choose?**
| **Database Type** | **Use Case** | **Best For** |
|-------------------|-------------|-------------|
| **Azure SQL Database** (Relational) | Structured, transactional data | Financial systems, ERP, analytics |
| **Azure Cosmos DB** (NoSQL) | Schema-free, fast queries | IoT, AI, real-time apps |

---
