#!/bin/bash

echo "Destroying Kubernetes resources"
cd manifests
terraform destroy -auto-approve
echo "Destroying EKS cluster"
cd ..
terraform destroy -auto-approve
