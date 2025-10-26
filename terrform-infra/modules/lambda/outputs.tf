# ------------------------------
# OUTPUTS
# ------------------------------
output "lambda_function_name" {
  value = aws_lambda_function.demo_lambdas.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.demo_lambdas.arn
}

output "module_path" {
  value       = path.module
  description = "The filesystem path of the module where this expression is placed."
}