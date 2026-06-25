from fastapi import FastAPI
from mangum import Mangum

app = FastAPI(title="My Lambda FastAPI")


@app.get("/")
def root():
    return {"message": "Hello from FastAPI on Lambda!"}


@app.get("/hello")
def hello():
    return {"message": "Hi bunny, this is my first FastAPI call on Lambda"}


@app.get("/random")
def random_numbers():
    import random
    return {"random_numbers": [random.randint(1, 100) for _ in range(5)]}


@app.get("/films/{film_id}")
def get_film(film_id: int):
    return {"film_id": film_id, "title": "Baahubali"}


# Mangum wraps your FastAPI app and becomes the Lambda entry point.
handler = Mangum(app)

