
# Output value definitions

output "function_name" {
  description = "Name of the Lambda function."
  value = aws_lambda_function.dx_symlink_lambda.function_name
}

output "function_arn" {
  description = "AWS arn of the Lambda function."
  value = aws_lambda_function.dx_symlink_lambda.arn
}