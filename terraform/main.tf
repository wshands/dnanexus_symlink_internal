provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Biogen = "dx-importer-symlink-s3-files-in-DNAnexus"
    }
  }
}

module "symlink_lambda_internal" {
  source = "./modules/dx-symlink-lambda"
  lambda_function_name = "DxSymlinkInternal"
  lambda_image_uri = var.symlink_lambda_internal_image_uri
  dnanexus_drive = var.dnanexus_drive_id
  dnanexus_project = var.dnanexus_project_id
  dnanexus_symlinks_folder = var.dnanexus_symlinks_folder
  dnanexus_token_secret_name = var.dnanexus_token_secret_name
  dnanexus_token_secret_key = var.dnanexus_token_secret_key
}

module "symlink_lambda_deleter" {
  source = "./modules/dx-symlink-lambda"
  lambda_function_name = "DxSymlinkDeleter"
  lambda_image_uri = var.symlink_lambda_deleter_image_uri
  dnanexus_drive = var.dnanexus_drive_id
  dnanexus_project = var.dnanexus_project_id
  dnanexus_symlinks_folder = var.dnanexus_symlinks_folder
  dnanexus_token_secret_name = var.dnanexus_token_secret_name
  dnanexus_token_secret_key = var.dnanexus_token_secret_key
}

module "symlink_lambda_tagger" {
  source = "./modules/dx-symlink-lambda"
  lambda_function_name = "DxSymlinkTagger"
  lambda_image_uri = var.symlink_lambda_tagger_image_uri
  dnanexus_drive = var.dnanexus_drive_id
  dnanexus_project = var.dnanexus_project_id
  dnanexus_symlinks_folder = var.dnanexus_symlinks_folder
  dnanexus_token_secret_name = var.dnanexus_token_secret_name
  dnanexus_token_secret_key = var.dnanexus_token_secret_key
}

# Add Lambda trigger from S3 bucket
# A file added to the proper bucket will trigger the Lambda
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification
# https://stackoverflow.com/questions/68245765/add-trigger-to-aws-lambda-functions-via-terraform
# There can be only one aws_s3_bucket_notification resource per bucket, so
# it seems we cannot put aws_s3_bucket_notification in generic module code,
# so define it here where we can add all the triggers at one time.
# https://github.com/gruntwork-io/terragrunt/issues/1077

# use 'data' to referece an already existing bucket
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket
data "aws_s3_bucket" "transfer-bucket" {
  bucket = var.target_bucket_name
}

resource "aws_lambda_permission" "allow_bucket_internal" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.symlink_lambda_internal.function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.transfer-bucket.arn
}

resource "aws_lambda_permission" "allow_bucket_deleter" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.symlink_lambda_deleter.function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.transfer-bucket.arn
}

resource "aws_lambda_permission" "allow_bucket_tagger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.symlink_lambda_tagger.function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.transfer-bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = data.aws_s3_bucket.transfer-bucket.id

  lambda_function {
    lambda_function_arn = module.symlink_lambda_internal.function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.target_bucket_filter_prefix
    filter_suffix       = var.target_bucket_filter_suffix
  }

  lambda_function {
    lambda_function_arn = module.symlink_lambda_deleter.function_arn
    events              = ["s3:ObjectRemoved:*"]
    filter_prefix       = var.target_bucket_filter_prefix
    filter_suffix       = var.target_bucket_filter_suffix
  }

  lambda_function {
    lambda_function_arn = module.symlink_lambda_tagger.function_arn
    events              = ["s3:ObjectTagging:*"]
    filter_prefix       = var.target_bucket_filter_prefix
    filter_suffix       = var.target_bucket_filter_suffix
  }

  depends_on = [
    aws_lambda_permission.allow_bucket_internal,
    aws_lambda_permission.allow_bucket_deleter,
    aws_lambda_permission.allow_bucket_tagger
    ]
}