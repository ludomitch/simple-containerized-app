# Kubernetes-based Two-Service API with Database, Prometheus, and Grafana

## Project Structure
```
├── README.md
├── api_service/
│ ├── Dockerfile
│ ├── main.py
│ └── requirements.txt
├── db_service/
│ ├── Dockerfile
│ ├── main.py
│ └── requirements.txt
├── manifests/
│ ├── api-service-deployment.yaml
│ ├── db-service-deployment.yaml
│ ├── postgres-deployment.yaml
│ └── postgres-init-configmap.yaml
```
## Technologies Used

- Kubernetes: For container orchestration
- Python: For both services
- FastAPI: For the API service
- psycopg2: For PostgreSQL communication in the db_service
- PostgreSQL: As the database
- Prometheus: For monitoring
- Grafana: For visualization of metrics

## Setup and Running

### Prerequisites

- Minikube or a Kubernetes cluster
- kubectl configured to use your cluster
- Docker (for building images)

### Steps

1. Build the Docker images for api_service and db_service:
   ```
   docker build -t api_service:latest api_service/
   docker build -t db_service:latest db_service/
   ```

2. If using Minikube, load the images into Minikube's registry:
   ```
   minikube image load api_service:latest
   minikube image load db_service:latest
   ```
   If using a remote cluster, push the images to a container registry.

3. Apply the Kubernetes manifests:
   ```
   kubectl apply -f k8s/manifests/
   ```

4. Access the API:
   - If using Minikube:
     ```
     minikube service api-service
     ```
   - If using a remote cluster, get the external IP or NodePort:
     ```
     kubectl get services api-service
     ```

## Monitoring

Prometheus and Grafana are set up to monitor the services. Access them through their respective services:

- Prometheus: `kubectl port-forward service/prometheus 9090:9090`
- Grafana: `kubectl port-forward service/grafana 3000:3000`

Default Grafana credentials:
- Username: admin
- Password: admin

## Troubleshooting

If you encounter issues, check the logs of the services:
