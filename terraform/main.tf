###VPC Networking

resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = var.enable_host
  enable_dns_support   = var.enable_support

  tags = {
    Name = "Main-VPC"
  }
}



resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "IGW"
  }

  depends_on = [aws_vpc.eks_vpc]
}

resource "aws_subnet" "public-subnet-2a" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "Public-subnet-2a"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


resource "aws_subnet" "public-subnet-2b" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "Public-subnet-2b"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}



resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
  Name = "public-rt" }

  depends_on = [aws_vpc.eks_vpc, aws_internet_gateway.igw]
}



resource "aws_route_table_association" "pub-route-association-2a" {

  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-subnet-2a.id

}

resource "aws_route_table_association" "pub-route-association-2b" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-subnet-2b.id
}



resource "aws_subnet" "private-subnet-2a" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "Private-subnet-2a"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "private-subnet-2b" {
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = {
    Name                                        = "Private-subnet-2b"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


resource "aws_eip" "ngw-eip" {
  domain = "vpc"

  tags = {
    Name = "eip"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw" {
  subnet_id     = aws_subnet.public-subnet-2b.id
  allocation_id = aws_eip.ngw-eip.id

  tags = {
    Name = "igw-nat"
  }

  depends_on = [aws_internet_gateway.igw, aws_eip.ngw-eip]
}



resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "private-rt"

  }

  depends_on = [aws_nat_gateway.ngw]

}

resource "aws_route_table_association" "private-route-association-2a" {

  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private-subnet-2a.id


}

resource "aws_route_table_association" "private-route-association-2b" {

  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private-subnet-2b.id

}

##IAM Roles and Policies

#IAM Role for the cluster
resource "aws_iam_role" "cluster" {
  name = "eks-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

#IAM policies for the cluster
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}


resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSBlockStoragePolicy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
}


resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSLoadBalancingPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

#IAM role for nodes


resource "aws_iam_instance_profile" "nodes" {
  name = "eks-node-group-profile"
  role = aws_iam_role.nodes.name
}


resource "aws_iam_role" "nodes" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

#IAM policies for the nodes
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nodes.name
}


#EKS AWS authentication

data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}



#EKS 

resource "aws_eks_cluster" "eks_cluster" {
  name    = "eks-cluster"
  version = "1.30"

  role_arn = aws_iam_role.cluster.arn

  # Controls how Kubernetes API authentication works
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }


  # Tells EKS which subnets to use for control-plane ENIs
  vpc_config {
    subnet_ids = [
      aws_subnet.private-subnet-2a.id,
      aws_subnet.private-subnet-2b.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Environment = "labs"
    Project     = "eks-assignment"
  }


  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSBlockStoragePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSLoadBalancingPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
}

#Kubernetes addons
resource "aws_eks_addon" "vpc-cni" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"
}



resource "aws_eks_addon" "kube-proxy" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"
}

##EBS CSI Driver 


resource "aws_iam_role" "ebs_csi-driver" {
  name = "ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa",
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "storage" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi-driver.name
}



resource "aws_eks_addon" "csi-driver" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"
  configuration_values        = null
  preserve                    = true
  service_account_role_arn    = aws_iam_role.ebs_csi-driver.arn

  depends_on = [ aws_eks_cluster.eks_cluster,
                aws_iam_openid_connect_provider.eks
  ]

}


#KMS Encryption

resource "aws_kms_key" "kms_key" {
  description             = "Encryption KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 20
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/exampleKey"
  target_key_id = aws_kms_key.kms_key.id
}

resource "aws_kms_key_policy" "kms_key_policy" {
  key_id = aws_kms_key.kms_key.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::038774803581:root"
        }

        Action   = "kms:*"
        Resource = "*"
      },

      {
        Sid    = "AllowEKSUseOfKey"
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]

        Resource = "*"
      }
    ]
  })
}



##Node Group
resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_role_arn   = aws_iam_role.nodes.arn
  node_group_name = "eks-node-group"

  subnet_ids = [
    aws_subnet.private-subnet-2a.id,
    aws_subnet.private-subnet-2b.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }


  tags = {
    "kubernetes.io/cluster/${aws_eks_cluster.eks_cluster.name}" = "owned"
  }



  depends_on = [aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonSSMManagedInstanceCore
  ]

}

##Kubernetes + Helm providers + Kubectl

provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}



data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks_cluster.name
}
##1 nginx-ingress controller

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.8.3"
  atomic           = false
  lint             = true
  wait             = true
  timeout          = 600


  set = [
    {
      name  = "controller.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
      value = "nlb"
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
      value = "internet-facing"
    },

    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
      value = "instance"
    },
    {
      name  = "controller.hostNetwork"
      value = "true"
    },

    {
      name  = "controller.replicaCount"
      value = "1"
    },
    {
      name  = "controller.service.externalTrafficPolicy"
      value = "Local"
    }
  ]
  depends_on = [
    aws_eks_node_group.private-nodes
  ]
}


##2  Cert manager

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  version    = "1.16.1"

  create_namespace = true
  wait             = true
  timeout          = 600

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },

  ]

  depends_on = [aws_eks_node_group.private-nodes]
}





#3  Cluster_issuer yaml file
resource "kubectl_manifest" "letsencrypt_staging" {
  yaml_body = <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: stokemubashir@gmail.com
    privateKeySecretRef:
      name: letsencrypt-nginx-cert-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "letsencrypt_prod" {
  yaml_body = <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server:  https://acme-v02.api.letsencrypt.org/directory
    email: stokemubashir@gmail.com
    privateKeySecretRef:
      name: letsencrypt-nginx-cert
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

  depends_on = [
    helm_release.cert_manager
  ]
}

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


##6 External DNS

resource "kubectl_manifest" "external_dns_namespace" {
  yaml_body = <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: external-dns
EOF
}



resource "aws_iam_role" "external_dns" {
  name = "iam-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:external-dns:external-dns",
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "external_dns_route53" {
  name = "external-dns-route53-policy"
  role = aws_iam_role.external_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "kubernetes_service_account_v1" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "external-dns"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
    }
  }
  depends_on = [kubectl_manifest.external_dns_namespace]
}


resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = "external-dns"
  create_namespace = false
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = "1.14.0"

  wait    = true
  timeout = 600

  set = [
    {
      name  = "provider"
      value = "aws"
    },
    {
      name  = "aws.region"
      value = "eu-west-2"
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "external-dns"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_dns.arn
    }
  ]

  depends_on = [
    kubectl_manifest.external_dns_namespace,
    kubernetes_service_account_v1.external_dns,
    aws_iam_role.external_dns,
    aws_iam_role_policy.external_dns_route53
  ]
}

#ArgoCD 

resource "helm_release" "argocd" {
  name              = "argocd"
  repository        = "https://argoproj.github.io/argo-helm"
  chart             = "argo-cd"
  version           = "5.24.1" 
  namespace         = "argo-cd"
  create_namespace  = true
  timeout           = 500



  set = [
    {
    name  = "server.service.type"
    value = "LoadBalancer" 
  },
  {
    name  = "server.ingress.enabled"
    value = "true"
  }
]
  depends_on = [ aws_eks_node_group.private-nodes ]
}
