# import json
# import random
# from fastapi import FastAPI

# app = FastAPI()

# def lambda_handler(event, context):
#     # Function URLs put the path here
#     path = event.get("rawPath", "/")

#     if path == "/random":
#         numbers = [random.randint(1, 100) for _ in range(5)]
#         return {
#             "statusCode": 200,
#             "body": json.dumps({"random_numbers": numbers})
#         }

#     return {
#         "statusCode": 200,
#         "body": json.dumps({
#             "message": "Hello from Lambda! Deployed via Terraform + GitHub Actions + S3."
#         })
#     }

# @app.route("/example", methods=["GET"])
# def funtion_example():
#     return "Hi bunny this is the first call with the lambda"



from fastapi import FastAPI
from mangum import Mangum

app = FastAPI()


@app.get("/hello")
def hello():
    return {"message": "Hello, this is my basic GET endpoint"}


@app.get("/films")
def films():
    return {"films": ["Magadheera", "Baahubali"]}


# This one line is what makes FastAPI work on Lambda:
handler = Mangum(app)