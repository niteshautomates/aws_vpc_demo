
# ------------------------------
# INPUT VARIABLES
# ------------------------------
variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda handler function (e.g. handler.lambda_handler)"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g. python3.9)"
  type        = string
  default     = "python3.9"
}

variable "source_path" {
  description = "Path to the Python source file or folder"
  type        = string
}

variable "role_arn" {
  description = "IAM Role ARN for Lambda execution"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}