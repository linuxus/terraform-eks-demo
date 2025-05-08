# AWS EKS Terraform Deployment

This repository contains Terraform configuration files to deploy a production-ready Amazon EKS (Elastic Kubernetes Service) cluster with core add-ons and best-practice configurations.

## Architecture Overview

This deployment creates:

- A complete VPC with public and private subnets across 3 availability zones
- An EKS cluster with managed node groups
- Essential EKS add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI Driver)
- IAM role integration with proper access permissions
- Pod Identity configuration for secure AWS service access

## Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate permissions
- kubectl (for interacting with the cluster post-deployment)

## Module Versions

- AWS Provider: >= 5.0.0
- Kubernetes Provider: >= 2.20.0
- Helm Provider: >= 2.10.0
- EKS Module: >= 19.15.0
- VPC Module: ~> 5.1.0

## Quick Start

1. Clone this repository
2. Review and modify variables in `variables.tf` according to your needs
3. Initialize, plan, and apply the Terraform configuration:

```bash
terraform init
terraform plan
terraform apply
```

4. After deployment, configure kubectl to interact with your new cluster:

```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw aws_region)
```

## Key Features

### VPC Configuration

- Properly configured VPC with public and private subnets
- NAT gateways for outbound internet access from private subnets
- Environment-specific NAT gateway configuration (single for dev/staging, one per AZ for prod)
- EKS-specific subnet tagging for proper integration

### EKS Cluster

- EKS 1.32 with managed node groups
- Configurable node instance types, group sizes, and capacity type (on-demand/spot)
- Secure by default with controlled API endpoint access

### EKS Add-ons

The following EKS add-ons are deployed:

- **CoreDNS**: Kubernetes cluster DNS
- **kube-proxy**: Network proxy for Kubernetes networking
- **VPC CNI**: Pod networking for AWS VPC
- **EBS CSI Driver**: For dynamic provisioning of EBS volumes

### IAM Integration

- **Pod Identity**: Modern approach for AWS service integration
- **Access Entries**: For secure admin access to the cluster
- **Admin Role**: Configured using the `AmazonEKSClusterAdminPolicy`

## Configuration Options

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| aws_region | AWS region to deploy resources | us-west-2 |
| project | Project name | hashi |
| environment | Environment name (dev, staging, prod) | dev |
| vpc_cidr | CIDR block for VPC | 10.0.0.0/16 |
| kubernetes_version | Kubernetes version | 1.32 |
| node_instance_types | Instance types for worker nodes | ["t3.small"] |
| node_group_min_size | Minimum size of node group | 1 |
| node_group_max_size | Maximum size of node group | 5 |
| node_group_desired_size | Desired size of node group | 3 |
| node_capacity_type | Capacity type for worker nodes | ON_DEMAND |
| admin_role_arn | ARN of IAM role for EKS cluster admin access | AWS SSO Admin role |
| allowed_ips | List of CIDR blocks allowed to access EKS API | ["0.0.0.0/0"] |

### Outputs

| Output | Description |
|--------|-------------|
| cluster_name | EKS cluster name |
| cluster_endpoint | Endpoint for EKS control plane |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_iam_role_name | IAM role name associated with EKS cluster |
| pod_identity_enabled | Whether Pod Identity is enabled for the cluster |
| vpc_id | ID of the VPC |
| private_subnets | List of IDs of private subnets |
| public_subnets | List of IDs of public subnets |

## IAM Access and Security

This deployment uses the modern AWS EKS access entries and Pod Identity features:

1. **Admin Access**: Configured through access entries, aligning with AWS best practices
2. **EBS CSI Driver**: Uses Pod Identity to access AWS EBS APIs securely
3. **Security Groups**: Properly configured for node-to-node and control plane communication

## Customization

### Adding Additional Node Groups

To add additional node groups, extend the `eks_managed_node_groups` block in `eks.tf`. For example:

```hcl
eks_managed_node_groups = {
  default_node_group = {
    # existing configuration...
  }
  
  high_performance = {
    name           = "high-perf-nodes"
    min_size       = 0
    max_size       = 3
    desired_size   = 1
    instance_types = ["c5.2xlarge"]
    capacity_type  = "ON_DEMAND"
  }
}
```

### Adding More EKS Add-ons

To add more EKS add-ons, extend the `cluster_addons` block in `eks.tf`.

## Best Practices Implemented

- Multi-AZ deployment for high availability
- Private subnet placement for worker nodes
- Appropriate security group configurations
- IAM role-based access control
- Pod Identity for secure AWS API access
- Production-ready VPC configuration

## Maintenance and Upgrades

To upgrade the Kubernetes version:

1. Update the `kubernetes_version` variable
2. Run `terraform plan` and `terraform apply`

Upgrading will follow the EKS-managed upgrade process with minimal disruption.

## License

This project is licensed under the MIT License - see the LICENSE file for details.