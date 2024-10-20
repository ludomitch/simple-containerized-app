// Add these data sources at the beginning of the file
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

// Update the provider configuration
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

locals {
  api_service_deployment_manifests = split("---\n", file("api-service-deployment.yaml"))
  db_service_deployment_manifests = split("---\n", file("db-service-deployment.yaml"))
  grafana_dashboard_manifest = file("grafana-dashboard.yaml")
  kube_state_metrics_manifests = split("---\n", file("kube-state-metrics.yaml"))
  postgres_deployment_manifests = split("---\n", file("postgres-deployment.yaml"))
  postgres_init_configmap_manifests = split("---\n", file("postgres-init-configmap.yaml"))
  prometheus_grafana_manifests = split("---\n", file("prometheus-grafana.yaml"))
}

// Update the null resource to use the correct EKS cluster name
resource "null_resource" "wait_for_cluster" {
  depends_on = [data.terraform_remote_state.eks]

  provisioner "local-exec" {
    command = <<-EOT
      aws eks --region ${data.terraform_remote_state.eks.outputs.region} update-kubeconfig --name ${data.terraform_remote_state.eks.outputs.cluster_id}
      kubectl wait --for=condition=Ready nodes --all --timeout=600s
    EOT
  }
}

resource "kubernetes_namespace" "simple_app" {
  metadata {
    name = "simple-app"
  }
  depends_on = [null_resource.wait_for_cluster]
}

resource "kubernetes_manifest" "api_service_manifests" {
  count = length(local.api_service_deployment_manifests)
  manifest = yamldecode(local.api_service_deployment_manifests[count.index])
  depends_on = [null_resource.wait_for_cluster, kubernetes_namespace.simple_app]
}

resource "kubernetes_manifest" "db_service_manifests" {
  count = length(local.db_service_deployment_manifests)
  manifest = yamldecode(local.db_service_deployment_manifests[count.index])
  depends_on = [null_resource.wait_for_cluster, kubernetes_namespace.simple_app]
}

resource "kubernetes_manifest" "grafana_dashboard_manifest" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "ConfigMap"
    "metadata" = {
      "name" = "grafana-dashboards"
      "namespace" = "simple-app"
    }
    "data" = {
      "dashboard.json" = replace(
        replace(local.grafana_dashboard_manifest, "!!json |", ""),
        "\n    ", "\n"
      )
    }
  }
  depends_on = [null_resource.wait_for_cluster, kubernetes_namespace.simple_app]
}

resource "kubernetes_manifest" "kube_state_metrics_manifests" {
  count = length(local.kube_state_metrics_manifests)
  manifest = yamldecode(local.kube_state_metrics_manifests[count.index])
  depends_on = [null_resource.wait_for_cluster, kubernetes_namespace.simple_app]
}

resource "kubernetes_manifest" "postgres_deployment_manifests" {
  count = length(local.postgres_deployment_manifests)
  manifest = yamldecode(local.postgres_deployment_manifests[count.index])
  depends_on = [null_resource.wait_for_cluster, kubernetes_namespace.simple_app]
}

resource "kubernetes_manifest" "postgres_init_configmap_manifests" {
  count = length(local.postgres_init_configmap_manifests)
  manifest = yamldecode(local.postgres_init_configmap_manifests[count.index])
  depends_on = [null_resource.wait_for_cluster, kubernetes_namespace.simple_app]
}

resource "kubernetes_manifest" "prometheus_grafana_manifests" {
  count = length(local.prometheus_grafana_manifests)
  manifest = yamldecode(local.prometheus_grafana_manifests[count.index])
  depends_on = [null_resource.wait_for_cluster, kubernetes_namespace.simple_app]

  // Add this block to handle the ServiceAccount resource
  lifecycle {
    ignore_changes = [
      manifest.metadata[0].namespace,
    ]
  }
}


resource "null_resource" "kubectl_port_forward" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl port-forward service/api-service 8000:8000 &
      kubectl port-forward service/db-service 8001:8000 &
      kubectl port-forward service/grafana 3000:3000 &
      kubectl port-forward service/prometheus 9090:9090 &
    EOT
    
    environment = {
      KUBECONFIG = data.aws_eks_cluster.cluster.endpoint
    }
  }

  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [
    kubernetes_manifest.api_service_manifests,
    kubernetes_manifest.db_service_manifests,
    kubernetes_manifest.prometheus_grafana_manifests
  ]
}
