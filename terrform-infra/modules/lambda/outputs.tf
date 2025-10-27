# ------------------------------
# OUTPUTS
# ------------------------------
output "name" {
  value = aws_lambda_function.demo_lambdas.function_name
}

output "arn" {
  value = aws_lambda_function.demo_lambdas.arn
}

output "module_path" {
  value       = path.module
  description = "The filesystem path of the module where this expression is placed."
}
