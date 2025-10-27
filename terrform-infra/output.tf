# output "lambda_function_arns" {
#   value = { for k, v in module.lambda_functions : k => v.arn }
# }
output "congito-authorizer-name" {
  value = module.api_gateway.cognito_authorizer_name
}

output "bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.lock.name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}