import json


def lambda_handler(event, context):
    """
    Basic Lambda handler.
    Replace the body with your real logic later.
    """
    print("Event received:", json.dumps(event))

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello from Lambda! Deployed via Terraform + GitHub Actions + S3."
        })
    }