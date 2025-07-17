module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.59"

  role_name                      = "${var.project_name}-external-secrets-irsa"
  attach_external_secrets_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets-system:external-secrets"]
    }
  }

  tags = {
    "Environment" = "dev"
    "Terraform"   = "true"
  }
}

##iam role for external secrets
#resource "aws_iam_role" "externalsecrets-role" {
#  name       = "externalsecrets_sa_role"
#  depends_on = [module.eks]
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Action = ["sts:AssumeRoleWithWebIdentity"]
#        Effect = "Allow"
#        Sid    = ""
#        # all services within EKS can assume this role
#        Principal = {
#          Federated = module.eks.oidc_provider_arn
#        }
#      },
#    ]
#  })
#}
#
#resource "aws_iam_role_policy" "external-secrets-policy" {
#  name = "external-secrets-sa-policy"
#  role = aws_iam_role.externalsecrets-role.id
#
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        #Read access to all secrets in the secrets manager
#        Effect   = "Allow"
#        Resource = "*"
#        Action = [
#          "secretsmanager:GetRandomPassword",
#          "secretsmanager:GetResourcePolicy",
#          "secretsmanager:GetSecretValue",
#          "secretsmanager:DescribeSecret",
#          "secretsmanager:ListSecretVersionIds",
#          "secretsmanager:ListSecrets",
#          "secretsmanager:BatchGetSecretValue"
#        ]
#      },
#    ]
#  })
#}

#resource "kubernetes_service_account" "externalsecrets-sa" {
#  depends_on = [aws_iam_role.externalsecrets-role, kubernetes_namespace.online-boutique]
#  metadata {
#    name      = "externalsecrets-sa"
#    namespace = "online-boutique"
#
#    # maps the IAM Role to the Kubernetes Service Account
#    annotations = {
#      "eks.amazonaws.com/role-arn" = aws_iam_role.externalsecrets-role.arn
#    }
#  }
#}


resource "helm_release" "external-secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.18.2"
  create_namespace = true
  namespace        = "external-secrets-system"
  depends_on       = [module.eks, helm_release.aws-load-balancer-controller, module.external_secrets_irsa]

  set = [
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-secrets"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.external_secrets_irsa.iam_role_arn
    }
  ]
}