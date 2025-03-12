Here's a **Terraform** script to deploy a **simple AKS (Azure Kubernetes Service) cluster** with worker nodes and a pod running in a **single namespace**.

---

### **Steps Covered:**
1. **Create an AKS Cluster** with a single node pool.
2. **Set up a Kubernetes Namespace**.
3. **Deploy an Nginx Pod** in that namespace.

---

### **🔹 `main.tf` (Terraform AKS Configuration)**
```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "aks-resource-group"
  location = "West US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "myAKSCluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "myaks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_namespace" "myns" {
  metadata {
    name = "my-namespace"
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx-deployment"
    namespace = kubernetes_namespace.myns.metadata.0.name
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "nginx"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }
      spec {
        container {
          image = "nginx:latest"
          name  = "nginx-container"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx_service" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.myns.metadata.0.name
  }

  spec {
    selector = {
      app = "nginx"
    }
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
```

---

### **🔹 Deployment Instructions**
1. **Initialize Terraform:**
   ```sh
   terraform init
   ```

2. **Plan the Deployment:**
   ```sh
   terraform plan
   ```

3. **Apply the Configuration:**
   ```sh
   terraform apply -auto-approve
   ```

4. **Get Kubernetes Config & Test:**
   ```sh
   az aks get-credentials --resource-group aks-resource-group --name myAKSCluster
   kubectl get pods -n my-namespace
   kubectl get svc -n my-namespace
   ```

---

### **💡 Features:**
✅ **Creates an AKS Cluster** (1 worker node)  
✅ **Deploys an Nginx pod** in a custom namespace  
✅ **Exposes the pod via LoadBalancer**  

---

### ⚠️ **Output:**
⚠️ **Terraform will create an AKS Cluster with a single node pool**.  
⚠️ **The default namespace is named `my-namespace`**.  
⚠️ **The default pod is named `nginx`**.  
⚠️ **The default port is `80`**.  
⚠️ **The default protocol is `TCP`**.  
⚠️ **The default target port is `80`**.  
⚠️     **The service is exposed via a LoadBalancer**.  
⚠️  **The LoadBalancer is named `nginx-lb`**.  
⚠️  **The LoadBalancer is exposed on port `80`**.  
⚠️  **The LoadBalancer is exposed on protocol `TCP`**.  
⚠️  **The LoadBalancer is exposed on target port `80`**.  
⚠️  **The LoadBalancer is named `nginx-lb`**.  
⚠  

```sh
terraform apply --auto-approve                                                

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # azurerm_kubernetes_cluster.aks will be created
  + resource "azurerm_kubernetes_cluster" "aks" {
      + current_kubernetes_version          = (known after apply)
      + dns_prefix                          = "myaks"
      + fqdn                                = (known after apply)
      + http_application_routing_zone_name  = (known after apply)
      + id                                  = (known after apply)
      + kube_admin_config                   = (sensitive value)
      + kube_admin_config_raw               = (sensitive value)
      + kube_config                         = (sensitive value)
      + kube_config_raw                     = (sensitive value)
      + kubernetes_version                  = (known after apply)
      + location                            = "westus2"
      + name                                = "myAKSCluster"
      + node_os_upgrade_channel             = "NodeImage"
      + node_resource_group                 = (known after apply)
      + node_resource_group_id              = (known after apply)
      + oidc_issuer_url                     = (known after apply)
      + portal_fqdn                         = (known after apply)
      + private_cluster_enabled             = false
      + private_cluster_public_fqdn_enabled = false
      + private_dns_zone_id                 = (known after apply)
      + private_fqdn                        = (known after apply)
      + resource_group_name                 = "aks-resource-group"
      + role_based_access_control_enabled   = true
      + run_command_enabled                 = true
      + sku_tier                            = "Free"
      + support_plan                        = "KubernetesOfficial"
      + workload_identity_enabled           = false

      + default_node_pool {
          + kubelet_disk_type    = (known after apply)
          + max_pods             = (known after apply)
          + name                 = "default"
          + node_count           = 1
          + node_labels          = (known after apply)
          + orchestrator_version = (known after apply)
          + os_disk_size_gb      = (known after apply)
          + os_disk_type         = "Managed"
          + os_sku               = (known after apply)
          + scale_down_mode      = "Delete"
          + type                 = "VirtualMachineScaleSets"
          + ultra_ssd_enabled    = false
          + vm_size              = "Standard_D2s_v3"
          + workload_runtime     = (known after apply)
        }

      + identity {
          + principal_id = (known after apply)
          + tenant_id    = (known after apply)
          + type         = "SystemAssigned"
        }
    }

  # azurerm_resource_group.rg will be created
  + resource "azurerm_resource_group" "rg" {
      + id       = (known after apply)
      + location = "westus2"
      + name     = "aks-resource-group"
    }

  # kubernetes_deployment.nginx will be created
  + resource "kubernetes_deployment" "nginx" {
      + id               = (known after apply)
      + wait_for_rollout = true

      + metadata {
          + generation       = (known after apply)
          + labels           = {
              + "app" = "nginx"
            }
          + name             = "nginx-deployment"
          + namespace        = "my-namespace"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + spec {
          + min_ready_seconds         = 0
          + paused                    = false
          + progress_deadline_seconds = 600
          + replicas                  = "1"
          + revision_history_limit    = 10

          + selector {
              + match_labels = {
                  + "app" = "nginx"
                }
            }

          + template {
              + metadata {
                  + generation       = (known after apply)
                  + labels           = {
                      + "app" = "nginx"
                    }
                  + name             = (known after apply)
                  + resource_version = (known after apply)
                  + uid              = (known after apply)
                }
              + spec {
                  + automount_service_account_token  = true
                  + dns_policy                       = "ClusterFirst"
                  + enable_service_links             = true
                  + host_ipc                         = false
                  + host_network                     = false
                  + host_pid                         = false
                  + hostname                         = (known after apply)
                  + node_name                        = (known after apply)
                  + restart_policy                   = "Always"
                  + scheduler_name                   = (known after apply)
                  + service_account_name             = (known after apply)
                  + share_process_namespace          = false
                  + termination_grace_period_seconds = 30

                  + container {
                      + image                      = "nginx:latest"
                      + image_pull_policy          = (known after apply)
                      + name                       = "nginx-container"
                      + stdin                      = false
                      + stdin_once                 = false
                      + termination_message_path   = "/dev/termination-log"
                      + termination_message_policy = (known after apply)
                      + tty                        = false

                      + port {
                          + container_port = 80
                          + protocol       = "TCP"
                        }
                    }
                }
            }
        }
    }

  # kubernetes_namespace.myns will be created
  + resource "kubernetes_namespace" "myns" {
      + id                               = (known after apply)
      + wait_for_default_service_account = false

      + metadata {
          + generation       = (known after apply)
          + name             = "my-namespace"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }
    }

  # kubernetes_service.nginx_service will be created
  + resource "kubernetes_service" "nginx_service" {
      + id                     = (known after apply)
      + status                 = (known after apply)
      + wait_for_load_balancer = true

      + metadata {
          + generation       = (known after apply)
          + name             = "nginx-service"
          + namespace        = "my-namespace"
          + resource_version = (known after apply)
          + uid              = (known after apply)
        }

      + spec {
          + allocate_load_balancer_node_ports = true
          + cluster_ip                        = (known after apply)
          + cluster_ips                       = (known after apply)
          + external_traffic_policy           = (known after apply)
          + health_check_node_port            = (known after apply)
          + internal_traffic_policy           = (known after apply)
          + ip_families                       = (known after apply)
          + ip_family_policy                  = (known after apply)
          + publish_not_ready_addresses       = false
          + selector                          = {
              + "app" = "nginx"
            }
          + session_affinity                  = "None"
          + type                              = "LoadBalancer"

          + port {
              + node_port   = (known after apply)
              + port        = 80
              + protocol    = "TCP"
              + target_port = "80"
            }
        }
    }

Plan: 5 to add, 0 to change, 0 to destroy.
```
---
```sh
az aks get-credentials --resource-group aks-resource-group --name myAKSCluster --overwrite-existing-credentials
```
```sh
Merged "myAKSCluster" as current context in ~/.kube/config
```
```
bayawchik@Bayas-MacBook-Pro simple % kubectl get nodes -o wide
NAME                              STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-default-19023758-vmss000000   Ready    <none>   13m   v1.30.9   10.224.0.4    <none>        Ubuntu 22.04.5 LTS   5.15.0-1081-azure   containerd://1.7.25-1
bayawchik@Bayas-MacBook-Pro simple % kubectl get pods -n my-namespace
kubectl get svc -n my-namespace
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-866d97c778-86thp   1/1     Running   0          12m
NAME            TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)        AGE
nginx-service   LoadBalancer   10.0.202.20   4.149.75.178   80:31155/TCP   12m
```
🔍 1. Check Node Configuration

Since your worker node (aks-default-19023758-vmss000000) is running Ubuntu 22.04.5 LTS with containerd as the runtime, you can inspect its configuration:

Check Node Details


```
bayawchik@Bayas-MacBook-Pro simple % kubectl describe node aks-default-19023758-vmss000000
Name:               aks-default-19023758-vmss000000
Roles:              <none>
Labels:             agentpool=default
                    beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/instance-type=Standard_D2s_v3
                    beta.kubernetes.io/os=linux
                    failure-domain.beta.kubernetes.io/region=westus2
                    failure-domain.beta.kubernetes.io/zone=0
                    kubernetes.azure.com/agentpool=default
                    kubernetes.azure.com/azure-cni-overlay=true
                    kubernetes.azure.com/cluster=MC_aks-resource-group_myAKSCluster_westus2
                    kubernetes.azure.com/consolidated-additional-properties=e775e68b-ff68-11ef-9488-96394073d99a
                    kubernetes.azure.com/kubelet-identity-client-id=9f3f333b-5fcc-4105-87d4-dcc309cb2caf
                    kubernetes.azure.com/mode=system
                    kubernetes.azure.com/network-name=aks-vnet-31244857
                    kubernetes.azure.com/network-resourcegroup=aks-resource-group
                    kubernetes.azure.com/network-subnet=aks-subnet
                    kubernetes.azure.com/network-subscription=f35a1694-aed9-45ac-bad8-6f23ceb8b2af
                    kubernetes.azure.com/node-image-version=AKSUbuntu-2204gen2containerd-202502.26.0
                    kubernetes.azure.com/nodenetwork-vnetguid=b4a2926a-ebad-43ba-91ba-46637e12cd6e
                    kubernetes.azure.com/nodepool-type=VirtualMachineScaleSets
                    kubernetes.azure.com/os-sku=Ubuntu
                    kubernetes.azure.com/podnetwork-type=overlay
                    kubernetes.azure.com/role=agent
                    kubernetes.azure.com/storageprofile=managed
                    kubernetes.azure.com/storagetier=Premium_LRS
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=aks-default-19023758-vmss000000
                    kubernetes.io/os=linux
                    node.kubernetes.io/instance-type=Standard_D2s_v3
                    storageprofile=managed
                    storagetier=Premium_LRS
                    topology.disk.csi.azure.com/zone=
                    topology.kubernetes.io/region=westus2
                    topology.kubernetes.io/zone=0
Annotations:        alpha.kubernetes.io/provided-node-ip: 10.224.0.4
                    csi.volume.kubernetes.io/nodeid:
                      {"disk.csi.azure.com":"aks-default-19023758-vmss000000","file.csi.azure.com":"aks-default-19023758-vmss000000"}
                    node.alpha.kubernetes.io/ttl: 0
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Wed, 12 Mar 2025 10:42:11 -0700
Taints:             <none>
Unschedulable:      false
Lease:
  HolderIdentity:  aks-default-19023758-vmss000000
  AcquireTime:     <unset>
  RenewTime:       Wed, 12 Mar 2025 10:56:51 -0700
Conditions:
  Type                          Status  LastHeartbeatTime                 LastTransitionTime                Reason                          Message
  ----                          ------  -----------------                 ------------------                ------                          -------
  KubeletProblem                False   Wed, 12 Mar 2025 10:54:34 -0700   Wed, 12 Mar 2025 10:44:03 -0700   KubeletIsUp                     kubelet service is up
  FrequentUnregisterNetDevice   False   Wed, 12 Mar 2025 10:54:34 -0700   Wed, 12 Mar 2025 10:44:03 -0700   NoFrequentUnregisterNetDevice   node is functioning properly
  FrequentContainerdRestart     False   Wed, 12 Mar 2025 10:54:34 -0700   Wed, 12 Mar 2025 10:44:03 -0700   NoFrequentContainerdRestart     containerd is functioning properly
  ContainerRuntimeProblem       False   Wed, 12 Mar 2025 10:54:34 -0700   Wed, 12 Mar 2025 10:44:03 -0700   ContainerRuntimeIsUp            container runtime service is up
  FrequentKubeletRestart        False   Wed, 12 Mar 2025 10:54:34 -0700   Wed, 12 Mar 2025 10:44:03 -0700   NoFrequentKubeletRestart        kubelet is functioning properly
  FrequentDockerRestart         False   Wed, 12 Mar 2025 10:54:34 -0700   Wed, 12 Mar 2025 10:44:03 -0700   NoFrequentDockerRestart         docker is functioning properly
  FilesystemCorruptionProblem   False   Wed, 12 Mar 2025 10:54:34 -0700   Wed, 12 Mar 2025 10:44:03 -0700   FilesystemIsOK                  Filesystem is healthy
  KernelDeadlock                False   Wed, 12 Mar 2025 10:54:34 -0700   Wed, 12 Mar 2025 10:44:03 -0700   KernelHasNoDeadlock             kernel has no deadlock
  ReadonlyFilesystem            False   Wed, 12 Mar 2025 10:54:34 -0700   Wed, 12 Mar 2025 10:44:03 -0700   FilesystemIsNotReadOnly         Filesystem is not read-only
  VMEventScheduled              False   Wed, 12 Mar 2025 10:54:34 -0700   Wed, 12 Mar 2025 10:44:32 -0700   NoVMEventScheduled              VM has no scheduled event
  MemoryPressure                False   Wed, 12 Mar 2025 10:53:26 -0700   Wed, 12 Mar 2025 10:42:11 -0700   KubeletHasSufficientMemory      kubelet has sufficient memory available
  DiskPressure                  False   Wed, 12 Mar 2025 10:53:26 -0700   Wed, 12 Mar 2025 10:42:11 -0700   KubeletHasNoDiskPressure        kubelet has no disk pressure
  PIDPressure                   False   Wed, 12 Mar 2025 10:53:26 -0700   Wed, 12 Mar 2025 10:42:11 -0700   KubeletHasSufficientPID         kubelet has sufficient PID available
  Ready                         True    Wed, 12 Mar 2025 10:53:26 -0700   Wed, 12 Mar 2025 10:42:33 -0700   KubeletReady                    kubelet is posting ready status
Addresses:
  InternalIP:  10.224.0.4
  Hostname:    aks-default-19023758-vmss000000
Capacity:
  cpu:                2
  ephemeral-storage:  129886128Ki
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             8130044Ki
  pods:               250
Allocatable:
  cpu:                1900m
  ephemeral-storage:  119703055367
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             5930492Ki
  pods:               250
System Info:
  Machine ID:                 cfe61dbf572a4e1fa261e2e336e2436a
  System UUID:                adc0406e-b380-4ff3-844c-83bb9b8f1983
  Boot ID:                    2b988a95-ee18-468a-b791-c22a24bf2587
  Kernel Version:             5.15.0-1081-azure
  OS Image:                   Ubuntu 22.04.5 LTS
  Operating System:           linux
  Architecture:               amd64
  Container Runtime Version:  containerd://1.7.25-1
  Kubelet Version:            v1.30.9
  Kube-Proxy Version:         v1.30.9
ProviderID:                   azure:///subscriptions/f35a1694-aed9-45ac-bad8-6f23ceb8b2af/resourceGroups/mc_aks-resource-group_myakscluster_westus2/providers/Microsoft.Compute/virtualMachineScaleSets/aks-default-19023758-vmss/virtualMachines/0
Non-terminated Pods:          (14 in total)
  Namespace                   Name                                   CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                                   ------------  ----------  ---------------  -------------  ---
  kube-system                 azure-cns-vkkkq                        40m (2%)      40m (2%)    250Mi (4%)       250Mi (4%)     14m
  kube-system                 azure-ip-masq-agent-hdddb              100m (5%)     500m (26%)  50Mi (0%)        250Mi (4%)     14m
  kube-system                 cloud-node-manager-dk5kp               50m (2%)      0 (0%)      50Mi (0%)        512Mi (8%)     14m
  kube-system                 coredns-659fcb469c-cnd44               100m (5%)     3 (157%)    70Mi (1%)        500Mi (8%)     14m
  kube-system                 coredns-659fcb469c-n8ls9               100m (5%)     3 (157%)    70Mi (1%)        500Mi (8%)     15m
  kube-system                 coredns-autoscaler-bfcb7c74c-p7cpq     20m (1%)      200m (10%)  10Mi (0%)        500Mi (8%)     15m
  kube-system                 csi-azuredisk-node-lkttd               30m (1%)      0 (0%)      60Mi (1%)        1400Mi (24%)   14m
  kube-system                 csi-azurefile-node-zsmnj               30m (1%)      0 (0%)      60Mi (1%)        600Mi (10%)    14m
  kube-system                 konnectivity-agent-8699948c5c-9r4vq    20m (1%)      1 (52%)     20Mi (0%)        1Gi (17%)      15m
  kube-system                 konnectivity-agent-8699948c5c-tskkq    20m (1%)      1 (52%)     20Mi (0%)        1Gi (17%)      15m
  kube-system                 kube-proxy-tq6f4                       100m (5%)     0 (0%)      0 (0%)           0 (0%)         14m
  kube-system                 metrics-server-5dfc656944-n72cl        156m (8%)     251m (13%)  134Mi (2%)       404Mi (6%)     14m
  kube-system                 metrics-server-5dfc656944-p7g5l        156m (8%)     251m (13%)  134Mi (2%)       404Mi (6%)     14m
  my-namespace                nginx-deployment-866d97c778-86thp      0 (0%)        0 (0%)      0 (0%)           0 (0%)         13m
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                922m (48%)   9242m (486%)
  memory             928Mi (16%)  7368Mi (127%)
  ephemeral-storage  0 (0%)       0 (0%)
  hugepages-1Gi      0 (0%)       0 (0%)
  hugepages-2Mi      0 (0%)       0 (0%)
Events:
  Type     Reason                   Age                From                                                          Message
  ----     ------                   ----               ----                                                          -------
  Normal   Starting                 14m                kube-proxy                                                    
  Warning  InvalidDiskCapacity      14m                kubelet                                                       invalid capacity 0 on image filesystem
  Normal   NodeHasSufficientMemory  14m (x2 over 14m)  kubelet                                                       Node aks-default-19023758-vmss000000 status is now: NodeHasSufficientMemory
  Normal   NodeHasNoDiskPressure    14m (x2 over 14m)  kubelet                                                       Node aks-default-19023758-vmss000000 status is now: NodeHasNoDiskPressure
  Normal   NodeHasSufficientPID     14m (x2 over 14m)  kubelet                                                       Node aks-default-19023758-vmss000000 status is now: NodeHasSufficientPID
  Normal   CreatedNNC               14m                dnc-rc/node-reconciler                                        Created NodeNetworkConfig aks-default-19023758-vmss000000
  Normal   NodeAllocatableEnforced  14m                kubelet                                                       Updated Node Allocatable limit across pods
  Normal   RegisteredNode           14m                node-controller                                               Node aks-default-19023758-vmss000000 event: Registered Node aks-default-19023758-vmss000000 in Controller
  Normal   NodeReady                14m                kubelet                                                       Node aks-default-19023758-vmss000000 status is now: NodeReady
  Warning  ContainerdStart          12m (x2 over 12m)  systemd-monitor                                               Starting containerd container runtime...
  Normal   NoVMEventScheduled       12m                custom-scheduledevents-consolidated-condition-plugin-monitor  Node condition VMEventScheduled is now: Unknown, reason: NoVMEventScheduled, message: "IMDS query failed, exit code: 28\nConnection timed out after 24 seconds."
  Warning  PreemptScheduled         12m                custom-scheduledevents-consolidated-preempt-plugin-monitor    IMDS query failed, exit code: 28
Connection timed out after 24 seconds.
  Normal  NoVMEventScheduled  12m  custom-scheduledevents-consolidated-condition-plugin-monitor  Node condition VMEventScheduled is now: False, reason: NoVMEventScheduled, message: "VM has no scheduled event"
bayawchik@Bayas-MacBook-Pro simple % kubectl get pods -A -o wide
NAMESPACE      NAME                                  READY   STATUS    RESTARTS   AGE   IP             NODE                              NOMINATED NODE   READINESS GATES
kube-system    azure-cns-vkkkq                       1/1     Running   0          15m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    azure-ip-masq-agent-hdddb             1/1     Running   0          15m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    cloud-node-manager-dk5kp              1/1     Running   0          15m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    coredns-659fcb469c-cnd44              1/1     Running   0          14m   10.244.0.227   aks-default-19023758-vmss000000   <none>           <none>
kube-system    coredns-659fcb469c-n8ls9              1/1     Running   0          16m   10.244.0.65    aks-default-19023758-vmss000000   <none>           <none>
kube-system    coredns-autoscaler-bfcb7c74c-p7cpq    1/1     Running   0          16m   10.244.0.78    aks-default-19023758-vmss000000   <none>           <none>
kube-system    csi-azuredisk-node-lkttd              3/3     Running   0          15m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    csi-azurefile-node-zsmnj              3/3     Running   0          15m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    konnectivity-agent-8699948c5c-9r4vq   1/1     Running   0          16m   10.244.0.61    aks-default-19023758-vmss000000   <none>           <none>
kube-system    konnectivity-agent-8699948c5c-tskkq   1/1     Running   0          16m   10.244.0.173   aks-default-19023758-vmss000000   <none>           <none>
kube-system    kube-proxy-tq6f4                      1/1     Running   0          15m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    metrics-server-5dfc656944-n72cl       2/2     Running   0          14m   10.244.0.132   aks-default-19023758-vmss000000   <none>           <none>
kube-system    metrics-server-5dfc656944-p7g5l       2/2     Running   0          14m   10.244.0.218   aks-default-19023758-vmss000000   <none>           <none>
my-namespace   nginx-deployment-866d97c778-86thp     1/1     Running   0          14m   10.244.0.84    aks-default-19023758-vmss000000   <none>           <none>
bayawchik@Bayas-MacBook-Pro simple % kubectl describe pod nginx-deployment-866d97c778-86thp -n my-namespace
Name:             nginx-deployment-866d97c778-86thp
Namespace:        my-namespace
Priority:         0
Service Account:  default
Node:             aks-default-19023758-vmss000000/10.224.0.4
Start Time:       Wed, 12 Mar 2025 10:43:05 -0700
Labels:           app=nginx
                  pod-template-hash=866d97c778
Annotations:      <none>
Status:           Running
IP:               10.244.0.84
IPs:
  IP:           10.244.0.84
Controlled By:  ReplicaSet/nginx-deployment-866d97c778
Containers:
  nginx-container:
    Container ID:   containerd://8bcb5fdf01dd1d98d5485d7e147c6592339a826b1f4d676e1c71e4e7dd7e0d8b
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:9d6b58feebd2dbd3c56ab5853333d627cc6e281011cfd6050fa4bcf2072c9496
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Wed, 12 Mar 2025 10:43:11 -0700
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-8zgdn (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-8zgdn:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  15m   default-scheduler  Successfully assigned my-namespace/nginx-deployment-866d97c778-86thp to aks-default-19023758-vmss000000
  Normal  Pulling    15m   kubelet            Pulling image "nginx:latest"
  Normal  Pulled     15m   kubelet            Successfully pulled image "nginx:latest" in 5.7s (5.7s including waiting). Image size: 72195292 bytes.
  Normal  Created    15m   kubelet            Created container nginx-container
  Normal  Started    15m   kubelet            Started container nginx-container
bayawchik@Bayas-MacBook-Pro simple % kubectl logs nginx-deployment-866d97c778-86thp -n my-namespace
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2025/03/12 17:43:11 [notice] 1#1: using the "epoll" event method
2025/03/12 17:43:11 [notice] 1#1: nginx/1.27.4
2025/03/12 17:43:11 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
2025/03/12 17:43:11 [notice] 1#1: OS: Linux 5.15.0-1081-azure
2025/03/12 17:43:11 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2025/03/12 17:43:11 [notice] 1#1: start worker processes
2025/03/12 17:43:11 [notice] 1#1: start worker process 28
2025/03/12 17:43:11 [notice] 1#1: start worker process 29
bayawchik@Bayas-MacBook-Pro simple % kubectl get pod nginx-deployment-866d97c778-86thp -n my-namespace -o yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2025-03-12T17:43:04Z"
  generateName: nginx-deployment-866d97c778-
  labels:
    app: nginx
    pod-template-hash: 866d97c778
  name: nginx-deployment-866d97c778-86thp
  namespace: my-namespace
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: nginx-deployment-866d97c778
    uid: 0fe4ffc2-12e5-4eba-ae3d-b877982e7883
  resourceVersion: "1407"
  uid: 89fcd505-cae1-4a13-9ac0-c26837bd5f93
spec:
  automountServiceAccountToken: true
  containers:
  - image: nginx:latest
    imagePullPolicy: Always
    name: nginx-container
    ports:
    - containerPort: 80
      protocol: TCP
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-8zgdn
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: aks-default-19023758-vmss000000
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  shareProcessNamespace: false
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: kube-api-access-8zgdn
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2025-03-12T17:43:11Z"
    status: "True"
    type: PodReadyToStartContainers
  - lastProbeTime: null
    lastTransitionTime: "2025-03-12T17:43:05Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2025-03-12T17:43:11Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2025-03-12T17:43:11Z"
    status: "True"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2025-03-12T17:43:05Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: containerd://8bcb5fdf01dd1d98d5485d7e147c6592339a826b1f4d676e1c71e4e7dd7e0d8b
    image: docker.io/library/nginx:latest
    imageID: docker.io/library/nginx@sha256:9d6b58feebd2dbd3c56ab5853333d627cc6e281011cfd6050fa4bcf2072c9496
    lastState: {}
    name: nginx-container
    ready: true
    restartCount: 0
    started: true
    state:
      running:
        startedAt: "2025-03-12T17:43:11Z"
  hostIP: 10.224.0.4
  hostIPs:
  - ip: 10.224.0.4
  phase: Running
  podIP: 10.244.0.84
  podIPs:
  - ip: 10.244.0.84
  qosClass: BestEffort
  startTime: "2025-03-12T17:43:05Z"
  ```
  ---

  ```bayawchik@Bayas-MacBook-Pro simple % kubectl exec -it nginx-deployment-866d97c778-86thp -n my-namespace -- /bin/sh
# uname -a
Linux nginx-deployment-866d97c778-86thp 5.15.0-1081-azure #90-Ubuntu SMP Tue Jan 28 05:15:28 UTC 2025 x86_64 GNU/Linux
# exit
bayawchik@Bayas-MacBook-Pro simple % kubectl describe svc nginx-service -n my-namespace
Name:                     nginx-service
Namespace:                my-namespace
Labels:                   <none>
Annotations:              <none>
Selector:                 app=nginx
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.0.202.20
IPs:                      10.0.202.20
LoadBalancer Ingress:     4.149.75.178 (VIP)
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31155/TCP
Endpoints:                10.244.0.84:80
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  18m   service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   17m   service-controller  Ensured load balancer
  ```

  ---


List All Running System Pods

To see what is running on the node:

```kubectl get pods -A -o wide```

```NAMESPACE      NAME                                  READY   STATUS    RESTARTS   AGE   IP             NODE                              NOMINATED NODE   READINESS GATES
kube-system    azure-cns-vkkkq                       1/1     Running   0          51m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    azure-ip-masq-agent-hdddb             1/1     Running   0          51m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    cloud-node-manager-dk5kp              1/1     Running   0          51m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    coredns-659fcb469c-cnd44              1/1     Running   0          51m   10.244.0.227   aks-default-19023758-vmss000000   <none>           <none>
kube-system    coredns-659fcb469c-n8ls9              1/1     Running   0          52m   10.244.0.65    aks-default-19023758-vmss000000   <none>           <none>
kube-system    coredns-autoscaler-bfcb7c74c-p7cpq    1/1     Running   0          52m   10.244.0.78    aks-default-19023758-vmss000000   <none>           <none>
kube-system    csi-azuredisk-node-lkttd              3/3     Running   0          51m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    csi-azurefile-node-zsmnj              3/3     Running   0          51m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    konnectivity-agent-56cc695447-4vnfq   1/1     Running   0          28m   10.244.0.7     aks-default-19023758-vmss000000   <none>           <none>
kube-system    konnectivity-agent-56cc695447-f9mhq   1/1     Running   0          28m   10.244.0.169   aks-default-19023758-vmss000000   <none>           <none>
kube-system    kube-proxy-tq6f4                      1/1     Running   0          51m   10.224.0.4     aks-default-19023758-vmss000000   <none>           <none>
kube-system    metrics-server-5dfc656944-n72cl       2/2     Running   0          51m   10.244.0.132   aks-default-19023758-vmss000000   <none>           <none>
kube-system    metrics-server-5dfc656944-p7g5l       2/2     Running   0          51m   10.244.0.218   aks-default-19023758-vmss000000   <none>           <none>
my-namespace   nginx-deployment-866d97c778-86thp     1/1     Running   0          50m   10.244.0.84    aks-default-19023758-vmss000000   <none>           <none>
```

🔍 2. Check Nginx Pod Deployment

You deployed Nginx via a Kubernetes Deployment. To verify how it is installed and running:

Check Pod Details

```kubectl describe pod nginx-deployment-866d97c778-86thp -n my-namespace
Name:             nginx-deployment-866d97c778-86thp
Namespace:        my-namespace
Priority:         0
Service Account:  default
Node:             aks-default-19023758-vmss000000/10.224.0.4
Start Time:       Wed, 12 Mar 2025 10:43:05 -0700
Labels:           app=nginx
                  pod-template-hash=866d97c778
Annotations:      <none>
Status:           Running
IP:               10.244.0.84
IPs:
  IP:           10.244.0.84
Controlled By:  ReplicaSet/nginx-deployment-866d97c778
Containers:
  nginx-container:
    Container ID:   containerd://8bcb5fdf01dd1d98d5485d7e147c6592339a826b1f4d676e1c71e4e7dd7e0d8b
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:9d6b58feebd2dbd3c56ab5853333d627cc6e281011cfd6050fa4bcf2072c9496
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Wed, 12 Mar 2025 10:43:11 -0700
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-8zgdn (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-8zgdn:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  51m   default-scheduler  Successfully assigned my-namespace/nginx-deployment-866d97c778-86thp to aks-default-19023758-vmss000000
  Normal  Pulling    51m   kubelet            Pulling image "nginx:latest"
  Normal  Pulled     51m   kubelet            Successfully pulled image "nginx:latest" in 5.7s (5.7s including waiting). Image size: 72195292 bytes.
  Normal  Created    51m   kubelet            Created container nginx-container
  Normal  Started    51m   kubelet            Started container nginx-container
  ```
  View Pod Logs

Check the output logs to confirm how Nginx started:

```sh
 kubectl logs nginx-deployment-866d97c778-86thp -n my-namespace
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2025/03/12 17:43:11 [notice] 1#1: using the "epoll" event method
2025/03/12 17:43:11 [notice] 1#1: nginx/1.27.4
2025/03/12 17:43:11 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
2025/03/12 17:43:11 [notice] 1#1: OS: Linux 5.15.0-1081-azure
2025/03/12 17:43:11 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2025/03/12 17:43:11 [notice] 1#1: start worker processes
2025/03/12 17:43:11 [notice] 1#1: start worker process 28
2025/03/12 17:43:11 [notice] 1#1: start worker process 29
10.224.0.4 - - [12/Mar/2025:18:04:30 +0000] "GET / HTTP/1.1" 200 615 "-" "Hello World" "-"
10.224.0.4 - - [12/Mar/2025:18:05:51 +0000] "\x05\x01\x00" 400 157 "-" "-" "-"
10.224.0.4 - - [12/Mar/2025:18:05:51 +0000] "\x04\x01\x01\xBB\x00\x00\x00\x01proxychecker\x00api.ip.pn\x00" 400 157 "-" "-" "-"
10.224.0.4 - - [12/Mar/2025:18:05:51 +0000] "CONNECT api.ip.pn:443 HTTP/1.1" 400 157 "-" "-" "-"
10.224.0.4 - - [12/Mar/2025:18:27:55 +0000] "GET / HTTP/1.1" 200 615 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.46" "-"
10.224.0.4 - - [12/Mar/2025:18:34:44 +0000] "GET / HTTP/1.1" 200 615 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.46" "-"
```

If Nginx is running correctly, the logs should show:

```sh
/docker-entrypoint.sh: Configuration complete; ready for start up
```
🔍 3. Inspect the Running Container

Check Pod YAML Definition

View the full YAML of the running pod:

```sh
kubectl describe pod nginx-deployment-866d97c778-86thp -n my-namespace
Name:             nginx-deployment-866d97c778-86thp
Namespace:        my-namespace
Priority:         0
Service Account:  default
Node:             aks-default-19023758-vmss000000/10.224.0.4
Start Time:       Wed, 12 Mar 2025 10:43:05 -0700
Labels:           app=nginx
                  pod-template-hash=866d97c778
Annotations:      <none>
Status:           Running
IP:               10.244.0.84
IPs:
  IP:           10.244.0.84
Controlled By:  ReplicaSet/nginx-deployment-866d97c778
Containers:
  nginx-container:
    Container ID:   containerd://8bcb5fdf01dd1d98d5485d7e147c6592339a826b1f4d676e1c71e4e7dd7e0d8b
    Image:          nginx:latest
    Image ID:       docker.io/library/nginx@sha256:9d6b58feebd2dbd3c56ab5853333d627cc6e281011cfd6050fa4bcf2072c9496
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Wed, 12 Mar 2025 10:43:11 -0700
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-8zgdn (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-8zgdn:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  51m   default-scheduler  Successfully assigned my-namespace/nginx-deployment-866d97c778-86thp to aks-default-19023758-vmss000000
  Normal  Pulling    51m   kubelet            Pulling image "nginx:latest"
  Normal  Pulled     51m   kubelet            Successfully pulled image "nginx:latest" in 5.7s (5.7s including waiting). Image size: 72195292 bytes.
  Normal  Created    51m   kubelet            Created container nginx-container
  Normal  Started    51m   kubelet            Started container nginx-container
bayawchik@Bayas-MacBook-Pro simple % kubectl logs nginx-deployment-866d97c778-86thp -n my-namespace
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2025/03/12 17:43:11 [notice] 1#1: using the "epoll" event method
2025/03/12 17:43:11 [notice] 1#1: nginx/1.27.4
2025/03/12 17:43:11 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
2025/03/12 17:43:11 [notice] 1#1: OS: Linux 5.15.0-1081-azure
2025/03/12 17:43:11 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1048576:1048576
2025/03/12 17:43:11 [notice] 1#1: start worker processes
2025/03/12 17:43:11 [notice] 1#1: start worker process 28
2025/03/12 17:43:11 [notice] 1#1: start worker process 29
10.224.0.4 - - [12/Mar/2025:18:04:30 +0000] "GET / HTTP/1.1" 200 615 "-" "Hello World" "-"
10.224.0.4 - - [12/Mar/2025:18:05:51 +0000] "\x05\x01\x00" 400 157 "-" "-" "-"
10.224.0.4 - - [12/Mar/2025:18:05:51 +0000] "\x04\x01\x01\xBB\x00\x00\x00\x01proxychecker\x00api.ip.pn\x00" 400 157 "-" "-" "-"
10.224.0.4 - - [12/Mar/2025:18:05:51 +0000] "CONNECT api.ip.pn:443 HTTP/1.1" 400 157 "-" "-" "-"
10.224.0.4 - - [12/Mar/2025:18:27:55 +0000] "GET / HTTP/1.1" 200 615 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.46" "-"
10.224.0.4 - - [12/Mar/2025:18:34:44 +0000] "GET / HTTP/1.1" 200 615 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.46" "-"
bayawchik@Bayas-MacBook-Pro simple % kubectl get pod nginx-deployment-866d97c778-86thp -n my-namespace -o yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2025-03-12T17:43:04Z"
  generateName: nginx-deployment-866d97c778-
  labels:
    app: nginx
    pod-template-hash: 866d97c778
  name: nginx-deployment-866d97c778-86thp
  namespace: my-namespace
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: nginx-deployment-866d97c778
    uid: 0fe4ffc2-12e5-4eba-ae3d-b877982e7883
  resourceVersion: "1407"
  uid: 89fcd505-cae1-4a13-9ac0-c26837bd5f93
spec:
  automountServiceAccountToken: true
  containers:
  - image: nginx:latest
    imagePullPolicy: Always
    name: nginx-container
    ports:
    - containerPort: 80
      protocol: TCP
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-8zgdn
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: aks-default-19023758-vmss000000
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  shareProcessNamespace: false
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: kube-api-access-8zgdn
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2025-03-12T17:43:11Z"
    status: "True"
    type: PodReadyToStartContainers
  - lastProbeTime: null
    lastTransitionTime: "2025-03-12T17:43:05Z"
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: "2025-03-12T17:43:11Z"
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: "2025-03-12T17:43:11Z"
    status: "True"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: "2025-03-12T17:43:05Z"
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: containerd://8bcb5fdf01dd1d98d5485d7e147c6592339a826b1f4d676e1c71e4e7dd7e0d8b
    image: docker.io/library/nginx:latest
    imageID: docker.io/library/nginx@sha256:9d6b58feebd2dbd3c56ab5853333d627cc6e281011cfd6050fa4bcf2072c9496
    lastState: {}
    name: nginx-container
    ready: true
    restartCount: 0
    started: true
    state:
      running:
        startedAt: "2025-03-12T17:43:11Z"
  hostIP: 10.224.0.4
  hostIPs:
  - ip: 10.224.0.4
  phase: Running
  podIP: 10.244.0.84
  podIPs:
  - ip: 10.244.0.84
  qosClass: BestEffort
  startTime: "2025-03-12T17:43:05Z"
  ```

  This will show:
	•	Container runtime (containerd)
	•	Pod spec (image, ports, environment variables)
	•	Node placement (which node the pod is running on)

Access the Pod & Inspect the Nginx Setup

To enter the running Nginx pod, use:

```sh
kubectl exec -it nginx-deployment-866d97c778-86thp -n my-namespace -- /bin/sh
# ls -l /usr/share/nginx/html
cat /etc/nginx/nginx.conf
nginx -v  # Check installed Nginx versiontotal 8
-rw-r--r-- 1 root root 497 Feb  5 11:06 50x.html
-rw-r--r-- 1 root root 615 Feb  5 11:06 index.html
# 
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
# exit
nginx version: nginx/1.27.4
```

🔍 4. Validate the LoadBalancer & Service

Your LoadBalancer service is exposing port 80 externally.

Check Service Details
```sh
kubectl describe svc nginx-service -n my-namespace
Name:                     nginx-service
Namespace:                my-namespace
Labels:                   <none>
Annotations:              <none>
Selector:                 app=nginx
Type:                     LoadBalancer
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.0.202.20
IPs:                      10.0.202.20
LoadBalancer Ingress:     4.149.75.178 (VIP)
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31155/TCP
Endpoints:                10.244.0.84:80
Session Affinity:         None
External Traffic Policy:  Cluster
Internal Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  56m   service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   56m   service-controller  Ensured load balancer
  ```
  This shows:
	•	ClusterIP: 10.0.202.20
	•	External IP: 4.149.75.178
	•	Port mapping (80:31155/TCP)

Test External Access

From your local machine:

```sh
curl http://4.149.75.178
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

🔍 5. Verify Worker Node Config & Logs

Check Container Runtime (containerd)

On the worker node (aks-default-19023758-vmss000000), check:

```sh
kubectl get nodes -o jsonpath='{.items[].status.nodeInfo.containerRuntimeVersion}'
containerd://1.7.25-1%         
```

Check Kubernetes System Logs

```sh
kubectl logs -n kube-system kube-proxy-tq6f4
Defaulted container "kube-proxy" out of: kube-proxy, kube-proxy-bootstrap (init)
I0312 17:42:26.395306       1 server_linux.go:69] "Using iptables proxy"
I0312 17:42:26.395574       1 flags.go:64] FLAG: --bind-address="0.0.0.0"
I0312 17:42:26.395599       1 flags.go:64] FLAG: --bind-address-hard-fail="false"
I0312 17:42:26.395608       1 flags.go:64] FLAG: --boot-id-file="/proc/sys/kernel/random/boot_id"
I0312 17:42:26.395616       1 flags.go:64] FLAG: --cleanup="false"
I0312 17:42:26.395621       1 flags.go:64] FLAG: --cluster-cidr="10.244.0.0/16"
I0312 17:42:26.395629       1 flags.go:64] FLAG: --config=""
I0312 17:42:26.395637       1 flags.go:64] FLAG: --config-sync-period="15m0s"
I0312 17:42:26.395645       1 flags.go:64] FLAG: --conntrack-max-per-core="0"
I0312 17:42:26.395652       1 flags.go:64] FLAG: --conntrack-min="131072"
I0312 17:42:26.395657       1 flags.go:64] FLAG: --conntrack-tcp-be-liberal="false"
I0312 17:42:26.395662       1 flags.go:64] FLAG: --conntrack-tcp-timeout-close-wait="1h0m0s"
I0312 17:42:26.395667       1 flags.go:64] FLAG: --conntrack-tcp-timeout-established="24h0m0s"
I0312 17:42:26.395673       1 flags.go:64] FLAG: --conntrack-udp-timeout="0s"
I0312 17:42:26.395678       1 flags.go:64] FLAG: --conntrack-udp-timeout-stream="0s"
I0312 17:42:26.395684       1 flags.go:64] FLAG: --detect-local-mode="InterfaceNamePrefix"
I0312 17:42:26.395692       1 flags.go:64] FLAG: --feature-gates=""
I0312 17:42:26.395701       1 flags.go:64] FLAG: --healthz-bind-address="0.0.0.0:10256"
I0312 17:42:26.395711       1 flags.go:64] FLAG: --healthz-port="10256"
I0312 17:42:26.395718       1 flags.go:64] FLAG: --help="false"
I0312 17:42:26.395724       1 flags.go:64] FLAG: --hostname-override=""
I0312 17:42:26.395730       1 flags.go:64] FLAG: --init-only="false"
I0312 17:42:26.395736       1 flags.go:64] FLAG: --iptables-localhost-nodeports="true"
I0312 17:42:26.395755       1 flags.go:64] FLAG: --iptables-masquerade-bit="14"
I0312 17:42:26.395764       1 flags.go:64] FLAG: --iptables-min-sync-period="1s"
I0312 17:42:26.395770       1 flags.go:64] FLAG: --iptables-sync-period="30s"
I0312 17:42:26.395777       1 flags.go:64] FLAG: --ipvs-exclude-cidrs="[]"
I0312 17:42:26.395812       1 flags.go:64] FLAG: --ipvs-min-sync-period="0s"
I0312 17:42:26.395819       1 flags.go:64] FLAG: --ipvs-scheduler=""
I0312 17:42:26.395825       1 flags.go:64] FLAG: --ipvs-strict-arp="false"
I0312 17:42:26.395831       1 flags.go:64] FLAG: --ipvs-sync-period="30s"
I0312 17:42:26.395837       1 flags.go:64] FLAG: --ipvs-tcp-timeout="0s"
I0312 17:42:26.395844       1 flags.go:64] FLAG: --ipvs-tcpfin-timeout="0s"
I0312 17:42:26.395849       1 flags.go:64] FLAG: --ipvs-udp-timeout="0s"
I0312 17:42:26.395855       1 flags.go:64] FLAG: --kube-api-burst="10"
I0312 17:42:26.395861       1 flags.go:64] FLAG: --kube-api-content-type="application/vnd.kubernetes.protobuf"
I0312 17:42:26.395867       1 flags.go:64] FLAG: --kube-api-qps="5"
I0312 17:42:26.395876       1 flags.go:64] FLAG: --kubeconfig=""
I0312 17:42:26.395882       1 flags.go:64] FLAG: --log-flush-frequency="5s"
I0312 17:42:26.395889       1 flags.go:64] FLAG: --log-json-info-buffer-size="0"
I0312 17:42:26.395908       1 flags.go:64] FLAG: --log-json-split-stream="false"
I0312 17:42:26.395915       1 flags.go:64] FLAG: --log-text-info-buffer-size="0"
I0312 17:42:26.395925       1 flags.go:64] FLAG: --log-text-split-stream="false"
I0312 17:42:26.395938       1 flags.go:64] FLAG: --logging-format="text"
I0312 17:42:26.395945       1 flags.go:64] FLAG: --machine-id-file="/etc/machine-id,/var/lib/dbus/machine-id"
I0312 17:42:26.395952       1 flags.go:64] FLAG: --masquerade-all="false"
I0312 17:42:26.395957       1 flags.go:64] FLAG: --master=""
I0312 17:42:26.395962       1 flags.go:64] FLAG: --metrics-bind-address="0.0.0.0:10249"
I0312 17:42:26.395968       1 flags.go:64] FLAG: --metrics-port="10249"
I0312 17:42:26.395975       1 flags.go:64] FLAG: --nodeport-addresses="[]"
I0312 17:42:26.395983       1 flags.go:64] FLAG: --oom-score-adj="-999"
I0312 17:42:26.395989       1 flags.go:64] FLAG: --pod-bridge-interface=""
I0312 17:42:26.395995       1 flags.go:64] FLAG: --pod-interface-name-prefix="azv"
I0312 17:42:26.396001       1 flags.go:64] FLAG: --profiling="false"
I0312 17:42:26.396007       1 flags.go:64] FLAG: --proxy-mode="iptables"
I0312 17:42:26.396024       1 flags.go:64] FLAG: --proxy-port-range=""
I0312 17:42:26.396032       1 flags.go:64] FLAG: --show-hidden-metrics-for-version=""
I0312 17:42:26.396038       1 flags.go:64] FLAG: --v="3"
I0312 17:42:26.396046       1 flags.go:64] FLAG: --version="false"
I0312 17:42:26.396056       1 flags.go:64] FLAG: --vmodule=""
I0312 17:42:26.396062       1 flags.go:64] FLAG: --write-config-to=""
I0312 17:42:26.396166       1 feature_gate.go:254] feature gates: {map[]}
I0312 17:42:26.397095       1 server.go:780] "Neither kubeconfig file nor master URL was specified, falling back to in-cluster config"
I0312 17:42:26.898666       1 server.go:1062] "Successfully retrieved node IP(s)" IPs=["10.224.0.4"]
I0312 17:42:26.898993       1 conntrack.go:119] "Set sysctl" entry="net/netfilter/nf_conntrack_tcp_timeout_established" value=86400
I0312 17:42:26.899086       1 conntrack.go:119] "Set sysctl" entry="net/netfilter/nf_conntrack_tcp_timeout_close_wait" value=3600
I0312 17:42:27.088309       1 server.go:659] "kube-proxy running in dual-stack mode" primary ipFamily="IPv4"
I0312 17:42:27.088399       1 server_linux.go:165] "Using iptables Proxier"
I0312 17:42:27.092265       1 proxier.go:243] "Setting route_localnet=1 to allow node-ports on localhost; to change this either disable iptables.localhostNodePorts (--iptables-localhost-nodeports) or set nodePortAddresses (--nodeport-addresses) to filter loopback addresses"
I0312 17:42:27.092595       1 utils.go:283] "Changed sysctl" name="net/ipv4/conf/all/route_localnet" before=0 after=1
I0312 17:42:27.092778       1 proxier.go:266] "Using iptables mark for masquerade" ipFamily="IPv4" mark="0x00004000"
I0312 17:42:27.092834       1 proxier.go:302] "Iptables sync params" ipFamily="IPv4" minSyncPeriod="1s" syncPeriod="30s" burstSyncs=2
I0312 17:42:27.092973       1 proxier.go:312] "Iptables supports --random-fully" ipFamily="IPv4"
I0312 17:42:27.093144       1 proxier.go:266] "Using iptables mark for masquerade" ipFamily="IPv6" mark="0x00004000"
I0312 17:42:27.093194       1 proxier.go:302] "Iptables sync params" ipFamily="IPv6" minSyncPeriod="1s" syncPeriod="30s" burstSyncs=2
I0312 17:42:27.093273       1 proxier.go:312] "Iptables supports --random-fully" ipFamily="IPv6"
I0312 17:42:27.093370       1 server.go:872] "Version info" version="v1.30.9"
I0312 17:42:27.093445       1 server.go:874] "Golang settings" GOGC="" GOMAXPROCS="" GOTRACEBACK=""
I0312 17:42:27.095451       1 proxier_health.go:176] "Starting healthz HTTP server" address="0.0.0.0:10256"
I0312 17:42:27.161105       1 bounded_frequency_runner.go:192] sync-runner Loop running
I0312 17:42:27.161955       1 bounded_frequency_runner.go:192] sync-runner Loop running
I0312 17:42:27.162174       1 config.go:192] "Starting service config controller"
I0312 17:42:27.162532       1 shared_informer.go:313] Waiting for caches to sync for service config
I0312 17:42:27.162761       1 reflector.go:296] Starting reflector *v1.EndpointSlice (15m0s) from k8s.io/client-go/informers/factory.go:160
I0312 17:42:27.162790       1 reflector.go:332] Listing and watching *v1.EndpointSlice from k8s.io/client-go/informers/factory.go:160
I0312 17:42:27.163002       1 config.go:319] "Starting node config controller"
I0312 17:42:27.163267       1 shared_informer.go:313] Waiting for caches to sync for node config
I0312 17:42:27.163759       1 reflector.go:296] Starting reflector *v1.Node (15m0s) from k8s.io/client-go/informers/factory.go:160
I0312 17:42:27.165047       1 reflector.go:332] Listing and watching *v1.Node from k8s.io/client-go/informers/factory.go:160
I0312 17:42:27.164385       1 config.go:101] "Starting endpoint slice config controller"
I0312 17:42:27.165449       1 shared_informer.go:313] Waiting for caches to sync for endpoint slice config
I0312 17:42:27.164437       1 reflector.go:296] Starting reflector *v1.Service (15m0s) from k8s.io/client-go/informers/factory.go:160
I0312 17:42:27.165474       1 reflector.go:332] Listing and watching *v1.Service from k8s.io/client-go/informers/factory.go:160
I0312 17:42:27.166366       1 reflector.go:359] Caches populated for *v1.EndpointSlice from k8s.io/client-go/informers/factory.go:160
I0312 17:42:27.175542       1 reflector.go:359] Caches populated for *v1.Node from k8s.io/client-go/informers/factory.go:160
I0312 17:42:27.184197       1 reflector.go:359] Caches populated for *v1.Service from k8s.io/client-go/informers/factory.go:160
I0312 17:42:27.184473       1 proxier.go:782] "Not syncing iptables until Services and Endpoints have been received from master"
I0312 17:42:27.184496       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:27.184583       1 proxier.go:782] "Not syncing iptables until Services and Endpoints have been received from master"
I0312 17:42:27.184609       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:27.263773       1 shared_informer.go:320] Caches are synced for service config
I0312 17:42:27.263910       1 config.go:199] "Calling handler.OnServiceSynced()"
I0312 17:42:27.264088       1 proxier.go:782] "Not syncing iptables until Services and Endpoints have been received from master"
I0312 17:42:27.264115       1 proxier.go:782] "Not syncing iptables until Services and Endpoints have been received from master"
I0312 17:42:27.263773       1 shared_informer.go:320] Caches are synced for node config
I0312 17:42:27.264135       1 config.go:326] "Calling handler.OnNodeSynced()"
I0312 17:42:27.264144       1 config.go:326] "Calling handler.OnNodeSynced()"
I0312 17:42:27.266582       1 shared_informer.go:320] Caches are synced for endpoint slice config
I0312 17:42:27.266667       1 config.go:108] "Calling handler.OnEndpointSlicesSynced()"
I0312 17:42:27.266957       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="default/kubernetes:https" endpoints=["20.72.246.29:443"]
I0312 17:42:27.267150       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:27.421509       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=1 numFilterChains=6 numFilterRules=7 numNATChains=6 numNATRules=10
I0312 17:42:27.489794       1 proxier.go:799] "SyncProxyRules complete" elapsed="222.935396ms"
I0312 17:42:27.489856       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:27.583424       1 proxier.go:1494] "Reloading service iptables data" numServices=0 numEndpoints=0 numFilterChains=5 numFilterRules=3 numNATChains=4 numNATRules=5
I0312 17:42:27.586686       1 proxier.go:799] "SyncProxyRules complete" elapsed="96.834077ms"
I0312 17:42:28.187810       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:28.188183       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:28.289246       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=1 numFilterChains=6 numFilterRules=7 numNATChains=6 numNATRules=10
I0312 17:42:28.292141       1 proxier.go:1494] "Reloading service iptables data" numServices=0 numEndpoints=0 numFilterChains=5 numFilterRules=3 numNATChains=4 numNATRules=5
I0312 17:42:28.345539       1 proxier.go:799] "SyncProxyRules complete" elapsed="157.33745ms"
I0312 17:42:28.345607       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:28.363547       1 proxier.go:799] "SyncProxyRules complete" elapsed="175.751451ms"
I0312 17:42:28.363579       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:35.515323       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns-tcp" endpoints=["10.244.0.65:53"]
I0312 17:42:35.515478       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns" endpoints=["10.244.0.65:53"]
I0312 17:42:35.515503       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:35.522725       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=3 numFilterChains=6 numFilterRules=7 numNATChains=4 numNATRules=6
I0312 17:42:35.555361       1 proxier.go:799] "SyncProxyRules complete" elapsed="40.087239ms"
I0312 17:42:35.555393       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:39.515648       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.101:4443"]
I0312 17:42:39.515800       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:39.522408       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=4 numFilterChains=6 numFilterRules=7 numNATChains=4 numNATRules=6
I0312 17:42:39.555442       1 proxier.go:799] "SyncProxyRules complete" elapsed="39.83044ms"
I0312 17:42:39.555630       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:40.529147       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.101:4443"]
I0312 17:42:40.529496       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.101:4443","10.244.0.245:4443"]
I0312 17:42:40.529721       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:40.538564       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=5 numFilterChains=6 numFilterRules=7 numNATChains=4 numNATRules=6
I0312 17:42:40.609172       1 proxier.go:799] "SyncProxyRules complete" elapsed="80.049878ms"
I0312 17:42:40.609384       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:41.536543       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns" endpoints=["10.244.0.65:53"]
I0312 17:42:41.536678       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns-tcp" endpoints=["10.244.0.65:53"]
I0312 17:42:41.536790       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns" endpoints=["10.244.0.227:53","10.244.0.65:53"]
I0312 17:42:41.536893       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns-tcp" endpoints=["10.244.0.227:53","10.244.0.65:53"]
I0312 17:42:41.536980       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:41.546305       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=7 numFilterChains=6 numFilterRules=7 numNATChains=4 numNATRules=6
I0312 17:42:41.579569       1 proxier.go:799] "SyncProxyRules complete" elapsed="43.067319ms"
I0312 17:42:41.579768       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:42.536406       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns" endpoints=["10.244.0.227:53","10.244.0.65:53"]
I0312 17:42:42.536464       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns-tcp" endpoints=["10.244.0.227:53","10.244.0.65:53"]
I0312 17:42:42.536502       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns-tcp" endpoints=["10.244.0.227:53","10.244.0.65:53"]
I0312 17:42:42.536518       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns" endpoints=["10.244.0.227:53","10.244.0.65:53"]
I0312 17:42:42.536546       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:42.544251       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=7 numFilterChains=6 numFilterRules=5 numNATChains=8 numNATRules=16
I0312 17:42:42.648531       1 proxier.go:799] "SyncProxyRules complete" elapsed="112.199043ms"
I0312 17:42:42.648564       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:43.440506       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns" endpoints=["10.244.0.227:53","10.244.0.65:53"]
I0312 17:42:43.440552       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns-tcp" endpoints=["10.244.0.227:53","10.244.0.65:53"]
I0312 17:42:43.440628       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns" endpoints=["10.244.0.227:53","10.244.0.65:53"]
I0312 17:42:43.440738       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/kube-dns:dns-tcp" endpoints=["10.244.0.227:53","10.244.0.65:53"]
I0312 17:42:43.440811       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:43.447272       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=7 numFilterChains=6 numFilterRules=5 numNATChains=10 numNATRules=22
I0312 17:42:43.542956       1 proxier.go:799] "SyncProxyRules complete" elapsed="102.487109ms"
I0312 17:42:43.542998       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:45.454707       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.101:4443","10.244.0.245:4443"]
I0312 17:42:45.454765       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.101:4443","10.244.0.245:4443"]
I0312 17:42:45.454786       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:45.467962       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=7 numFilterChains=6 numFilterRules=5 numNATChains=4 numNATRules=8
I0312 17:42:45.499912       1 proxier.go:799] "SyncProxyRules complete" elapsed="45.244895ms"
I0312 17:42:45.499952       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:46.426422       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.101:4443","10.244.0.245:4443"]
I0312 17:42:46.426479       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.245:4443"]
I0312 17:42:46.426516       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:46.435355       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=6 numFilterChains=6 numFilterRules=5 numNATChains=4 numNATRules=8
I0312 17:42:46.475877       1 proxier.go:799] "SyncProxyRules complete" elapsed="49.500166ms"
I0312 17:42:46.475922       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:47.563382       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.245:4443"]
I0312 17:42:47.563440       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.245:4443"]
I0312 17:42:47.563623       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:47.573199       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=7 numFilterChains=6 numFilterRules=5 numNATChains=4 numNATRules=8
I0312 17:42:47.615382       1 proxier.go:799] "SyncProxyRules complete" elapsed="52.063649ms"
I0312 17:42:47.615416       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:42:47.615545       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.245:4443"]
I0312 17:42:47.615778       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443","10.244.0.245:4443"]
I0312 17:42:47.615881       1 proxier.go:805] "Syncing iptables rules"
I0312 17:42:47.620537       1 proxier.go:1494] "Reloading service iptables data" numServices=4 numEndpoints=8 numFilterChains=6 numFilterRules=5 numNATChains=4 numNATRules=8
I0312 17:42:47.663871       1 proxier.go:799] "SyncProxyRules complete" elapsed="48.419973ms"
I0312 17:42:47.664007       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:43:04.957884       1 proxier.go:805] "Syncing iptables rules"
I0312 17:43:04.965058       1 proxier.go:1494] "Reloading service iptables data" numServices=5 numEndpoints=8 numFilterChains=6 numFilterRules=7 numNATChains=4 numNATRules=8
I0312 17:43:05.003549       1 proxier.go:799] "SyncProxyRules complete" elapsed="45.680477ms"
I0312 17:43:05.003589       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:43:05.003736       1 proxier.go:805] "Syncing iptables rules"
I0312 17:43:05.012103       1 proxier.go:1494] "Reloading service iptables data" numServices=5 numEndpoints=8 numFilterChains=6 numFilterRules=7 numNATChains=4 numNATRules=8
I0312 17:43:05.043771       1 proxier.go:799] "SyncProxyRules complete" elapsed="40.124317ms"
I0312 17:43:05.043842       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:43:11.652116       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="my-namespace/nginx-service" endpoints=["10.244.0.84:80"]
I0312 17:43:11.652191       1 proxier.go:805] "Syncing iptables rules"
I0312 17:43:11.657266       1 proxier.go:1494] "Reloading service iptables data" numServices=5 numEndpoints=9 numFilterChains=6 numFilterRules=5 numNATChains=7 numNATRules=16
I0312 17:43:11.699260       1 proxier.go:799] "SyncProxyRules complete" elapsed="47.19116ms"
I0312 17:43:11.699287       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:43:15.613218       1 proxier.go:805] "Syncing iptables rules"
I0312 17:43:15.619812       1 proxier.go:1494] "Reloading service iptables data" numServices=5 numEndpoints=9 numFilterChains=6 numFilterRules=5 numNATChains=7 numNATRules=17
I0312 17:43:15.651418       1 proxier.go:799] "SyncProxyRules complete" elapsed="38.270848ms"
I0312 17:43:15.651570       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:43:43.436649       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443","10.244.0.245:4443"]
I0312 17:43:43.436740       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443","10.244.0.245:4443"]
I0312 17:43:43.436768       1 proxier.go:805] "Syncing iptables rules"
I0312 17:43:43.442002       1 proxier.go:1494] "Reloading service iptables data" numServices=5 numEndpoints=9 numFilterChains=6 numFilterRules=4 numNATChains=6 numNATRules=16
I0312 17:43:43.484247       1 proxier.go:799] "SyncProxyRules complete" elapsed="47.642774ms"
I0312 17:43:43.484383       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:43:55.828523       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443","10.244.0.245:4443"]
I0312 17:43:55.838670       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443","10.244.0.245:4443"]
I0312 17:43:55.838726       1 proxier.go:805] "Syncing iptables rules"
I0312 17:43:55.850510       1 proxier.go:1494] "Reloading service iptables data" numServices=5 numEndpoints=9 numFilterChains=6 numFilterRules=4 numNATChains=7 numNATRules=19
I0312 17:43:55.895183       1 proxier.go:799] "SyncProxyRules complete" elapsed="66.740043ms"
I0312 17:43:55.895226       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:43:55.949502       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443","10.244.0.245:4443"]
I0312 17:43:55.949565       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443","10.244.0.245:4443"]
I0312 17:43:55.949591       1 proxier.go:805] "Syncing iptables rules"
I0312 17:43:55.975558       1 proxier.go:1494] "Reloading service iptables data" numServices=5 numEndpoints=9 numFilterChains=6 numFilterRules=4 numNATChains=8 numNATRules=22
I0312 17:43:56.019157       1 proxier.go:799] "SyncProxyRules complete" elapsed="69.697524ms"
I0312 17:43:56.019628       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:43:57.019917       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443","10.244.0.245:4443"]
I0312 17:43:57.020180       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443","10.244.0.245:4443"]
I0312 17:43:57.020299       1 proxier.go:805] "Syncing iptables rules"
I0312 17:43:57.025474       1 proxier.go:1494] "Reloading service iptables data" numServices=5 numEndpoints=9 numFilterChains=6 numFilterRules=4 numNATChains=8 numNATRules=20
I0312 17:43:57.063639       1 proxier.go:799] "SyncProxyRules complete" elapsed="43.787601ms"
I0312 17:43:57.063678       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 17:43:58.822190       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443","10.244.0.245:4443"]
I0312 17:43:58.822254       1 endpointslicecache.go:348] "Setting endpoints for service port name" portName="kube-system/metrics-server" endpoints=["10.244.0.132:4443","10.244.0.218:4443"]
I0312 17:43:58.822278       1 proxier.go:805] "Syncing iptables rules"
I0312 17:43:58.831153       1 proxier.go:1494] "Reloading service iptables data" numServices=5 numEndpoints=8 numFilterChains=6 numFilterRules=4 numNATChains=7 numNATRules=19
I0312 17:43:58.871776       1 proxier.go:799] "SyncProxyRules complete" elapsed="49.63326ms"
I0312 17:43:58.871814       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 18:42:28.364521       1 proxier.go:805] "Syncing iptables rules"
I0312 18:42:28.368082       1 proxier.go:1494] "Reloading service iptables data" numServices=0 numEndpoints=0 numFilterChains=5 numFilterRules=3 numNATChains=4 numNATRules=5
I0312 18:42:28.417002       1 proxier.go:799] "SyncProxyRules complete" elapsed="52.497127ms"
I0312 18:42:28.417046       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
I0312 18:43:58.872018       1 proxier.go:805] "Syncing iptables rules"
I0312 18:43:58.878282       1 proxier.go:1494] "Reloading service iptables data" numServices=5 numEndpoints=8 numFilterChains=6 numFilterRules=4 numNATChains=4 numNATRules=12
I0312 18:43:58.919623       1 proxier.go:799] "SyncProxyRules complete" elapsed="47.633089ms"
I0312 18:43:58.919671       1 bounded_frequency_runner.go:296] sync-runner: ran, next possible in 1s, periodic in 1h0m0s
```



