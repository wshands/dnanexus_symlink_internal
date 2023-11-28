# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Output value definitions

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.dx_symlink_internal_lambda.function_name
}

