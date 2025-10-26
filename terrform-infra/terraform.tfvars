lambda_functions = {
  "create-vpc-lambda" = {
    handler     = "create_vpc.lambda_handler"
    runtime     = "python3.13"
    source_path = "modules/lambda/lambda_code/create_vpc"
    environment = {
      TABLE_NAME = "vpc-resources-tb"
      REGION     = "ap-south-1"
    }
  }

  "delete-vpc-lambda" = {
    handler     = "delete_vpc.lambda_handler"
    runtime     = "python3.13"
    source_path = "modules/lambda/lambda_code/delete_vpc"
    environment = {
      TABLE_NAME = "vpc-resources-tb"
      REGION     = "ap-south-1"
    }
  }

  "get-resource-lambda" = {
    handler     = "get_resource.lambda_handler"
    runtime     = "python3.13"
    source_path = "modules/lambda/lambda_code/get_resource"
    environment = {
      TABLE_NAME = "vpc-resources-tb"
      REGION     = "ap-south-1"
    }
  }
}
