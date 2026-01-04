#EKS 

##Cluster

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
