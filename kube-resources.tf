data "aws_eks_cluster" "cluster" {
  name       = "${var.project_name}-eks-cluster"
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = "${var.project_name}-eks-cluster"
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = try(data.aws_eks_cluster.cluster.endpoint, "")
  cluster_ca_certificate = try(base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data), "")
  token                  = try(data.aws_eks_cluster_auth.cluster.token, "")
}

resource "kubernetes_namespace" "online-boutique" {
  depends_on = [module.eks]
  metadata {
    name = "online-boutique"
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
    name      = "developer" # This should match the username in the EKS access entry
    api_group = "rbac.authorization.k8s.io"
  }
  # Add a subject for the assumed role ARN
  subject {
    kind      = "User"
    name      = "arn:aws:sts::495599766789:assumed-role/external-developer/K8SSession"
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
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }

  # Add a subject for the assumed role ARN
  subject {
    kind      = "User"
    name      = "arn:aws:sts::495599766789:assumed-role/external-admin/K8SSession"
    api_group = "rbac.authorization.k8s.io"
  }
}