# 1️⃣ Create HTTP API (v2)
resource "aws_apigatewayv2_api" "http_api" {
  name          = var.api_name
  protocol_type = "HTTP"
}

# 2️⃣ Create Lambda Integrations (one per function)
resource "aws_apigatewayv2_integration" "lambda_integrations" {
  for_each = var.lambda_map

  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# 3️⃣ Define Routes (HTTP method → Lambda)
resource "aws_apigatewayv2_route" "routes" {
  for_each = {
    "GET /vpcs/{resource_id}" = "get_resource"
    "DELETE /vpcs"            = "delete_vpc"
    "POST /vpc"               = "create_vpc"
  }

  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integrations[each.value].id}"
}

# 4️⃣ Default Stage (auto-deploy)
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# 5️⃣ Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw_lambda_permissions" {
  for_each = var.lambda_map

  statement_id  = "AllowInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

