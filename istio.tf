# 1. Install istio-base first (CRDs and base components)
resource "helm_release" "istio-base" {
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = "1.26.2"
  create_namespace = true
  namespace        = "istio-system"
  depends_on       = [module.eks_blueprints_addons]
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
  namespace        = "istio-gateway"
  depends_on       = [helm_release.istiod, aws_security_group.istio-gateway-lb]

  values = [
    templatefile("${path.module}/istio-gateway-values.yaml.tfpl",
    { lb_security_group_id = aws_security_group.istio-gateway-lb.id })
  ]

  set {
    name  = "replicaCount"
    value = "2"
  }

  set {
    name  = "affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight"
    value = "100"
  }

  set {
    name  = "affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchLabels.app"
    value = "istio-ingressgateway"
  }

  set {
    name  = "affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.topologyKey"
    value = "kubernetes.io/hostname"
  }
}

resource "aws_security_group" "istio-gateway-lb" {
  name       = "istio-gateway-lb"
  vpc_id     = module.vpc.vpc_id
  depends_on = [module.vpc]
}

resource "aws_vpc_security_group_ingress_rule" "istio-gateway-lb_http" {
  security_group_id = aws_security_group.istio-gateway-lb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "istio-gateway-lb_https" {
  security_group_id = aws_security_group.istio-gateway-lb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.istio-gateway-lb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.istio-gateway-lb.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

# Allow load balancer to reach worker nodes for health checks
resource "aws_vpc_security_group_ingress_rule" "nodes_from_lb_health" {
  security_group_id            = module.eks.node_security_group_id
  referenced_security_group_id = aws_security_group.istio-gateway-lb.id
  from_port                    = 15021
  to_port                      = 15021
  ip_protocol                  = "tcp"
  description                  = "Istio gateway health check"
  depends_on                   = [module.eks]
}

# Allow load balancer to reach worker nodes for HTTP/HTTPS traffic
resource "aws_vpc_security_group_ingress_rule" "nodes_from_lb_nodeport" {
  security_group_id            = module.eks.node_security_group_id
  referenced_security_group_id = aws_security_group.istio-gateway-lb.id
  from_port                    = 30000
  to_port                      = 32767
  ip_protocol                  = "tcp"
  description                  = "NodePort range for Istio gateway HTTP/HTTPS"
  depends_on                   = [module.eks]
}