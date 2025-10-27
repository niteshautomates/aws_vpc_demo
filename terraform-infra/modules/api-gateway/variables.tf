variable "api_name" {
  type        = string
  description = "Name of the API Gateway"
}

variable "region" {
  type        = string
  description = "AWS region of API Gateway and Lambdas"
}

variable "lambda_map" {
  type = map(object({
    arn  = string
    name = string
  }))
  description = "Map of Lambda functions with arn and name. Keys: get_resource, delete_vpc, create_vpc"
}


variable "cognito_authorizer_name" {
  type        = string
  description = "Name of the API Gateway Cognito authorizer"
  
}