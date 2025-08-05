# 1. Install istio-base first (CRDs and base components)
resource "helm_release" "istio-base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.26.2"
  create_namespace = true
  namespace        = "istio-system"
  depends_on       = [module.eks, helm_release.aws-load-balancer-controller, helm_release.external-secrets]
}

# 2. Install istiod second (control plane)
resource "helm_release" "istiod" {
  name             = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = "1.26.2"
  create_namespace = false
  namespace        = "istio-system"
  depends_on       = [helm_release.istio-base]
}

# 3. Install istio-ingressgateway last (data plane)
resource "helm_release" "istio-ingressgateway" {
  name             = "istio-ingressgateway"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = "1.26.2"
  create_namespace = true
  namespace        = "istio-ingress"
  depends_on       = [helm_release.istiod]

  values = [
    file("${path.module}/helm-values/istio-gateway.yaml")
  ]
}