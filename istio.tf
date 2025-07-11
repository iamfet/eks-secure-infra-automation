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
    { lb_security_group_id = aws_security_group.istio_gateway_lb.id })
  ]
}

resource "aws_security_group" "istio_gateway_lb" {
  name        = "${var.project_name}-istio-gateway-lb"
  description = "Allows HTTP/HTTPS to Istio ingress gateway NLB"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.project_name}-istio-gateway-lb"
  }

  depends_on = [module.vpc]
}

# Ingress: Allow HTTP (port 80) from anywhere
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.istio_gateway_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP from anywhere"
}

# Ingress: Allow HTTPS (port 443) from anywhere
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.istio_gateway_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow HTTPS from anywhere"
}

#Allow Istio health checks (required for NLB -> Istio pods)
resource "aws_vpc_security_group_ingress_rule" "health_check" {
  security_group_id = aws_security_group.istio_gateway_lb.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 15021
  to_port           = 15021
  ip_protocol       = "tcp"
  description       = "Allow HTTPS from anywhere"
}

# Egress: Allow all IPv4 outbound traffic
resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.istio_gateway_lb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound IPv4 traffic"
}

# Egress: Allow all IPv6 outbound traffic
resource "aws_vpc_security_group_egress_rule" "all_ipv6" {
  security_group_id = aws_security_group.istio_gateway_lb.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound IPv6 traffic"
}
