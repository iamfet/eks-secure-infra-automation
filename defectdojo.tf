#resource "helm_release" "defectdojo" {
#  name       = "defectdojo"
#  chart      = "https://github.com/DefectDojo/django-DefectDojo/tree/master/helm/defectdojo"
#  namespace  = "defectdojo"
#  depends_on = [module.eks, helm_release.istio-ingressgateway, kubernetes_namespace.defectdojo]
#
#  values = [
#    file("${path.module}/helm-values/defectdojo.yaml")
#  ]
#}