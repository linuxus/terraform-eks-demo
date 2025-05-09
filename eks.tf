module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 19.15.0"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster access configuration
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.allowed_ips

# EKS Addons that are necessary for cluster
  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    # Add EBS CSI driver addon with Pod Identity
    aws-ebs-csi-driver = {
      most_recent = true
      # No service_account_role_arn needed with Pod Identity
      pod_identity_associations = {
        # Associate the EBS CSI controller service account with an IAM role
        ebs_csi_controller = {
          service_account      = "ebs-csi-controller-sa"
          namespace            = "kube-system"
          role_arn             = aws_iam_role.ebs_csi_role.arn
        }
      }
    }
  }

# Access Entry Configuration
  access_entries = {
    admin = {
      kubernetes_groups = ["masters"]
      principal_arn     = var.admin_role_arn
      type              = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
          }
        }
      }
    }
  }

  # Enable EKS Managed Node Groups
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = var.node_instance_types
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    default_node_group = {
      name           = "default-node-group"
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      desired_size   = var.node_group_desired_size
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      tags = merge(
        local.common_tags,
        {
          "k8s.io/cluster-autoscaler/enabled"               = "true"
          "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
        }
      )
    }
  }

  tags = local.common_tags
}

# Create IAM role for EBS CSI Driver using Pod Identity
resource "aws_iam_role" "ebs_csi_role" {
  name = "${local.cluster_name}-ebs-csi-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach the required EBS CSI policies to the role
resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}