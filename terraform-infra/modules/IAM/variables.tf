variable "role_name" {
  description = "Name of the IAM Role"
  type        = string
}

variable "assume_role_services" {
  description = "List of AWS services that can assume this role (e.g., lambda.amazonaws.com, ec2.amazonaws.com)"
  type        = list(string)
}

variable "policy_files" {
  description = "List of local JSON policy file paths to attach to the IAM role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to assign to the IAM role"
  type        = map(string)
  default     = {}
}

variable "table_name" {
  description = "Name of the DynamoDB table (used in IAM policy)"
  type        = string
  default     = null
}
