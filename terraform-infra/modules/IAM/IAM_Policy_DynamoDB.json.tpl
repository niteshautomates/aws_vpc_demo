{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowDynamoDBWrite",
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": "arn:aws:dynamodb:${region}:${account_id}:table/${table_name}"
        }
    ]
}