
# Input variable definitions

variable "lambda_function_name" {
  description = "The name of the AWS lambda function in AWS that will be shown in the console"
  type = string
}

variable "lambda_image_uri" {
  description = "The URI of the AWS lambda Docker image"
  type = string
}

variable "dnanexus_drive" {
  description = "The URI of the AWS lambda Docker image"
  type = string
}

variable "dnanexus_project" {
  description = "The URI of the AWS lambda Docker image"
  type = string
}

variable "dnanexus_symlinks_folder" {
  description = "The URI of the AWS lambda Docker image"
  type = string
}

variable "dnanexus_token_secret_name" {
  description = "DNAnexus token secret name in AWS secrets manager"
  type = string
}

variable "dnanexus_token_secret_key" {
  description = "DNAnexus token secret key in AWS secrets manager"
  type = string
}