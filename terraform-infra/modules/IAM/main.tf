###########################################
# IAM Role Creation
###########################################
resource "aws_iam_role" "this" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = var.assume_role_services
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge({
    Name = var.role_name
  }, var.tags)
}

###########################################
# Custom IAM Policies from JSON Files
###########################################

resource "aws_iam_policy" "custom_policies" {
  for_each = { for idx, file in var.policy_files : idx => file }

  name        = "${var.role_name}-policy-${each.key}"
  description = "Custom IAM policy for ${var.role_name}"

  policy = templatefile(each.value, {
    region      = data.aws_region.current.name
    account_id  = data.aws_caller_identity.current.account_id
    table_name  = var.table_name
  })
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

###########################################
# Attach Each Policy to the Role
###########################################
resource "aws_iam_role_policy_attachment" "policy_attachments" {
  for_each   = aws_iam_policy.custom_policies
  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}
