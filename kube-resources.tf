data "aws_caller_identity" "current" {}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  admin_session_arn = "arn:aws:sts::${local.account_id}:assumed-role/external-admin/K8SSession"
  dev_session_arn   = "arn:aws:sts::${local.account_id}:assumed-role/external-developer/K8SSession"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

resource "kubernetes_namespace" "online-boutique" {
  depends_on = [module.eks_blueprints_addons]
  metadata {
    name = "online-boutique"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "kubernetes_role" "namespace-viewer" {
  depends_on = [kubernetes_namespace.online-boutique]
  metadata {
    name      = "namespace-viewer"
    namespace = "online-boutique"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "secrets", "configmaps", "persistentvolumeclaims"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "namespace-viewer" {
  depends_on = [kubernetes_role.namespace-viewer]
  metadata {
    name      = "namespace-viewer"
    namespace = "online-boutique"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "namespace-viewer"
  }
  subject {
    kind      = "User"
    name      = local.dev_session_arn
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role" "cluster_viewer" {
  metadata {
    name = "cluster-viewer"
  }

  rule {
    api_groups = [""]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  # port forwarding to enable admin access argocd locally through port-forwarding
  rule {
    api_groups = [""]
    resources  = ["pods", "pods/portforward"]
    verbs      = ["get", "list", "create"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  # Required for istioctl proxy-status and other Istio CLI commands
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts/token"]
    verbs      = ["create"]
  }

  # Istio security resources
  rule {
    api_groups = ["security.istio.io"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_viewer" {
  depends_on = [kubernetes_cluster_role.cluster_viewer]
  metadata {
    name = "cluster-viewer"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-viewer"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = local.admin_session_arn
    api_group = "rbac.authorization.k8s.io"
  }
}

# service account to assume aws externalsecrets-role to fetch secret
resource "kubernetes_service_account" "externalsecrets-sa" {
  depends_on = [aws_iam_role.externalsecrets-role, kubernetes_namespace.online-boutique]
  metadata {
    name      = "externalsecrets-sa"
    namespace = "online-boutique"

    # maps the IAM Role to the Kubernetes Service Account
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.externalsecrets-role.arn
    }
  }
}
