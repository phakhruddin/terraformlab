provider "azurerm" {
  features {
    resource_group {
        prevent_deletion_if_contains_resources = false
    }
  }
}

# Create Resource Group
resource "azurerm_resource_group" "cosmos_rg" {
  name     = "cosmos-resource-group"
  location = "West US 2"
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


resource "azurerm_storage_account" "func_storage" {
  name                     = "funcstoragewrite"
  resource_group_name      = azurerm_resource_group.cosmos_rg.name
  location                 = azurerm_resource_group.cosmos_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "func_container" {
  name                  = "function-code"
  storage_account_id    = azurerm_storage_account.func_storage.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "function_plan" {
  name                = "func-write-plan"
  resource_group_name = azurerm_resource_group.cosmos_rg.name
  location            = azurerm_resource_group.cosmos_rg.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
}

data "azurerm_cosmosdb_account" "cosmos_conn" {
  name                = azurerm_cosmosdb_account.cosmos_account.name
  resource_group_name = azurerm_resource_group.cosmos_rg.name
}

resource "azurerm_linux_function_app" "func_write" {
  name                       = "func-write-cosmos"
  resource_group_name        = azurerm_resource_group.cosmos_rg.name
  location                   = azurerm_resource_group.cosmos_rg.location
  service_plan_id            = azurerm_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.func_storage.name
  storage_account_access_key = azurerm_storage_account.func_storage.primary_access_key

  site_config {
    application_stack {
      python_version = "3.8"
    }
  }

  app_settings = {
    "COSMOS_CONNECTION_STRING" = data.azurerm_cosmosdb_account.cosmos_conn.primary_key
    #"COSMOS_CONNECTION_STRING" = azurerm_cosmosdb_account.cosmos_account.connection_strings[0]
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "AzureWebJobsStorage"      = azurerm_storage_account.func_storage.primary_connection_string
  }
}

resource "azurerm_storage_blob" "function_code_blob" {
  name                   = "write-function.zip"
  storage_account_name   = azurerm_storage_account.func_storage.name
  storage_container_name = azurerm_storage_container.func_container.name
  type                   = "Block"
  source                 = "write-function.zip"  # Ensure this zip exists locally before running terraform apply
}
