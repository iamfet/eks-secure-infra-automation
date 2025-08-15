data "aws_route53_zone" "fetdevops" {
  name = "fetdevops.com"
}

# Cert Manager Pod Identity
module "cert_manager_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "${var.project_name}-cert-manager"

  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [data.aws_route53_zone.fetdevops.arn]

  associations = {
    cert-manager = {
      cluster_name    = module.eks.cluster_name
      namespace       = "cert-manager"
      service_account = "cert-manager"
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}



resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.18.2"
  namespace        = "cert-manager"
  create_namespace = true
  depends_on       = [module.eks, module.cert_manager_pod_identity, helm_release.aws-load-balancer-controller]

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },

  ]
}

# Cert Manager IRSA (commented out - replaced with Pod Identity)
# module "cert_manager_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
#   version = "~> 6.0"
#
#   name                          = "${var.project_name}-cm-irsa"
#   attach_cert_manager_policy    = true
#   cert_manager_hosted_zone_arns = [data.aws_route53_zone.fetdevops.arn]
#
#   oidc_providers = {
#     eks = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["cert-manager:cert-manager"]
#     }
#   }
#
#   tags = {
#     Environment = var.environment
#     Terraform   = "true"
#   }
# }