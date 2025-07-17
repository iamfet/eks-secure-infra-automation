#Create the IAM Role for Service Account for cluster autoscaler
module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.59"

  role_name                        = "${var.project_name}-cluster-autoscaler-irsa"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = ["${var.project_name}-eks-cluster"]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = {
    "Environment" = "dev"
    "Terraform"   = "true"
  }
}


# IAM role for cluster autoscaler
#resource "aws_iam_role" "cluster_autoscaler" {
#  name = "${var.project_name}-cluster-autoscaler"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [{
#      Action = "sts:AssumeRoleWithWebIdentity"
#      Effect = "Allow"
#      Principal = {
#        Federated = module.eks.oidc_provider_arn
#      }
#      Condition = {
#        StringEquals = {
#          "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
#          "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
#        }
#      }
#    }]
#  })
#}
#
#resource "aws_iam_role_policy" "cluster_autoscaler" {
#  name = "cluster-autoscaler-policy"
#  role = aws_iam_role.cluster_autoscaler.id
#
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [{
#      Effect = "Allow"
#      Action = [
#        "autoscaling:DescribeAutoScalingGroups",
#        "autoscaling:DescribeAutoScalingInstances",
#        "autoscaling:DescribeLaunchConfigurations",
#        "autoscaling:DescribeScalingActivities",
#        "autoscaling:DescribeTags",
#        "ec2:DescribeInstanceTypes",
#        "ec2:DescribeLaunchTemplateVersions"
#      ]
#      Resource = "*"
#    }, {
#      Effect = "Allow"
#      Action = [
#        "autoscaling:SetDesiredCapacity",
#        "autoscaling:TerminateInstanceInAutoScalingGroup",
#        "ec2:DescribeImages",
#        "ec2:GetInstanceTypesFromInstanceRequirements",
#        "eks:DescribeNodegroup"
#      ]
#      Resource = "*"
#    }]
#  })
#}

resource "helm_release" "cluster-autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.48.0"
  namespace  = "kube-system"
  depends_on = [module.cluster_autoscaler_irsa, module.eks, helm_release.aws-load-balancer-controller]

  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "awsRegion"
      value = var.aws_region
    },
    {
      name  = "extraArgs.scale-down-unneeded-time"
      value = "2m"
    },
    {
      name  = "extraArgs.skip-nodes-with-local-storage"
      value = "false"
    },
    {
      name  = "extraArgs.skip-nodes-with-system-pods"
      value = "false"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.cluster_autoscaler_irsa.iam_role_arn
    }
  ]

}