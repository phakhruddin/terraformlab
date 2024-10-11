To create a simple Terraform lab to practice using a `for_each` loop that reads from a YAML input file and creates resources, we will focus on provisioning Kubernetes pods using the **Kubernetes provider**. We'll use a YAML file to define multiple pod configurations, and Terraform will loop through the YAML file to create the respective pods.

### Lab Setup:

1.  **Terraform reads a YAML input file** using the `for_each` loop.
2.  **Kubernetes provider** is used to provision pods based on the data in the YAML file.
3.  The lab will include a simple `main.tf` file, a YAML configuration file, and use the `yaml_decode` function to convert the YAML file into a format that Terraform can process.

* * *

### 1\. **Install Required Tools:**

*   Install Terraform:
    
    ```bash
    brew install terraform
    ```
    
*   Install `kubectl` and Minikube (if you want to test locally):
    
    ```bash
    brew install kubectl
    brew install minikube
    ```
    

Start Minikube:

```bash
minikube start
```

Ensure Minikube's Kubernetes config is used:

```bash
kubectl config use-context minikube
```

### 2\. **Create the YAML Input File**

This YAML file defines the pod configurations for Kubernetes.

#### File: `pods_config.yaml`

```yaml
pods:
  - name: "nginx-pod"
    image: "nginx"
    port: 80
    labels:
      app: "nginx"
  - name: "redis-pod"
    image: "redis"
    port: 6379
    labels:
      app: "redis"
```

### 3\. **Create the Terraform Configuration**

#### File: `main.tf`

```hcl
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
```

### 4\. **Explanation of Key Parts:**

*   **YAML Decoding**:
    
    *   The `data "local_file"` block reads the `pods_config.yaml` file.
    *   The `yamldecode()` function converts the YAML file content into a data structure that Terraform can work with.
*   **for\_each Loop**:
    
    *   We loop through the `pod_configs` list (each pod configuration) using `for_each`. Terraform creates a Kubernetes pod for each entry in the YAML file.
*   **Kubernetes Provider**:
    
    *   The `kubernetes_pod` resource block provisions Kubernetes pods. Each pod is configured according to the YAML input (name, image, port, and labels).

### 5\. **Run the Lab:**

1.  Initialize Terraform:
    
    ```bash
    terraform init
    ```
    
2.  Validate the configuration:
    
    ```bash
    terraform validate
    ```
    
3.  Plan the deployment:
    
    ```bash
    terraform plan
    ```
    
4.  Apply the configuration:
    
    ```bash
    terraform apply
    ```
    
5.  Check if the pods were created:
    
    ```bash
    kubectl get pods
    ```
    

You should see the `nginx-pod` and `redis-pod` running.

### 6\. **Clean Up Resources**:

After testing, clean up the Kubernetes resources by running:

```bash
terraform destroy
```

* * *

### Summary:

In this lab, you practiced using the `for_each` loop in Terraform to read from a YAML input file and create multiple Kubernetes pods based on the configurations defined in the YAML file. This approach is flexible and can be expanded to manage more complex Kubernetes resources or other infrastructure components.
