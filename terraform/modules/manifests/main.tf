terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

resource "kubectl_manifest" "namespace" {
  yaml_body = <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: app-space
EOF

}


resource "kubectl_manifest" "resource_quota" {
  yaml_body = <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: app-quota
  namespace: app-space
spec:
  hard:
   
    requests.cpu: "2"          
    requests.memory: 2Gi        
    limits.cpu: "4"             
    limits.memory: 4Gi          

    
    pods: "20"                  
    services: "5"               
EOF

  depends_on = [kubectl_manifest.namespace]
}


resource "kubectl_manifest" "deployment" {

  yaml_body = <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: app-space
  labels:
    app: my-app
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app: my-app
      containers:
      - name: gatusapp
        image: 038774803581.dkr.ecr.eu-west-2.amazonaws.com/ecr_repo
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
EOF

  depends_on = [
    kubectl_manifest.resource_quota
  ]

}



resource "kubectl_manifest" "HorizontalPodAutoscaler" {
  yaml_body = <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: go-app-hpa
  namespace: app-space
  labels:
    app: my-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app

  minReplicas: 2
  maxReplicas: 10  

 
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70  
  
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0   
      policies:
        - type: Percent
          value: 100                  
          periodSeconds: 15
        - type: Pods
          value: 4                    
          periodSeconds: 15
      selectPolicy: Max                

    scaleDown:
      stabilizationWindowSeconds: 300 
      policies:
        - type: Percent
          value: 50                   
          periodSeconds: 60
EOF

  depends_on = [
    kubectl_manifest.deployment
  ]
}

resource "kubectl_manifest" "service" {
  yaml_body = <<EOF
apiVersion: v1
kind: Service
metadata:
  name: service-gatus-app
  namespace: app-space
spec:
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
EOF

}


resource "kubectl_manifest" "ingress" {
  yaml_body = <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  namespace: app-space
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    external-dns.alpha.kubernetes.io/hostname: mubashir.site
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
      - mubashir.site
    secretName: mubashir-site-tls
  rules:
    - host: mubashir.site
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service-gatus-app
                port:
                  number: 80
EOF

  depends_on = [
    kubectl_manifest.deployment,
  ]
}



####On favorites tab on google there is actually a demonstration to show
###how HPA works
##Karpenter scales nodes not pods