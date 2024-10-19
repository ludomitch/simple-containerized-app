# Simple Two-Service API with Database

This project demonstrates a simple two-service API setup with a Postgres database.

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
   docker-compose up --build &
   ```

3. Access the API:
   Open a web browser or use curl to access `http://localhost:8000/`. You should see the "hello world" message.

## Clean up

When you are done playing with the services, you can clean up the containers with the following command:

```
docker-compose -f docker-compose.yml down
```

## Explanation

This setup creates three containers:

1. `postgres`: A PostgreSQL database initialized with a "hello world" string.
2. `db_service`: A Python service that communicates with the database.
3. `api_service`: A FastAPI service that exposes an API endpoint and communicates with the db_service.

The API service calls the db_service, which retrieves the string from the database and returns it to the API service, which then returns it to the client.