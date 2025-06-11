variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "private_subnets_cidr" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
}

variable "public_subnets_cidr" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the EKS cluster will be created"
  type        = string
}

variable "user_for_admin_role" {
  description = "ARN of AWS user for admin role"
}

variable "user_for_dev_role" {
  description = "ARN of AWS user for developer role"
}