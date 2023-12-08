
# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."
  type    = string
  default = "us-east-1"
}

variable "symlink_lambda_internal_image_uri" {
  description = "URI of the Docker image that is used to deploy the internal lambda function"
  type = string
}

variable "symlink_lambda_deleter_image_uri" {
  description = "URI of the Docker image that is used to deploy the deleter lambda function"
  type = string
}

variable "symlink_lambda_tagger_image_uri" {
  description = "URI of the Docker image that is used to deploy the tagger lambda function"
  type = string
}

variable "dnanexus_drive_id" {
  description = "DNAnexus ID of symlink drive"
  type = string
}

variable "dnanexus_project_id" {
  description = "DNAnexus project ID"
  type = string
}

variable "dnanexus_symlinks_folder" {
  description = "DNAnexus symlink folder name"
  type = string
  default = "/symlinks"
}

variable "dnanexus_token_secret_name" {
  description = "DNAnexus token secret name in AWS secrets manager"
  type = string
  sensitive = true
}

variable "dnanexus_token_secret_key" {
  description = "DNAnexus token secret key in AWS secrets manager"
  type = string
  sensitive = true
}

variable "target_bucket_name" {
  description = "AWS bucket to which files are transferred"
  type = string
}

variable "target_bucket_filter_prefix" {
  description = "Subfolder to monitor of AWS bucket to which files are transferred"
  # https://nedinthecloud.com/2022/09/26/using-optional-arguments-in-terraform-input-variables/
  type = string
  default = null
}

variable "target_bucket_filter_suffix" {
  description = "File suffix to monitor of AWS bucket to which files are transferred"
  type = string
  default = null
}