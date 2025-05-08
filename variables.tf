variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "acme"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32"
}

variable "node_instance_types" {
  description = "Instance types for worker nodes"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_group_min_size" {
  description = "Minimum size of node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum size of node group"
  type        = number
  default     = 5
}

variable "node_group_desired_size" {
  description = "Desired size of node group"
  type        = number
  default     = 3
}

variable "node_capacity_type" {
  description = "Capacity type for worker nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "admin_role_arn" {
  description = "ARN of IAM role for EKS cluster admin access"
  type        = string
  # This needs to be a valid IAM role ARN in your account
  default = "arn:aws:iam::777331576745:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_50c61f54e29316fc"
}

variable "allowed_ips" {
  description = "List of CIDR blocks allowed to access EKS API"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Open to all IPs by default, adjust as needed
}