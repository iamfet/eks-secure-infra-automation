resource "helm_release" "external-secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.18.2"
  create_namespace = true
  namespace        = "external-secrets-system"
  depends_on       = [module.eks, helm_release.aws-load-balancer-controller]

  wait = true

  set = [
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-secrets"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.external_secrets_irsa.iam_role_arn
    }
  ]
}