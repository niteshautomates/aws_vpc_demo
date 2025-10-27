# ------------------------------
# OUTPUTS
# ------------------------------
output "name" {
  value = aws_lambda_function.demo_lambdas.function_name
}

output "arn" {
  value = aws_lambda_function.demo_lambdas.arn
}
