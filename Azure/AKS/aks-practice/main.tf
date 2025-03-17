provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Variables
variable "resource_group_name" {
  default = "aks-admin-practice-rg"
}

variable "location" {
  default = "westus2"
}

variable "cluster_name" {
  default = "admin-practice-aks"
}

variable "kubernetes_version" {
  default = "1.30.9"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# AKS Cluster with minimal configuration
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "systempool"
    node_count          = 1
    vm_size             = "Standard_B2s"  # Smallest viable size for AKS
    type                = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"  # Simpler networking option
    pod_cidr       = "10.244.0.0/16"
  }
  
  # Disable add-ons to save resources
  azure_policy_enabled           = false
  http_application_routing_enabled = false
}

# Output values
output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}