from fastapi import FastAPI, HTTPException
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import logging
from prometheus_client import make_asgi_app, Counter

app = FastAPI()

metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)
# Define a counter metric
DB_REQUEST_COUNT = Counter(
    "db_request_count", "Total number of requests to the database"
)
DB_ERROR_COUNT = Counter(
    "db_error_count", "Total number of errors during requests to the database"
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__ + " DB SERVICE")


def get_db_connection():
    try:
        DB_REQUEST_COUNT.inc()  # Increment the counter
        connection_params = {
            "host": os.environ.get("DB_HOST", "postgres"),
            "port": os.environ.get("DB_PORT", "5432"),
            "database": os.environ["DB_NAME"],
            "user": os.environ["DB_USER"],
        }
        logger.info(f"Attempting to connect with params: {connection_params}")
        return psycopg2.connect(
            **connection_params,
            password=os.environ["DB_PASSWORD"],
        )
    except psycopg2.Error as e:
        DB_ERROR_COUNT.inc()  # Increment the counter
        logger.error(f"Unable to connect to the database: {e}")
        raise HTTPException(status_code=500, detail="Database connection error")


@app.get("/get_string")
def get_string() -> str:
    logger.info("Attempting to retrieve string from database")
    conn = None
    cur = None
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        logger.info(
            "Executing SQL query: SELECT string_value FROM strings WHERE id = 1"
        )
        cur.execute("SELECT string_value FROM strings WHERE id = 1")
        result = cur.fetchone()
        if result is None:
            logger.warning("No string found with id = 1")
            raise HTTPException(status_code=404, detail="String not found")
        logger.info("Successfully retrieved string from database")
        return result["string_value"]
    except psycopg2.Error as e:
        logger.error(f"Database error: {e}")
        raise HTTPException(status_code=500, detail="Database error")
    finally:
        if cur:
            logger.debug("Closing database cursor")
            cur.close()
        if conn:
            logger.debug("Closing database connection")
            conn.close()


if __name__ == "__main__":
    import uvicorn

    logger.info(f"Starting the application on port 8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)
