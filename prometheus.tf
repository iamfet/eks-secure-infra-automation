resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = "27.28.0"
  namespace        = "monitoring"
  create_namespace = true
  depends_on       = [module.eks, helm_release.aws-load-balancer-controller]
}