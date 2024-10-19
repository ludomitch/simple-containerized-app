from fastapi import FastAPI, HTTPException
import httpx
import logging

app = FastAPI()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.get("/")
async def root() -> str:
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get("http://db_service:8000/get_string")
            response.raise_for_status()
            logger.info(f"Response from db_service: {response.text}")
            logger.info(f"Response status code: {response}")
            return response.text
    except httpx.HTTPStatusError as e:
        logger.error(f"HTTP error occurred: {e}")
        raise HTTPException(status_code=e.response.status_code, detail=str(e))
    except httpx.RequestError as e:
        logger.error(f"Request error occurred: {e}")
        raise HTTPException(status_code=500, detail="Failed to connect to db_service")


if __name__ == "__main__":
    import uvicorn

    logger.info("Starting the application")
    uvicorn.run(app, host="0.0.0.0", port=8000)
