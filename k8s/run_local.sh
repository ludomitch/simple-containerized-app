#!/bin/bash

echo "Starting Minikube..."

minikube start

echo "Applying Kubernetes manifests..."
kubectl apply -f manifests/

echo "Port forwarding services..."
kubectl port-forward service/api-service 8000:8000 &
kubectl port-forward service/grafana 3000:3000 & 