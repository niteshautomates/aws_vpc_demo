output "api_endpoint" {
  description = "Endpoint of the HTTP API"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "api_id" {
  description = "HTTP API ID"
  value       = aws_apigatewayv2_api.http_api.id
}

output "cognito_authorizer_name" {
  description = "Custome authorizer name"
  value = aws_apigatewayv2_authorizer.custom-authorizer.name
}