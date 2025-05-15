output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

# Replace OIDC provider output with Pod Identity-related outputs
output "pod_identity_enabled" {
  description = "Whether Pod Identity is enabled for the cluster"
  value       = true
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# Output the security group IDs for reference
output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_primary_security_group_id
}

output "node_security_group_id" {
  description = "EKS node security group ID"
  value       = try(data.aws_security_group.node_group_sg.id, "Not available yet")
}