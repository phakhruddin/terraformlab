# Kubernetes provider configuration
provider "kubernetes" {
  config_path = "~/.kube/config"  # Ensure your kubeconfig is correct for the cluster
}

# Read and decode the YAML file
data "local_file" "pods_yaml" {
  filename = "${path.module}/pods_config.yaml"
}

locals {
  pod_configs = yamldecode(data.local_file.pods_yaml.content).pods
}

# Create a Kubernetes pod for each pod configuration in the YAML file
resource "kubernetes_pod" "pods" {
  for_each = { for pod in local.pod_configs : pod.name => pod }

  metadata {
    name = each.value.name
    labels = each.value.labels
  }

  spec {
    container {
      image = each.value.image
      name  = each.value.name
      port {
        container_port = each.value.port
      }
    }
  }
}

output "created_pods" {
  value = [for pod in kubernetes_pod.pods : pod.metadata[0].name]
}

