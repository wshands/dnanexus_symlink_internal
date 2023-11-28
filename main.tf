# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      hashicorp-learn = "lambda-api-gateway"
    }
  }

}

/*
resource "random_pet" "lambda_bucket_name" {
  prefix = "learn-terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}


data "archive_file" "lambda_dx_symlink_internal" {
  type = "zip"

  source_dir  = "${path.module}/dnanexus_symlink_internal"
  output_path = "${path.module}/dx_symlink_internal.zip"
}

resource "aws_s3_object" "lambda_dx_symlink_internal" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "dx_symlink_internal_lambda.zip"
  source = data.archive_file.lambda_dx_symlink_internal.output_path

  etag = filemd5(data.archive_file.lambda_dx_symlink_internal.output_path)
}
*/

resource "aws_lambda_function" "dx_symlink_internal_lambda" {
  function_name = "DxSymlinkInternal"
  image_uri     = "230407893272.dkr.ecr.us-east-1.amazonaws.com/dnanexus_symlink_internal:main"
  package_type  = "Image"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "dx_symlink_internal" {
  name = "/aws/lambda/${aws_lambda_function.dx_symlink_internal_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret
# https://developer.hashicorp.com/terraform/language/data-sources
data "aws_secretsmanager_secret" "migration_dependencies_contributor_token" {
  name = "migration_dependencies_contributor_token"
}

# Give the Lambda function the ability to access secrets using
# and identity policy
# https://stackoverflow.com/questions/70574190/allow-lambda-permission-to-access-secretsmanager-value
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy
resource "aws_iam_role_policy" "sm_policy" {
  name = "sm_access_permissions"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {   
          # Allow the Lambda to manipulate S3 buckets and objects
          # TODO limit this to only what the Lambda needs to do
          # https://stackoverflow.com/questions/57145353/how-to-grant-lambda-permission-to-upload-file-to-s3-bucket-in-terraform
          "Effect": "Allow",
          "Action": [
              "s3:*"
          ],
          "Resource": "arn:aws:s3:::*"
      }
    ]
  })
}


/*
resource "aws_secretsmanager_secret_policy" "secrets_policy" {
  secret_arn = data.aws_secretsmanager_secret.migration_dependencies_contributor_token.arn

  policy = jsonencode(
  {
    Version: "2012-10-17",
    Statement: [
        {
          Sid: "EnableAnotherAWSAccountToReadTheSecret"
          Effect: "Allow"
          Principal: {
            Service = "lambda.amazonaws.com"
          }
          Action: "secretsmanager:GetSecretValue"
          Resource: "*"
        }
    ]
  })
}
*/

# Add Lambda trigger from S3 bucket
# A file added to the proper bucket will trigger the Lambda
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification
# https://stackoverflow.com/questions/68245765/add-trigger-to-aws-lambda-functions-via-terraform

# use 'data' to referece an already existing bucket
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket
data "aws_s3_bucket" "transfer-bucket" {
  bucket = "transferred-files"
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dx_symlink_internal_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.transfer-bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = data.aws_s3_bucket.transfer-bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.dx_symlink_internal_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    #filter_prefix       = "transferred-fles/"
    #filter_suffix       = ".log"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}
