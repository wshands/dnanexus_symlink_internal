
# Input variable definitions

variable "lambda_function_name" {
  description = "The name of the AWS lambda function in AWS that will be shown in the console"
  type = string
}

variable "lambda_image_uri" {
  description = "The URI of the AWS lambda Docker image"
  type = string
}

/*
variable "s3_trigger_event" {
  description = "The S3 event that will trigger the Lambda function"
  type = string
}
*/