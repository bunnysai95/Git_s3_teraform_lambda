###############################################
# variables.tf
###############################################

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "git-s3-terraform-lambda"
}

variable "artifact_bucket_name" {
  description = "S3 bucket that stores the Lambda zip. MUST be globally unique."
  type        = string
}

variable "artifact_s3_key" {
  description = "Path/key of the zip inside the bucket"
  type        = string
  default     = "lambda/lambda.zip"
}

variable "source_code_hash" {
  description = "Base64 sha256 of the zip. Passed in from CI/CD."
  type        = string
  default     = ""
}
