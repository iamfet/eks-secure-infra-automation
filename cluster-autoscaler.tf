# Cluster Autoscaler Pod Identity
module "cluster_autoscaler_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${var.project_name}-cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  associations = {
    cluster-autoscaler = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "cluster-autoscaler"
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}



resource "helm_release" "cluster-autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.48.0"
  namespace  = "kube-system"
  depends_on = [module.eks, helm_release.aws-load-balancer-controller, module.cluster_autoscaler_pod_identity]

  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "awsRegion"
      value = var.aws_region
    },
    {
      name  = "rbac.create"
      value = "true"
    },
    {
      name  = "rbac.serviceAccount.create"
      value = "true"
    },
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },

    #Fine tune autoscaling
    {
      name  = "extraArgs.scale-down-unneeded-time"
      value = "2m"
    },
    {
      name  = "extraArgs.skip-nodes-with-local-storage"
      value = "false"
    },
    {
      name  = "extraArgs.skip-nodes-with-system-pods"
      value = "false"
    }
  ]
}

# Cluster Autoscaler IRSA (commented out - replaced with Pod Identity)
# module "cluster_autoscaler_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
#   version = "~> 6.0"
#
#   name                             = "${var.project_name}-ca-irsa"
#   attach_cluster_autoscaler_policy = true
#   cluster_autoscaler_cluster_names = [module.eks.cluster_name]
#
#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:cluster-autoscaler"]
#     }
#   }
#
#   tags = {
#     Environment = var.environment
#     Terraform   = "true"
#   }
# }