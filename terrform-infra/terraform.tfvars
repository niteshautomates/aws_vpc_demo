lambda_functions = {
  "create_vpc" = {
    handler     = "create_vpc.lambda_handler"
    runtime     = "python3.13"
    source_path = "modules/lambda/lambda_code/create_vpc"
    environment = {
      TABLE_NAME = "vpc-resources-tb"
      REGION     = "ap-south-1"
    }
  }

  "delete_vpc" = {
    handler     = "delete_vpc.lambda_handler"
    runtime     = "python3.13"
    source_path = "modules/lambda/lambda_code/delete_vpc"
    environment = {
      TABLE_NAME = "vpc-resources-tb"
      REGION     = "ap-south-1"
    }
  }

  "get_resource" = {
    handler     = "get_resource.lambda_handler"
    runtime     = "python3.13"
    source_path = "modules/lambda/lambda_code/get_resource"
    environment = {
      TABLE_NAME = "vpc-resources-tb"
      REGION     = "ap-south-1"
    }
  }
}
