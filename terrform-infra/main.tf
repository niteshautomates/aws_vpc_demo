# Create DynamoDB Table


module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = "vpc-resources-tb"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "resource_id"

  attributes = [
    {
      name = "resource_id"
      type = "S"
    }
  ]

  ttl_enabled            = true
  ttl_attribute_name     = "expiry_time"
  enable_streams         = false
  stream_view_type       = "NEW_AND_OLD_IMAGES"
  point_in_time_recovery = true

  tags = {
    Environment = "dev"
    Service     = "aws_vpc_ddb"
  }
}

#lambda IAM Roles
module "lambda_iam_role" {
  source = "./modules/IAM"

  role_name = "lambda-vpc-role"

  assume_role_services = [
    "lambda.amazonaws.com"
  ]

  policy_files = [
    "${path.module}/modules/IAM/IAM_Policy_CWLogs.json",
    "${path.module}/modules/IAM/IAM_Policy_DynamoDB.json.tpl",
    "${path.module}/modules/IAM/IAM_Policy_VPC.json"
  ]
  table_name = module.dynamodb.table_name
  tags = {
    Environment = "dev"
    Owner       = "Nitesh"
    Project     = "aws-vpc-demo"
  }
}


# Create Lambda Functions

provider "aws" {
  region = "ap-south-1"
}

module "lambda_functions" {
  depends_on = [ module.lambda_iam_role,module.dynamodb ]
  source = "./modules/lambda"

  for_each = var.lambda_functions
  

  function_name         = each.key
  handler               = each.value.handler
  runtime               = each.value.runtime
  source_path           = "${path.module}/${each.value.source_path}"
  role_arn              = module.lambda_iam_role.role_arn
  environment_variables = each.value.environment
}
