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