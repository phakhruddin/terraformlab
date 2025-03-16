# WebApp Demo 1
---
## Objective
Let’s craft a comprehensive Terraform demo on Azure that incorporates certificates, a Load Balancer, Linux VM auto-scaling, a web frontend, and a backend application retrieving data from Cosmos DB. This setup will simulate a scalable web application architecture with secure HTTPS traffic, auto-scaling based on CPU usage, and data persistence in Cosmos DB. Below is the outline ofthe architecture, the Terraform code, and a sample application code for the frontend and backend.

---

### **Architecture Overview**
1. **Resource Group**: Container for all resources.
2. **Virtual Network (VNet)**: Hosts the Load Balancer and VM Scale Set.
3. **Load Balancer**: Public-facing with an Application Gateway (for HTTPS and certificate management).
4. **Certificate**: Stored in Azure Key Vault, attached to the Application Gateway for HTTPS.
5. **VM Scale Set**: Auto-scaling Linux VMs running a web server (e.g., Nginx).
6. **Cosmos DB**: MongoDB API for data storage, accessed by the backend.
7. **Backend App**: A Python Flask app on the VMs, retrieving data from Cosmos DB.
8. **Frontend**: Simple HTML served by Nginx, calling the backend API.
9. **Auto-Scaling**: Scales VMs based on CPU usage.

---

### **Terraform Configuration (`main.tf`)**
Please refer to the `main.tf` file in repository for the Terraform configuration.

---

### **Deployment Steps**
1. **Initialize Terraform**:
   ```bash
   terraform init
   terraform apply
   ```
   - Confirm with `yes`.

2. **Insert Initial Data into Cosmos DB**:
   - Get the connection string:
     ```bash
     terraform output -raw appgw_url
     az cosmosdb keys list --name cosmos-web-demo-<suffix> --resource-group rg-web-demo --query "primaryMasterKey" -o tsv
     ```
   - Connect with `mongosh` (replace `<suffix>` and `<key>`):
     ```bash
     mongosh "mongodb://cosmos-web-demo-<suffix>:<key>@cosmos-web-demo-<suffix>.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false" --apiVersion 1
     ```
   - Insert data:
     ```bash
     use demo_db
     db.demo_collection.insertOne({"key": "test", "message": "Hello from Cosmos DB!"})
     ```

3. **Test the Application**:
   - Visit the Application Gateway URL (from `terraform output appgw_url`):
     ```
     https://<public-ip>
     ```
   - Expected output: A webpage saying “Welcome to the Web Demo” with “Data: Hello from Cosmos DB!”.

---

### **How It Works**
- **Certificate**: A self-signed cert is stored in Key Vault and attached to the Application Gateway for HTTPS. In production, import a real cert.
- **Load Balancer**: The Application Gateway routes HTTPS traffic to the VM Scale Set’s backend pool.
- **Linux VM Scale Set**: Runs Nginx (frontend) and a Flask app (backend). Scales from 2 to 5 instances when CPU exceeds 70% or drops below 30%.
- **Frontend**: Nginx serves a static HTML page that fetches data from the backend via `/api/data`.
- **Backend**: Flask retrieves data from Cosmos DB’s MongoDB API.
- **Cosmos DB**: Stores a simple key-value pair, accessible by the backend.

---

### **Notes**
- **Security**: The demo uses a self-signed cert and hardcoded password for simplicity. Use SSH keys and a real cert in production.
- **Networking**: The Application Gateway requires a public IP; adjust firewall rules (NSG) for production.
- **Cost**: This uses a Consumption plan for Cosmos DB and Standard_v2 for the Gateway—monitor costs in a real deployment.


---

### **Logical Architecture**

Below is a diagram representing the architecture described in the Terraform `main.tf` file. The diagram illustrates the relationships and dependencies between the resources.

```
+-------------------+
| Azure Resource    |
| Group (rg)        |
|                   |
| - Location:       |
|   westus2         |
+-------------------+
           |
           | Manages
           v
+-------------------+
| Virtual Network   |
| (vnet)            |
|                   |
| - Address Space:  |
|   10.0.0.0/16     |
+-------------------+
           |
           | Contains
           v
+-------------------+       +-------------------+
| Frontend Subnet   |       | Backend Subnet    |
| (frontend_subnet) |       | (backend_subnet)  |
|                   |       |                   |
| - Address Prefix: |       | - Address Prefix: |
|   10.0.1.0/24     |       |   10.0.2.0/24     |
+-------------------+       +-------------------+
           |                         |
           |                         | Hosts
           v                         v
+-------------------+       +-------------------+
| Application       |       | VM Scale Set      |
| Gateway (appgw)   |       | (vmss)            |
|                   |       |                   |
| - Public IP:      |       | - Instances: 2    |
|   appgw_pip       |       | - SKU: Standard_B1s|
+-------------------+       +-------------------+
           |                         |
           |                         | Connects to
           v                         v
+-------------------+       +-------------------+
| Key Vault (kv)    |       | Cosmos DB         |
|                   |       | (cosmos)          |
| - Certificates:   |       |                   |
|   webdemo-cert    |       | - MongoDB API     |
+-------------------+       +-------------------+
           |
           | Stores
           v
+-------------------+
| Self-Signed       |
| Certificate       |
| (cert)            |
+-------------------+
           |
           | Used by
           v
+-------------------+
| Application       |
| Gateway (appgw)   |
|                   |
| - HTTPS Listener  |
| - SSL Certificate |
+-------------------+
           |
           | Routes to
           v
+-------------------+
| Backend Pool      |
| (backend-pool)    |
|                   |
| - VM Scale Set    |
|   Instances       |
+-------------------+
           |
           | Connects to
           v
+-------------------+
| Cosmos DB         |
| (cosmos)          |
|                   |
| - MongoDB API     |
+-------------------+
```

<img width="1378" alt="Image" src="https://github.com/user-attachments/assets/b25965af-a3a7-4258-9009-9eca5026e530" />

### Key Components:
1. **Resource Group (rg)**: Manages all resources.
2. **Virtual Network (vnet)**: Contains subnets for frontend and backend.
3. **Frontend Subnet (frontend_subnet)**: Hosts the Application Gateway.
4. **Backend Subnet (backend_subnet)**: Hosts the VM Scale Set.
5. **Application Gateway (appgw)**: Load balancer with a public IP, SSL certificate, and backend pool.
6. **VM Scale Set (vmss)**: Hosts the backend application instances.
7. **Key Vault (kv)**: Stores the self-signed certificate used by the Application Gateway.
8. **Cosmos DB (cosmos)**: MongoDB API database used by the backend application.
9. **Self-Signed Certificate (cert)**: Used for HTTPS in the Application Gateway.

### Relationships:
- The **Resource Group** manages all resources.
- The **Virtual Network** contains the **Frontend Subnet** and **Backend Subnet**.
- The **Application Gateway** is deployed in the **Frontend Subnet** and routes traffic to the **VM Scale Set** in the **Backend Subnet**.
- The **VM Scale Set** connects to **Cosmos DB** for data storage.
- The **Key Vault** stores the SSL certificate used by the **Application Gateway**.

This diagram provides a high-level overview of the infrastructure and how the components interact.