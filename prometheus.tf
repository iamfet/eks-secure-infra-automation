resource "helm_release" "istio_prometheus" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "75.12.0"
  create_namespace = true
  namespace        = "monitoring"
  depends_on       = [helm_release.istiod]
  values = [
    <<-EOF
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
    EOF
  ]
}