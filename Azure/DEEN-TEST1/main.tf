provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "deen_test1" {
  name     = "DEEN-TEST1"
  location = "West US 2"
}


# Create Network Watcher
resource "azurerm_network_watcher" "network_watcher" {
  name                = "NetworkWatcher_westus2"
  resource_group_name = "NetworkWatcherRG"  # Microsoft default resource group for Network Watcher
  location            = "West US 2"
}

# Create Route Table
resource "azurerm_route_table" "my_route_table" {
  name                = "myRouteTable"
  resource_group_name = azurerm_resource_group.deen_test1.name
  location            = azurerm_resource_group.deen_test1.location
}
