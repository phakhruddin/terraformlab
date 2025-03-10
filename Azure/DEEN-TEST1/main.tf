provider "azurerm" {
  features {}
}

# Create Resource Group
resource "azurerm_resource_group" "deen_test1" {
  name     = "deen_test1"
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

data "azurerm_ssh_public_key" "existing_key" {
  name                = "deen-key1"  # Replace with the actual SSH key name
  resource_group_name = "deen_test1"   # Replace with the actual resource group name
}

# Ensure Bastion Subnet Exists
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"  # Required for Bastion
  resource_group_name  = azurerm_virtual_network.myVNet.resource_group_name
  virtual_network_name = azurerm_virtual_network.myVNet.name
  address_prefixes     = ["10.0.5.0/26"]  # Ensure this doesn't overlap
}

# Public IP for Bastion
resource "azurerm_public_ip" "bastion_ip" {
  name                = "bastion-ip"
  resource_group_name = azurerm_resource_group.deen_test1.name
  location            = azurerm_resource_group.deen_test1.location
  allocation_method   = "Static"
  sku                 = "Standard"  # Required for Bastion
}

# Azure Bastion Host
resource "azurerm_bastion_host" "deen_bastion" {
  name                = "deen-bastion"
  resource_group_name = azurerm_resource_group.deen_test1.name
  location            = azurerm_resource_group.deen_test1.location

  sku = "Standard"  # Enables native client SSH support

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}

# Create Public IP for ALB (Publicly Accessible)
resource "azurerm_public_ip" "alb_public_ip" {
  name                = "alb-public-ip"
  resource_group_name = azurerm_resource_group.deen_test1.name
  location            = azurerm_resource_group.deen_test1.location
  allocation_method   = "Static"
  sku                 = "Standard" # Required for ALB
}

# Create Application Load Balancer (ALB) in Public Subnet
resource "azurerm_lb" "public_alb" {
  name                = "public-alb"
  resource_group_name = azurerm_resource_group.deen_test1.name
  location            = azurerm_resource_group.deen_test1.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.alb_public_ip.id
  }
}

# Create Backend Pool for ALB
resource "azurerm_lb_backend_address_pool" "alb_backend_pool" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.public_alb.id
}

# Create Health Probe for ALB
resource "azurerm_lb_probe" "alb_health_probe" {
  name            = "http-health-probe"
  loadbalancer_id = azurerm_lb.public_alb.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Create Load Balancer Rule for HTTP Traffic
resource "azurerm_lb_rule" "alb_http_rule" {
  name                    = "http-rule"
  loadbalancer_id         = azurerm_lb.public_alb.id
  protocol                = "Tcp"
  frontend_port           = 80
  backend_port            = 80
  frontend_ip_configuration_name = "public-frontend"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.alb_backend_pool.id]
  probe_id               = azurerm_lb_probe.alb_health_probe.id
}

# Network Security Group for VMSS (Allow HTTP & SSH)
resource "azurerm_network_security_group" "vmss_nsg" {
  name                = "vmss-nsg"
  resource_group_name = azurerm_resource_group.deen_test1.name
  location            = azurerm_resource_group.deen_test1.location

  security_rule {
    name                       = "Allow-HTTP"
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
    name                       = "Allow-SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Attach NSG to Ingest Subnet
resource "azurerm_subnet_network_security_group_association" "ingest_nsg_assoc" {
  subnet_id                 = azurerm_subnet.ingest.id
  network_security_group_id = azurerm_network_security_group.vmss_nsg.id
}

# VMSS with Nginx, Connected to ALB
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "deen-vmss"
  resource_group_name = azurerm_resource_group.deen_test1.name
  location            = azurerm_resource_group.deen_test1.location
  sku                 = "Standard_B1s"
  instances           = 2 # Start with 2 instances, auto-scale enabled

  admin_username      = "azureuser"
  disable_password_authentication = true

  upgrade_mode = "Rolling"  # Required for automatic OS upgrades

  rolling_upgrade_policy {
    max_batch_instance_percent              = 10   # Up to 20% of instances upgraded at a time
    max_unhealthy_instance_percent          = 10   # Up to 10% of instances can be unhealthy
    max_unhealthy_upgraded_instance_percent = 5    # Only 5% upgraded instances can be unhealthy
    pause_time_between_batches              = "PT0S" # No wait time between batch upgrades
  }

  # Add Health Probe for VMSS Rolling Upgrade
  health_probe_id = azurerm_lb_probe.alb_health_probe.id

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.existing_key.public_key
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "vmss-ipconfig"
      primary   = true
      subnet_id = azurerm_subnet.ingest.id

      load_balancer_backend_address_pool_ids = [
        azurerm_lb_backend_address_pool.alb_backend_pool.id
      ]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18_04-lts-gen2"
    version   = "latest"
  }

  # Install & Start Nginx Automatically
  custom_data = base64encode(<<EOF
#!/bin/bash
apt update -y
apt install nginx -y
systemctl start nginx
systemctl enable nginx
EOF
  )

  # Auto-scale Policy
  automatic_os_upgrade_policy {
    disable_automatic_rollback = false
    enable_automatic_os_upgrade = true
  }
}