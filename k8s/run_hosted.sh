
echo "Creating EKS cluster"
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
echo "EKS Cluster created"

echo "Creating Kubernetes resources"
cd manifests
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
echo "Kubernetes resources created"

echo "You can access the app via the following DNS"
terraform output load_balancer_dns