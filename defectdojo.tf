resource "helm_release" "defectdojo" {
  name       = "defectdojo"
  repository = "https://defectdojo.github.io/django-DefectDojo"
  chart      = "defectdojo"
  namespace  = "defectdojo"
  depends_on = [module.eks, helm_release.istio-ingressgateway, kubernetes_namespace.defectdojo]

  values = [
    file("${path.module}/helm-values/defectdojo.yaml")
  ]
}