data "aws_route53_zone" "fetdevops" {
  name = "fetdevops.com"
}

module "cert_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name                          = "${var.project_name}-cm-irsa"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [data.aws_route53_zone.fetdevops.arn]

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
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
  depends_on       = [module.eks, module.cert_manager_irsa, helm_release.aws-load-balancer-controller]

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.cert_manager_irsa.arn
    }
  ]
}