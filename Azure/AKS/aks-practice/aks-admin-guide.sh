#!/bin/bash
# AKS Administrator Practice Guide - Kubernetes Configuration Components
# Run these commands after deploying the Terraform infrastructure

## 1. Setup and Connection
echo "Fetching AKS credentials..."
RESOURCE_GROUP="aks-admin-practice-rg"
CLUSTER_NAME="admin-practice-aks"

# Get credentials for the cluster
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing

# Verify connection to cluster
echo "Verifying connection to cluster..."
kubectl get nodes

## 2. Workload Management - Deployments and Services

# Create a namespace for team development
echo "Creating a namespace for team development..."
kubectl create namespace team-dev

# Create an Nginx deployment with resource constraints
cat << EOF > nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: team-dev
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
EOF

kubectl apply -f nginx-deployment.yaml

# Create a service for the Nginx deployment
cat << EOF > nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: team-dev
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

kubectl apply -f nginx-service.yaml

## 3. Storage Configuration

# Create storage classes
cat << EOF > storage-classes.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: premium-ssd
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azurefile
provisioner: kubernetes.io/azure-file
parameters:
  skuName: Standard_LRS
mountOptions:
  - dir_mode=0777
  - file_mode=0777
  - uid=1000
  - gid=1000
  - mfsymlinks
  - cache=strict
  - actimeo=30
EOF

kubectl apply -f storage-classes.yaml

# Create a PVC
cat << EOF > data-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: team-dev
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: premium-ssd
  resources:
    requests:
      storage: 10Gi
EOF

kubectl apply -f data-pvc.yaml

# Create a pod that uses the PVC
cat << EOF > storage-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod
  namespace: team-dev
spec:
  containers:
  - name: storage-container
    image: nginx:1.21
    volumeMounts:
    - mountPath: "/data"
      name: data-volume
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: data-pvc
EOF

kubectl apply -f storage-pod.yaml

## 4. Network Policies

# Create a network policy example
cat << EOF > network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-only-from-frontend
  namespace: team-dev
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
EOF

kubectl apply -f network-policy.yaml

# Create backend and frontend deployments
cat << EOF > frontend-backend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: team-dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: team-dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx:1.21
        ports:
        - containerPort: 8080
EOF

kubectl apply -f frontend-backend.yaml

## 5. RBAC Configuration

# Create a service account
cat << EOF > dev-service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dev-user
  namespace: team-dev
EOF

kubectl apply -f dev-service-account.yaml

# Create a role with limited permissions
cat << EOF > dev-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: team-dev
  name: developer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
EOF

kubectl apply -f dev-role.yaml

# Bind the role to the service account
cat << EOF > dev-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-role-binding
  namespace: team-dev
subjects:
- kind: ServiceAccount
  name: dev-user
  namespace: team-dev
roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f dev-rolebinding.yaml

# Create a token for the service account
cat << EOF > dev-token.yaml
apiVersion: v1
kind: Secret
metadata:
  name: dev-user-token
  namespace: team-dev
  annotations:
    kubernetes.io/service-account.name: dev-user
type: kubernetes.io/service-account-token
EOF

kubectl apply -f dev-token.yaml

## 6. Advanced Configurations

# Create a statefulset with persistent volume
cat << EOF > stateful-app.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: stateful-app
  namespace: team-dev
spec:
  serviceName: "stateful-app"
  replicas: 3
  selector:
    matchLabels:
      app: stateful-app
  template:
    metadata:
      labels:
        app: stateful-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "premium-ssd"
      resources:
        requests:
          storage: 5Gi
EOF

kubectl apply -f stateful-app.yaml

# Create a service for the statefulset
cat << EOF > stateful-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: stateful-app
  namespace: team-dev
spec:
  selector:
    app: stateful-app
  ports:
  - port: 80
    targetPort: 80
  clusterIP: None # Headless service
EOF

kubectl apply -f stateful-service.yaml

# Create a HorizontalPodAutoscaler
cat << EOF > hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
  namespace: team-dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF

kubectl apply -f hpa.yaml

# Create a PodDisruptionBudget
cat << EOF > pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
  namespace: team-dev
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: nginx
EOF

kubectl apply -f pdb.yaml

## 7. Azure Key Vault Integration

# Get the managed identity client ID
echo "Getting AKS managed identity for Key Vault integration..."
KEYVAULT_NAME=$(terraform output -raw keyvault_name)
echo "Key Vault name: $KEYVAULT_NAME"

# Create SecretProviderClass
cat << EOF > secret-provider.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secret
  namespace: team-dev
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: ""
    keyvaultName: "$KEYVAULT_NAME"
    objects: |
      array:
        - |
          objectName: database-password
          objectType: secret
    tenantId: $(az account show --query tenantId -o tsv)
EOF

kubectl apply -f secret-provider.yaml

# Create pod with Key Vault mounted
cat << EOF > secure-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: team-dev
spec:
  containers:
    - name: secure-app
      image: nginx:1.21
      volumeMounts:
      - name: secrets-store
        mountPath: "/mnt/secrets-store"
        readOnly: true
  volumes:
    - name: secrets-store
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "azure-keyvault-secret"
EOF

kubectl apply -f secure-pod.yaml

## 8. Ingress Configuration

# Install NGINX Ingress Controller
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Wait for controller to be ready
echo "Waiting for ingress controller to be ready..."
sleep 30

# Create sample applications
cat << EOF > app1-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
  namespace: team-dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: gcr.io/google-samples/hello-app:1.0
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: app1-service
  namespace: team-dev
spec:
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
EOF

kubectl apply -f app1-deployment.yaml

cat << EOF > app2-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
  namespace: team-dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: gcr.io/google-samples/hello-app:2.0
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: app2-service
  namespace: team-dev
spec:
  selector:
    app: app2
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
EOF

kubectl apply -f app2-deployment.yaml

# Create Ingress resource
cat << EOF > ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: team-dev
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
EOF

kubectl apply -f ingress.yaml

# Get Ingress Controller external IP
echo "Waiting for external IP (this may take a few minutes)..."
sleep 60
INGRESS_IP=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"
echo "Test by running: curl http://$INGRESS_IP/app1 and curl http://$INGRESS_IP/app2"

## 9. ConfigMap and Secret examples

# Create a ConfigMap
cat << EOF > config-map.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: team-dev
data:
  app-settings.json: |
    {
      "environment": "development",
      "logLevel": "debug",
      "apiEndpoint": "https://api.example.com"
    }
  database.conf: |
    host=db.example.com
    port=5432
    max_connections=100
EOF

kubectl apply -f config-map.yaml

# Create a Secret
cat << EOF > app-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
  namespace: team-dev
type: Opaque
stringData:
  api-key: "YOUR_API_KEY"
  db-password: "password123"
EOF

kubectl apply -f app-secret.yaml

# Pod using ConfigMap and Secret
cat << EOF > pod-with-config.yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
  namespace: team-dev
spec:
  containers:
  - name: app
    image: nginx:1.21
    volumeMounts:
    - name: config-volume
      mountPath: /app/config
    - name: secret-volume
      mountPath: /app/secrets
      readOnly: true
    env:
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: api-key
  volumes:
  - name: config-volume
    configMap:
      name: app-config
  - name: secret-volume
    secret:
      secretName: app-secret
EOF

kubectl apply -f pod-with-config.yaml

echo "AKS administrator practice environment has been set up!"
echo "----------------------------------------"
echo "Practice exercises to try:"
echo "1. Scale deployments manually and configure autoscaling"
echo "2. Test network policies by accessing pods from different sources"
echo "3. Expand a persistent volume claim"
echo "4. Create and use different service account roles"
echo "5. Deploy applications to specific node pools using nodeSelectors"
echo "6. Configure pod affinity and anti-affinity rules"
echo "7. Practice troubleshooting pod startup issues"
echo "8. Set up monitoring and alerts"
echo "----------------------------------------"