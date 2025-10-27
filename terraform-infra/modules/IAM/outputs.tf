output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "attached_policies" {
  description = "List of attached policy ARNs"
  value       = [for p in aws_iam_policy.custom_policies : p.arn]
}
