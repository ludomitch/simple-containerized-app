# Simple Two-Service API with Database

This project demonstrates a simple two-service API setup with a Postgres database, as requested in the case study.

## Project Structure

```
.
├── README.md
├── docker-compose.yml
├── api_service/
│   ├── Dockerfile
│   └── main.py
├── db_service/
│   ├── Dockerfile
│   └── main.py
└── init.sql
```

## Technologies Used

- Docker and Docker Compose: For containerization and easy local deployment
- Python: For both services
- FastAPI: For the API service
- psycopg2: For PostgreSQL communication in the db_service
- PostgreSQL: As the database

## Setup and Running

### Prerequisites

- Docker and Docker Compose installed on your system

### Steps

1. Clone this repository:
   ```
   git clone <repository-url>
   cd <repository-directory>
   ```

2. Build and run the services:
   ```
   docker-compose up --build
   ```

3. Access the API:
   Open a web browser or use curl to access `http://localhost:8000/`. You should see the "hello world" message.

## Explanation

This setup creates three containers:

1. `postgres`: A PostgreSQL database initialized with a "hello world" string.
2. `db_service`: A Python service that communicates with the database.
3. `api_service`: A FastAPI service that exposes an API endpoint and communicates with the db_service.

The API service calls the db_service, which retrieves the string from the database and returns it to the API service, which then returns it to the client.

## Deployment to Cloud (AWS)

For AWS deployment, you would typically use:

1. Amazon ECS (Elastic Container Service) or EKS (Elastic Kubernetes Service) for container orchestration
2. Amazon RDS for PostgreSQL
3. Application Load Balancer for routing traffic

The exact setup would depend on your specific requirements and scale.

## Monitoring and Observability

For a production setup, consider adding:

1. AWS CloudWatch for logs and metrics
2. Prometheus for more detailed metrics
3. Grafana for visualization

## CI/CD

For continuous integration and deployment, you could use:

1. GitHub Actions for CI/CD pipeline
2. AWS CodePipeline and CodeBuild for AWS-native CI/CD

Remember to adapt the Dockerfiles and docker-compose.yml for production use, including proper security measures and environment-specific configurations.