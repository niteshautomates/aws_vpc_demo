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

resource "aws_apigatewayv2_authorizer" "custom-authorizer" {
  api_id                            = aws_apigatewayv2_api.http_api.id
  authorizer_type                   = "JWT"
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "custom-authorizer"
  jwt_configuration {
    audience = ["kb8epg3au1grcdngua0hli37o"]
    issuer = "https://cognito-idp.ap-south-1.amazonaws.com/ap-south-1_SmcPZ5nDx"
  }
}


# 3️⃣ Define Routes (HTTP method → Lambda)
resource "aws_apigatewayv2_route" "routes" {
  for_each = {
    "GET /vpcs/{resource_id}" = "get_resource"
    "DELETE /vpcs"            = "delete_vpc"
    "POST /vpcs"              = "create_vpc"
  }

  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integrations[each.value].id}"
 

  authorization_type = "JWT"


  authorizer_id = aws_apigatewayv2_authorizer.custom-authorizer.id


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

