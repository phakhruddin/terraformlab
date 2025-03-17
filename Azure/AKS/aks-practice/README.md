

# Azure Kubernetes Service (AKS) Administrator Practice Guide

This comprehensive guide provides a practical environment for Kubernetes administrators to practice on Azure Kubernetes Service using a hybrid approach with Terraform for infrastructure and kubectl for Kubernetes configurations.

## Architecture Overview

The practice environment includes:

1. **Azure Infrastructure** (Terraform-managed):
   - AKS cluster with advanced networking
   - Multiple node pools (system and user pools)
   - Azure Key Vault integration
   - Log Analytics workspace for monitoring
   - Virtual network with custom subnets

2. **Kubernetes Resources** (kubectl-managed):
   - Workload deployments (Nginx, sample apps)
   - Storage configurations
   - Network policies
   - RBAC configurations
   - Advanced features (StatefulSets, HPAs, etc.)

## Getting Started

### Step 1: Deploy Infrastructure with Terraform

1. Create a directory and save the Terraform configuration:
   ```bash
   mkdir aks-practice && cd aks-practice
   ```

2. Copy the content from the `AKS Administrator Practice with Terraform` artifact into a file named `main.tf`

3. Initialize and apply the Terraform configuration:
   ```bash
   terraform init
   terraform apply
   ```

4. This will create:
   - Resource Group
   - AKS Cluster with multiple node pools
   - Azure Key Vault
   - Supporting resources

### Step 2: Configure Kubernetes Resources

1. After the infrastructure is deployed, save the administration script:
   ```bash
   # Save the script content from "AKS Administrator Practice Guide" artifact
   vim aks-admin-guide.sh
   chmod +x aks-admin-guide.sh
   ```

2. Run the administration script:
   ```bash
   ./aks-admin-guide.sh
   ```

3. This will create various Kubernetes resources:
   - Namespaces, deployments, and services
   - Storage classes and persistent volumes
   - Network policies
   - RBAC configurations
   - Ingress controller and routes

## Practice Exercises

Once your environment is set up, try these administrative tasks:

### 1. Node Management

```bash
# authenticate

az aks get-credentials --resource-group aks-admin-practice-rg --name admin-practice-aks --overwrite-existing

# View node pools
kubectl get nodes --show-labels

# Cordon a node (mark as unschedulable)
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl cordon $NODE_NAME

# Drain workloads from a node
kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data

# Uncordon a node
kubectl uncordon $NODE_NAME

# Add a taint to a node
kubectl taint nodes $NODE_NAME dedicated=gpu:NoSchedule
```

### 2. Storage Administration

```bash
# View storage classes
kubectl get storageclass

# View PVCs
kubectl get pvc -n team-dev

# Expand a PVC (if your storage class supports it)
kubectl patch pvc data-pvc -n team-dev -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# View persistent volumes
kubectl get pv
```

### 3. Network Management

```bash
# Test network policies
kubectl run test-pod --image=nginx -n team-dev
kubectl exec -it test-pod -n team-dev -- curl backend-service

# View services
kubectl get svc -A

# Test ingress
INGRESS_IP=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl http://$INGRESS_IP/app1
```

### 4. Security and RBAC

```bash
# Get token for the service account
kubectl get secret dev-user-token -n team-dev -o jsonpath='{.data.token}' | base64 --decode

# Test RBAC permissions
kubectl --token=$TOKEN get pods -n team-dev
kubectl --token=$TOKEN get pods -n default  # This should fail

# View roles and bindings
kubectl get roles,rolebindings -n team-dev
```

### 5. Workload Management

```bash
# Scale deployments
kubectl scale deployment nginx-deployment -n team-dev --replicas=5

# View HPA
kubectl get hpa -n team-dev

# Test CPU load to trigger HPA
kubectl run -i --tty load-generator --rm --image=busybox -n team-dev -- /bin/sh -c "while true; do wget -q -O- http://nginx-service; done"

# View pod resource usage
kubectl top pods -n team-dev
```

### 6. Advanced Operations

```bash
# View cluster events
kubectl get events --sort-by='.lastTimestamp'

# Upgrade cluster version via Terraform
# Update kubernetes_version in your Terraform config and run:
# terraform apply

# Check container logs
kubectl logs -n team-dev -l app=nginx

# Using ConfigMaps and Secrets
kubectl get configmap app-config -n team-dev -o yaml
kubectl get secret app-secret -n team-dev -o yaml
```

## Key Vault Integration

Test the Azure Key Vault integration:

```bash
# Check if the CSI driver is working
kubectl exec -it secure-pod -n team-dev -- ls -la /mnt/secrets-store/

# View the mounted secret
kubectl exec -it secure-pod -n team-dev -- cat /mnt/secrets-store/database-password
```

## Monitoring and Troubleshooting

```bash
# View metrics for nodes
kubectl top nodes

# View metrics for pods
kubectl top pods -A

# Check pod status
kubectl get pods -n team-dev -o wide

# Describe a pod to troubleshoot issues
kubectl describe pod <pod-name> -n team-dev

# View logs
kubectl logs <pod-name> -n team-dev
```

## Cleanup

When you're done practicing, clean up all resources:

```bash
terraform destroy
```

This will remove all Azure resources created for this practice environment.

## Additional Resources

- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Kubernetes Official Documentation](https://kubernetes.io/docs/home/)
- [Terraform AKS Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster)

This practice guide provides a comprehensive environment for Kubernetes administrators to sharpen their skills with both infrastructure and application management on Azure Kubernetes Service.