resource "helm_release" "defectdojo" {
  name       = "defectdojo"
  repository = "https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/master/helm/defectdojo"
  chart      = "defectdojo"
  version    = "1.6.142"
  namespace  = "defectdojo"
  depends_on = [module.eks, helm_release.istio-ingressgateway, kubernetes_namespace.defectdojo]

  values = [
    file("${path.module}/helm-values/defectdojo.yaml")
  ]
}