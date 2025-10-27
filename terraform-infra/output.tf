# output "lambda_function_arns" {
#   value = { for k, v in module.lambda_functions : k => v.arn }
# }
output "congito-authorizer-name" {
  value = module.api_gateway.cognito_authorizer_name
}

