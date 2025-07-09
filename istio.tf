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
  depends_on       = [helm_release.istiod]

  values = [
    templatefile("${path.module}/istio-gateway-values.yaml.tfpl",
    { lb_security_group_id = aws_security_group.istio-gateway-lb.id })
  ]
}

resource "aws_security_group" "istio-gateway-lb" {
  name   = "istio-gateway-lb"
  vpc_id = module.vpc.vpc_id
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