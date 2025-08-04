resource "helm_release" "istio_prometheus" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "75.15.2"
  create_namespace = true
  namespace        = "monitoring"
  depends_on       = [helm_release.istiod, helm_release.cert_manager]
  values = [
    <<-EOF
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
    grafana:
      sidecar:
        dashboards:
          enabled: true
          label: grafana_dashboard
          labelValue: "1"
          searchNamespace: ALL
    EOF
  ]
}