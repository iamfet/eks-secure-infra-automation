# VAULT SERVER INFRASTRUCTURE
# IRSA Role for Vault Server - Enables auto-unsealing via AWS KMS
module "vault_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name = "${var.project_name}-vault-irsa"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["vault:vault"]
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# Attach KMS policy to Vault IRSA role
resource "aws_iam_role_policy_attachment" "vault_kms" {
  role       = module.vault_irsa.name
  policy_arn = aws_iam_policy.vault_kms.arn
}

# IAM Policy for Vault KMS operations
resource "aws_iam_policy" "vault_kms" {
  name = "${var.project_name}-vault-kms-policy"
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

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# KMS Key and Alias for Vault auto-unsealing
resource "aws_kms_key" "vault_unseal" {
  description = "Vault unseal key"
  tags = {
    Name        = "vault-unseal-key"
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/vault-unseal-key"
  target_key_id = aws_kms_key.vault_unseal.key_id
}


resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  version          = "0.28.1"
  create_namespace = true
  namespace        = "vault"
  depends_on       = [module.eks, aws_kms_key.vault_unseal]

  values = [
    file("${path.module}/helm-values/vault.yaml")
  ]

  set = [
    {
      name  = "server.serviceAccount.create"
      value = "true"
    },
    {
      name  = "server.serviceAccount.name"
      value = "vault"
    },
    {
      name  = "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.vault_irsa.arn
    }
  ]
}
