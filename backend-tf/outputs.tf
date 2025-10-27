output "bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.lock.name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}