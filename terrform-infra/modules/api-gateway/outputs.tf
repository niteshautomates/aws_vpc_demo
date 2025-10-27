output "api_endpoint" {
  description = "Public endpoint of the HTTP API"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "api_id" {
  description = "API ID of the HTTP API"
  value       = aws_apigatewayv2_api.http_api.id
}

output "cognito_authorizer_name" {
  value = aws_apigatewayv2_authorizer.custom-authorizer.name
}