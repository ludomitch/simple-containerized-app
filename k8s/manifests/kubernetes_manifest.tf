data "terraform_remote_state" "eks" {
  backend = "local"
  config = {
    path = "../terraform.tfstate"
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


locals {
  api_service_deployment_manifests = split("---\n", file("api-service.yaml"))
  db_service_deployment_manifests = split("---\n", file("db-service.yaml"))
  postgres_deployment_manifests = split("---\n", file("postgres.yaml"))
  postgres_init_configmap_manifests = split("---\n", file("postgres-init-configmap.yaml"))

  # grafana_dashboard_manifest = file("grafana-dashboard.yaml")
  kube_state_metrics_manifests = split("---\n", file("kube-state-metrics.yaml"))
  prometheus_grafana_manifests = split("---\n", file("prometheus-grafana.yaml"))

}


resource "kubernetes_namespace" "simple_app" {
  metadata {
    name = "simple-app"
  }
}

resource "kubernetes_manifest" "api_service_manifests" {
  count = length(local.api_service_deployment_manifests)
  manifest = yamldecode(local.api_service_deployment_manifests[count.index])
  depends_on = [kubernetes_namespace.simple_app]
}

resource "kubernetes_manifest" "db_service_manifests" {
  count = length(local.db_service_deployment_manifests)
  manifest = yamldecode(local.db_service_deployment_manifests[count.index])
  depends_on = [kubernetes_namespace.simple_app]
}

resource "kubernetes_manifest" "postgres_deployment_manifests" {
  count = length(local.postgres_deployment_manifests)
  manifest = yamldecode(local.postgres_deployment_manifests[count.index])
  depends_on = [kubernetes_namespace.simple_app]
}

resource "kubernetes_manifest" "postgres_init_configmap_manifests" {
  count = length(local.postgres_init_configmap_manifests)
  manifest = yamldecode(local.postgres_init_configmap_manifests[count.index])
  depends_on = [kubernetes_namespace.simple_app]
}

resource "kubernetes_manifest" "kube_state_metrics_manifests" {
  count = length(local.kube_state_metrics_manifests)
  manifest = yamldecode(local.kube_state_metrics_manifests[count.index])
  depends_on = [kubernetes_namespace.simple_app]
 }



resource "kubernetes_manifest" "prometheus_grafana_manifests" {
  count = length(local.prometheus_grafana_manifests)
  manifest = yamldecode(local.prometheus_grafana_manifests[count.index])
  depends_on = [kubernetes_namespace.simple_app]

}
