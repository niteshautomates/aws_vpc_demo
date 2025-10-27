variable "lambda_functions" {
  description = "Map of Lambda functions to deploy"
  type = map(object({
    handler     = string
    runtime     = string
    source_path = string
    environment = map(string)
  }))
}


variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "dynamodb_table_name" {
  type    = string
  default = "terraform-state-lock"
}
