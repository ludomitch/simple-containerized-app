from fastapi import FastAPI, HTTPException
import httpx
import logging
from prometheus_client import make_asgi_app, Counter
import os

app = FastAPI()
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)
# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__ + " API SERVICE")

# Define a counter metric
REQUEST_COUNT = Counter("request_count", "Total number of requests to the API")
REQUEST_ERROR_COUNT = Counter(
    "request_error_count", "Total number of errors during requests to the API"
)

DB_SERVICE_URL = os.environ.get("DB_SERVICE_URL", "http://db-service:8000")


@app.get("/")
async def root() -> str:
    logger.info("Received request at root endpoint")
    try:
        logger.info(f"Attempting to connect to db-service at {DB_SERVICE_URL}")
        async with httpx.AsyncClient() as client:
            logger.info("Created httpx client")
            response = await client.get(f"{DB_SERVICE_URL}/get_string")
            logger.info(f"Received response from db-service: {response.status_code}")
            response.raise_for_status()
            logger.info(f"Response from db-service: {response.text}")
            REQUEST_COUNT.inc()
            return response.text
    except httpx.HTTPStatusError as e:
        logger.error(f"HTTP error occurred: {e}")
        REQUEST_ERROR_COUNT.inc()
        raise HTTPException(status_code=e.response.status_code, detail=str(e))
    except httpx.RequestError as e:
        logger.error(f"Request error occurred: {e}")
        REQUEST_ERROR_COUNT.inc()
        raise HTTPException(
            status_code=500, detail=f"Failed to connect to db-service: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn

    logger.info("Starting the application")
    uvicorn.run(app, host="0.0.0.0", port=8000)
