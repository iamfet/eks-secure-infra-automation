provider "aws" {
  region = var.aws_region
}

#VPC for Cluster
data "aws_availability_zones" "azs" {

} #queries AWS to provide the names of availability zones dynamically

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1" #6.0

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
    Terraform                                               = "true"
    Environment                                             = var.environment
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                                = 1 # Identifies this subnet for external load balancers
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"                       = 1 # Identifies this subnet for internal services
  }
}

#EKS for Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.9" #21.0

  name               = "${var.project_name}-eks-cluster"
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access = true

  addons = {
    coredns                = {}
    eks-pod-identity-agent = { before_compute = true }
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Set authentication mode to API
  authentication_mode = "API"

  # Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  # Add access entries
  access_entries = {
    admin = {
      principal_arn = aws_iam_role.external-admin.arn
      type          = "STANDARD"
      access_scope = {
        type = "cluster"
      }
    }

    developer = {
      principal_arn = aws_iam_role.external-developer.arn
      type          = "STANDARD"
      access_scope = {
        type       = "namespace"
        namespaces = ["online-boutique"]
      }
    }

    example = {
      principal_arn = "arn:aws:iam::495599766789:user/fetdevops"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    dev = {
      instance_types = ["t2.large"]
      min_size       = 1
      max_size       = 4
      desired_size   = 2

      tags = {
        "k8s.io/cluster-autoscaler/enabled"                         = "true"
        "k8s.io/cluster-autoscaler/${var.project_name}-eks-cluster" = "owned"
      }
    }
  }

  node_security_group_additional_rules = {

    #Enables automatic sidecar injection when pods are created
    ingress_15017 = {
      description                   = "Cluster API to Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }

    #Enables service discovery and configuration distribution
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  tags = {
    environment = var.environment
    terraform   = true
  }
}

# EBS CSI Driver IRSA (commented out - replaced with Pod Identity)
# module "ebs_csi_driver_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
#   version = "~> 6.0"
#
#   name                  = "ebs-csi-irsa"
#   attach_ebs_csi_policy = true
#
#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
#   }
#
#   tags = {
#     Environment = var.environment
#     Terraform   = "true"
#   }
# }

# EBS CSI Driver Pod Identity
module "ebs_csi_driver_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "ebs-csi-driver"

  attach_aws_ebs_csi_policy = true

  associations = {
    ebs-csi = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}





#module "eks_blueprints_addons" {
#  depends_on = [module.eks]
#  source     = "aws-ia/eks-blueprints-addons/aws"
#  version    = "~> 1.21"
#
#  cluster_name      = module.eks.cluster_name
#  cluster_endpoint  = module.eks.cluster_endpoint
#  cluster_version   = module.eks.cluster_version
#  oidc_provider_arn = module.eks.oidc_provider_arn
#
#  enable_aws_load_balancer_controller = false
#  enable_metrics_server               = false
#  enable_cluster_autoscaler           = false
#  enable_external_secrets             = false
#
#}
