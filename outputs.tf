output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "istio_ingress_nlb_sg_id" {
  value       = aws_security_group.istio_ingress_nlb.id
  description = "Security group ID for the Istio ingress NLB"
}

output "istio_ingress_nlb_sg_id" {
  value       = aws_security_group.istio_gateway_lb.id
  description = "Security group ID for the Istio ingress NLB"
}
