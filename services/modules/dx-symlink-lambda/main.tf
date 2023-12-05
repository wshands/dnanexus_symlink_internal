
resource "aws_lambda_function" "dx_symlink_lambda" {
  function_name = var.lambda_function_name
  image_uri = var.lambda_image_uri
  package_type  = "Image"
  timeout = 300
  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "dx_symlink" {
  name = "/aws/lambda/${aws_lambda_function.dx_symlink_lambda.function_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda_${var.lambda_function_name}"

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
        # TODO limit this to our particular secret resource?
        Resource = "*"
      },
      {   
          # Allow the Lambda to manipulate S3 buckets and objects
          # TODO limit this to only what the Lambda needs to do on a specific bucket?
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
