resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.18.2"
  namespace        = "cert-manager"
  create_namespace = true
  depends_on       = [module.eks]

  set {
    name  = "installCRDs"
    value = "true"
  }
}