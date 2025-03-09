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

  route {
    name                   = "AllowSubnetCommunication"
    address_prefix         = "10.0.0.0/16"
    next_hop_type          = "VnetLocal"
  }
}


resource "azurerm_virtual_network" "myVNet" {
  name                = "myVNet"
  location            = "westus2"
  resource_group_name = "deen_test1"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "ingest" {
  name                 = "ingest-subnet"
  resource_group_name  = azurerm_virtual_network.myVNet.resource_group_name
  virtual_network_name = azurerm_virtual_network.myVNet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "data" {
  name                 = "data-subnet"
  resource_group_name  = azurerm_virtual_network.myVNet.resource_group_name
  virtual_network_name = azurerm_virtual_network.myVNet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_virtual_network.myVNet.resource_group_name
  virtual_network_name = azurerm_virtual_network.myVNet.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_subnet" "general" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_virtual_network.myVNet.resource_group_name
  virtual_network_name = azurerm_virtual_network.myVNet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_virtual_network.myVNet.resource_group_name
  virtual_network_name = azurerm_virtual_network.myVNet.name
  address_prefixes     = ["10.0.5.0/26"]
}

resource "azurerm_subnet_route_table_association" "ingest" {
  subnet_id      = azurerm_subnet.ingest.id
  route_table_id = azurerm_route_table.my_route_table.id
}

resource "azurerm_subnet_route_table_association" "data" {
  subnet_id      = azurerm_subnet.data.id
  route_table_id = azurerm_route_table.my_route_table.id
}

resource "azurerm_subnet_route_table_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  route_table_id = azurerm_route_table.my_route_table.id
}

resource "azurerm_subnet_route_table_association" "general" {
  subnet_id      = azurerm_subnet.general.id
  route_table_id = azurerm_route_table.my_route_table.id
}