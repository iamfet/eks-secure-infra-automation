provider "aws" {
  region = var.aws_region
}

#VPC for Cluster
data "aws_availability_zones" "azs" {
  state = "available"
} #queries AWS to provide the names of availability zones dynamically

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = " ~> 5.21"

  name            = "${var.project_name}-vpc"
  cidr            = var.vpc_cidr_block
  private_subnets = var.private_subnets_cidr
  public_subnets  = var.public_subnets_cidr
  azs             = data.aws_availability_zones.azs.names

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared" # Tags required for EKS to discover subnets
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                                = 1 # Identifies this subnet for external load balancers
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
    "kubernetes.io/role/internal_elb"                       = 1 # Identifies this subnet for internal services
  }

}

#EKS for Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36"

  cluster_name    = "${var.project_name}-eks-cluster"
  cluster_version = var.cluster_version

  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  cluster_endpoint_public_access = true

  create_cluster_security_group = false
  create_node_security_group    = false

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }


  # Set authentication mode to API
  authentication_mode = "API"

  # Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  # Add access entries
  access_entries = {
    admin = {
      principal_arn = aws_iam_role.external-admin.arn
      username      = "admin" # This should match the name used in the Kubernetes role binding
      type          = "STANDARD"
      access_scope = {
        type = "cluster"
      }
    }

    developer = {
      principal_arn = aws_iam_role.external-developer.arn
      username      = "developer" # This should match the name used in the Kubernetes role binding
      type          = "STANDARD"
      access_scope = {
        type       = "namespace"
        namespaces = ["online-boutique"]
      }
    }
  }

  eks_managed_node_groups = {
    dev = {
      instance_types = ["m5.xlarge"]
      min_size       = 1
      max_size       = 4
      desired_size   = 2
    }
  }
  tags = {
    environment = "development"
    application = "${var.project_name}"
  }

}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.21"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn


  enable_aws_load_balancer_controller = true
  enable_metrics_server               = true
  enable_cluster_autoscaler           = true
  cluster_autoscaler = {
    set = [
      {
        name  = "extraArgs.scale-down-unneeded-time"
        value = "2m"
      },
      {
        name  = "extraArgs.skip-nodes-with-local-storage"
        value = false
      },
      {
        name  = "extraArgs.skip-nodes-with-system-pods"
        value = false
      }
    ]
  }

}