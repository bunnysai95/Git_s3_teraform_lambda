import json
import random


def lambda_handler(event, context):
    # Function URLs put the path here
    path = event.get("rawPath", "/")

    if path == "/random":
        numbers = [random.randint(1, 100) for _ in range(5)]
        return {
            "statusCode": 200,
            "body": json.dumps({"random_numbers": numbers})
        }

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello from Lambda! Deployed via Terraform + GitHub Actions + S3."
        })
    }