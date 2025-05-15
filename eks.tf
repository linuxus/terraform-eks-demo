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
  # Add the cluster creator (the identity used by Terraform) as an administrator via access entry
  enable_cluster_creator_admin_permissions = true

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

  # Enable EKS Managed Node Groups with custom IAM role
 eks_managed_node_group_defaults = {
  ami_type       = "AL2_x86_64"
  instance_types = var.node_instance_types
  attach_cluster_primary_security_group = true
  
  # Create and use a custom IAM role for the node group
  create_iam_role = true
  iam_role_additional_policies = {
    # Add the required policy for EBS volume operations
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }
  
  # Disable tagging of node security groups with the cluster tag
  # This prevents the kubernetes.io/cluster/xxx tag from being applied
  node_security_group_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = null
  }
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

# Create a custom policy for additional EBS volume permissions if needed
resource "aws_iam_policy" "ebs_volume_permissions" {
  name        = "${local.cluster_name}-ebs-volume-permissions"
  description = "Additional permissions for EBS volume operations"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:ModifyVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots"
        ],
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach the custom policy to the EBS CSI role
resource "aws_iam_role_policy_attachment" "ebs_volume_permissions_attachment" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = aws_iam_policy.ebs_volume_permissions.arn
}

# Get the security group ID of the node group
data "aws_security_group" "node_group_sg" {
  tags = {
    "aws:eks:cluster-name" = local.cluster_name
    "eks:nodegroup-name"   = "${local.cluster_name}-default-node-group"
  }

  # This filter helps to identify the node group SG more precisely
  filter {
    name   = "description"
    values = ["*node*", "*eks*"]
  }

  # This dependency ensures that the data source is read after the EKS cluster is created
  depends_on = [module.eks]
}

# Custom Resource to remove Kubernetes cluster tag from the node security group
resource "null_resource" "remove_cluster_tag" {
  # This runs after the EKS module has completed
  depends_on = [module.eks, data.aws_security_group.node_group_sg]
  
  # Only run this when the EKS cluster is created or the security group changes
  triggers = {
    node_security_group_id = data.aws_security_group.node_group_sg.id
    cluster_name           = local.cluster_name
  }

  # Remove the cluster tag using AWS CLI
  provisioner "local-exec" {
    command = <<-EOT
      aws ec2 delete-tags \
        --resources ${data.aws_security_group.node_group_sg.id} \
        --tags Key=kubernetes.io/cluster/${local.cluster_name}
    EOT
  }
}

