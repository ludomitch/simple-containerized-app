# Kubernetes Simple-App Deployment Guide

This project demonstrates a simple two-service API setup with a Postgres database orchestrated using Kubernetes.

## Project Overview

This directory contains scripts and configurations for deploying a multi-service application with monitoring capabilities on Kubernetes, either locally or on AWS using Terraform.

The deployment includes:
- API Service
- Database Service
- PostgreSQL Database
- Prometheus for metrics collection
- Grafana for metrics visualization

## Technologies Used

- Kubernetes: For container orchestration
- Python: For both services
- FastAPI: For the API service
- psycopg2: For PostgreSQL communication in the db_service
- PostgreSQL: As the database
- Prometheus: For monitoring
- Grafana: For visualization of metrics

## Project Structure

```
.
├── README.md
├── run_hosted.sh
├── run_local.sh
├── cluster_creation.tf
└── manifests/
│   ├── kubernetes_manifest.tf
│   ├── api_service.yaml
│   ├── db_service.yaml
│   ├── postgres.yaml
│   ├── postgres-init-configmap.yaml
│   ├── prometheus-grafana.yaml
│   └── kube-state-metrics.yaml
└── api_service/
│   ├── Dockerfile
│   └── main.py
│   └── requirements.txt
└── db_service/
│   ├── Dockerfile
│   └── main.py
│   └── requirements.txt
```


## Setup and Running

### Requirements
Before proceeding with the deployment, ensure you have the following tools installed:
- Minikube or a Kubernetes cluster
- kubectl configured to use your cluster
- Docker (for building images)
- Terraform: For provisioning and managing infrastructure
- AWS CLI: For interacting with AWS services


## Deployment Scripts

### 1. Local Deployment: `run_local.sh`

This script sets up the Kubernetes services locally using Minikube. It:

1. Starts Minikube
2. Applies Kubernetes manifests
3. Sets up port forwarding for services

After running, you can access:
- Grafana dashboard: `http://localhost:3000`
- API Service: `http://localhost:8000`

Usage:
```
bash run_local.sh
```

### 2. Hosted Deployment: `run_hosted.sh`

This script deploys the Kubernetes services on AWS using Terraform. It:

1. Initializes Terraform
2. Creates the necessary AWS resources
3. Applies Kubernetes manifests
4. Outputs the DNS addresses for accessing the services

After running, the script will output the DNS addresses for accessing the Grafana dashboard and API Service.

Usage:
```
bash run_hosted.sh
```

Finally, there is a wind_down.sh script that will destroy the cluster and delete the resources.

## Grafana Dashboard

A preconfigured Grafana dashboard has been set up for monitoring the deployed services. This dashboard provides visualizations for key metrics and performance indicators.

To access the dashboard:
- For local deployment: Navigate to `http://localhost:3000`
- For hosted deployment: Use the Grafana DNS address provided by the `run_hosted.sh` script

Login credentials for Grafana are default to username: `admin` and password: `admin`. You can change these credentials on the login screen.

## Note

Ensure you have the necessary permissions and credentials set up for AWS access when using the hosted deployment script.

You can do this via the AWS CLI:
```
aws configure
```

## Useful Commands

### Terraform

```
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
terraform destroy -auto-approve
```

### Kubernetes

```
aws eks --region eu-west-1 update-kubeconfig --name my-eks-cluster
kubectl logs --all-containers=true --selector=app --tail=100 -n=simple-app

kubectl apply -f manifests/
kubectl rollout restart deployment
```