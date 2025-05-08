locals {
  cluster_name = "${var.project}-${var.environment}-eks"
  vpc_name     = "${var.project}-${var.environment}-vpc"

  azs = [
    "${var.aws_region}a",
    "${var.aws_region}b",
    "${var.aws_region}c"
  ]

  common_tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}