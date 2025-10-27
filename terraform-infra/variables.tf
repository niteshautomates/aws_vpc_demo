variable "lambda_functions" {
  description = "Map of Lambda functions to deploy"
  type = map(object({
    handler     = string
    runtime     = string
    source_path = string
    environment = map(string)
  }))
}


