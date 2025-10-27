variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "dynamodb_table_name" {
  type    = string
  default = "terraform-state-lock"
}
