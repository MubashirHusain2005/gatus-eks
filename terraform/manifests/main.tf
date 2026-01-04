resource "kubectl_manifest" "namespace" {
  yaml_body = <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: app-space
EOF
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
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: gatusapp
        image: 038774803581.dkr.ecr.eu-west-2.amazonaws.com/gatusapp:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080

EOF

  depends_on = [
    aws_eks_node_group.private-nodes,

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
    cert-manager.io/cluster-issuer: ${var.cert_issuer}
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
    kubectl_manifest.letsencrypt_staging,
    helm_release.nginx_ingress
  ]

}