###############################################
# main.tf - Lambda + S3 (artifact bucket)
###############################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state stored in S3 (created below in bootstrap step).
  # Comment this whole "backend" block out for your VERY FIRST local run,
  # then uncomment after the state bucket exists (see the guide).
  
  backend "s3" {
   bucket = "bunnysai95-tfstate-8821"
   key    = "lambda/terraform.tfstate"
   region = "us-east-1"
 }
}

provider "aws" {
  region = var.aws_region
}

###############################################
# S3 bucket that holds the Lambda zip artifact
###############################################
resource "aws_s3_bucket" "artifacts" {
  bucket = var.artifact_bucket_name
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

###############################################
# IAM role the Lambda assumes
###############################################
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lets the Lambda write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

###############################################
# The Lambda function itself
# Code comes from the zip we upload to S3 in CI/CD
###############################################
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  s3_bucket = aws_s3_bucket.artifacts.id
  s3_key    = var.artifact_s3_key

  # Forces an update when the zip content changes
  source_code_hash = var.source_code_hash
}
