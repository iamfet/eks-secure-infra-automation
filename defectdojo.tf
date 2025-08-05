resource "helm_release" "defectdojo" {
  name       = "defectdojo"
  repository = "https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/helm-charts"
  chart      = "defectdojo"
  version    = "1.6.153"
  namespace  = "defectdojo"
  depends_on = [module.eks, helm_release.istio-ingressgateway, kubernetes_namespace.defectdojo]

  values = [
    file("${path.module}/helm-values/defectdojo.yaml")
  ]
}