# AWS Load Balancer Controller Pod Identity
module "aws_load_balancer_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${var.project_name}-alb-controller"

  attach_aws_lb_controller_policy = true


  associations = {
    alb-controller = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.13.3"
  namespace  = "kube-system"
  depends_on = [module.eks, module.vpc, module.aws_load_balancer_controller_pod_identity]

  wait = true

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },

  ]
}

# AWS Load Balancer Controller IRSA (replaced with Pod Identity)
# module "aws_load_balancer_controller_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
#   version = "~> 6.0"
#
#   name                                   = "${var.project_name}-alb-controller-irsa"
#   attach_load_balancer_controller_policy = true
#
#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
#     }
#   }
#
#   tags = {
#     Environment = var.environment
#     Terraform   = "true"
#   }
# }