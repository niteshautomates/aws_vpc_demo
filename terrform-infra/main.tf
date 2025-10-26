# Create DynamoDB Table


module "dynamodb" {
  source = "./terraform-dynamodb-module"

  table_name   = "vpc-resources-tb"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "resource_id"

  attributes = [
    {
      name = "resoruce_id"
      type = "S"
    },
    {
      name = "email"
      type = "S"
    }
  ]

  ttl_enabled          = true
  ttl_attribute_name   = "expiry_time"
  enable_streams       = true
  stream_view_type     = "NEW_AND_OLD_IMAGES"
  point_in_time_recovery = true

  tags = {
    Environment = "dev"
    Service     = "user"
  }
}
