
# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."
  type    = string
  default = "us-east-1"
}

variable "lambda_function_name" {
  description = "The name of the AWS lambda function in AWS that will be shown in the console"
  type = string
}

variable "lambda_image_uri" {
  description = "The URI of the AWS lambda Docker image"
  type = string
}