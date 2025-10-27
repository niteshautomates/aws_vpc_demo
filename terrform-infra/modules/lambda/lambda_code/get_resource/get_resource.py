# get_vpc_lambda.py
import os
import json
import boto3

dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DDB_TABLE', 'vpc-resources-tb')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    resource_id = event.get('pathParameters', {}).get('resource_id')
    if not resource_id:
        return {"statusCode":400, "body": json.dumps({"message":"resource_id required"})}

    resp = table.get_item(Key={"resource_id": resource_id})
    item = resp.get('Item')
    if not item:
        return {"statusCode":404, "body": json.dumps({"message":"not found"})}

    return {"statusCode":200, "body": json.dumps(item)}
