minikube start

kubectl apply -f manifests/

kubectl port-forward service/api-service 8000:8000 &
kubectl port-forward service/grafana 3000:3000 & 