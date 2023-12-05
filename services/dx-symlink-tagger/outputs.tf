
# Output value definitions

output "function_name" {
  description = "Name of the Lambda function."
  value = module.symlink_lambda.function_name
}

output "function_arn" {
  description = "arn of the Lambda function."
  value = module.symlink_lambda.arn
}