# IRSA Roles
# Allows Vault server pods to access AWS KMS for auto-unsealing
module "vault_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.59.0"

  role_name = "vault-kms-role"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["vault:vault"]
    }
  }

  role_policy_arns = {
    kms = aws_iam_policy.vault_kms.arn
  }
}

resource "aws_iam_policy" "vault_kms" {
  name = "vault-kms-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      Resource = aws_kms_key.vault_unseal.arn
    }]
  })
}

# Allows application pods to authenticate with Vault using AWS identity
# instead of kubernetes tokens
module "online_boutique_vault_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.59.0"

  role_name = "online-boutique-vault-role"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["online-boutique:vault-auth"]
    }
  }
}

# KMS Resources
resource "aws_kms_key" "vault_unseal" {
  description = "Vault unseal key"
  tags = {
    Name = "vault-unseal-key"
  }
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/vault-unseal-key"
  target_key_id = aws_kms_key.vault_unseal.key_id
}

# Helm Release
resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = "0.28.1"
  create_namespace = true
  namespace        = "vault"
  depends_on       = [module.eks, aws_kms_key.vault_unseal]

  values = [
    file("${path.module}/vault-values.yaml")
  ]

  set {
    name  = "server.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.vault_irsa.iam_role_arn
  }
}