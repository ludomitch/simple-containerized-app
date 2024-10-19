from fastapi import FastAPI
import httpx

app = FastAPI()


@app.get("/")
async def root():
    async with httpx.AsyncClient() as client:
        response = await client.get("http://db_service:8000/get_string")
    return {"message": response.text}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
