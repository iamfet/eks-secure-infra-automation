variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets_cidr" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets_cidr" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "fet-shop"
}

variable "cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "aws_region" {
  description = "AWS region where the EKS cluster will be created"
  type        = string
  default     = "us-east-1"
}

variable "user_for_admin_role" {
  description = "ARN of AWS user for admin role"
  type        = string
  # No default value
}

variable "user_for_dev_role" {
  description = "ARN of AWS user for developer role"
  type        = string
  # No default value
}

# If the git repository that ArgoCD syncs is private, these variables are required
variable "gitops_url" {
  description = "URL of git repo argocd connects and sync"
  type        = string
  # No default value
}

variable "gitops_username" {
  description = "Username of git repo argocd connects and sync"
  type        = string
  # No default value
}

variable "gitops_password" {
  description = "Password of git repo argocd connects and sync"
  type        = string
  # No default value
}