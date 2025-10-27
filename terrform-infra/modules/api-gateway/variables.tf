variable "api_name" {
  type        = string
  description = "Name of the API Gateway"
}

variable "region" {
  type        = string
  description = "AWS region where API Gateway and Lambdas are deployed"
}

variable "lambda_map" {
  type = map(object({
    arn  = string
    name = string
  }))
  description = "Map of Lambda functions with arn and name. Keys: get_resource, delete_resource, create_vpc"
}

variable "cognito_authorizer_arn" {
  description = "ARN of existing Cognito Authorizer to attach to routes"
  type        = string
  default     = null
}

variable "cognito_authorizer_name" {
  type        = string
  description = "Name of the API Gateway Cognito authorizer"
  
}