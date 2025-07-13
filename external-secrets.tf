resource "helm_release" "external-secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.18.2"
  create_namespace = true
  namespace        = "external-secrets"
  depends_on       = [module.eks_blueprints_addons, aws_iam_role.externalsecrets-role]

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.externalsecrets-role.arn
  }
}