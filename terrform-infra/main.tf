data "aws_caller_identity" "current" {}
# Create S3 bucket and DyanamoDB table for terraform backend
resource "aws_s3_bucket" "tfstate" {
  bucket        = "20251028-terraform-state-bucket"
  force_destroy = false

  tags = {
    Name = "terraform-state-bucket"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "tfstate_versioning" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "tfstate_public_access" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "tfstate_lifecycle" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    filter {}
  }
}

# private access control 
resource "aws_s3_bucket_ownership_controls" "tfstate_ownership" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_dynamodb_table" "lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = var.dynamodb_table_name
  }
}



# Create DynamoDB Table to store VPC resoruces


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
  depends_on = [module.lambda_iam_role, module.dynamodb]
  source     = "./modules/lambda"

  for_each = var.lambda_functions


  function_name         = each.key
  handler               = each.value.handler
  runtime               = each.value.runtime
  source_path           = "${path.module}/${each.value.source_path}"
  role_arn              = module.lambda_iam_role.role_arn
  environment_variables = each.value.environment
}


#Create API Gateway to access lambda functions

module "api_gateway" {
  depends_on              = [module.lambda_iam_role, module.lambda_functions, module.dynamodb]
  source                  = "./modules/api-gateway"
  api_name                = "vpc-management-api"
  region                  = "ap-south-1"
  cognito_authorizer_name = "custom-authorizer"

  lambda_map = {
    get_resource = { arn = module.lambda_functions["get_resource"].arn, name = module.lambda_functions["get_resource"].name }
    delete_vpc   = { arn = module.lambda_functions["delete_vpc"].arn, name = module.lambda_functions["delete_vpc"].name }
    create_vpc   = { arn = module.lambda_functions["create_vpc"].arn, name = module.lambda_functions["create_vpc"].name }
  }
  cognito_authorizer_arn = "arn:aws:cognito-idp:ap-south-1:602061978233:userpool/ap-south-1_SmcPZ5nDx"
}
