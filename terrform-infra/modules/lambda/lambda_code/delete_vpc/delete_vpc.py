import os
import json
import boto3
from datetime import datetime
from botocore.exceptions import ClientError

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
ec2 = boto3.client('ec2')

# DynamoDB table name (environment variable or default)
TABLE_NAME = os.environ.get('DDB_TABLE', 'vpc-resources')

def lambda_handler(event, context):
    body = event.get('body')
    if isinstance(body, str):
        body = json.loads(body)

    resource_id = body.get('resource_id')
    if not resource_id:
        return {"statusCode": 400, "body": json.dumps({"message": "resource_id required"})}

    table = dynamodb.Table(TABLE_NAME)

    # Fetch record from DynamoDB
    try:
        resp = table.get_item(Key={"resource_id": resource_id})
        item = resp.get('Item')
        if not item:
            return {"statusCode": 404, "body": json.dumps({"message": "Resource not found in DynamoDB"})}
    except ClientError as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

    vpc_id = item['vpc_id']
    region = item.get('region', ec2.meta.region_name)
    ec2_regional = boto3.client('ec2', region_name=region)

    try:
        # ---------------------------------------------------
        # 1️⃣ Delete Route Table Associations and Route Table
        # ---------------------------------------------------
        rt_info = item.get('route_table', {})
        if rt_info:
            rt_id = rt_info.get('route_table_id')
            associations = rt_info.get('associations', [])

            # Disassociate subnets from the route table
            for assoc in associations:
                assoc_id = assoc.get('association_id')
                if assoc_id:
                    try:
                        ec2_regional.disassociate_route_table(AssociationId=assoc_id)
                    except ClientError:
                        pass  # skip if already disassociated

            # Delete non-local routes
            if rt_id:
                try:
                    routes = ec2_regional.describe_route_tables(RouteTableIds=[rt_id])['RouteTables'][0]['Routes']
                    for r in routes:
                        if 'GatewayId' in r and r['DestinationCidrBlock'] != 'local':
                            try:
                                ec2_regional.delete_route(RouteTableId=rt_id, DestinationCidrBlock=r['DestinationCidrBlock'])
                            except ClientError:
                                pass
                    ec2_regional.delete_route_table(RouteTableId=rt_id)
                except ClientError:
                    pass

        # ---------------------------------------------------
        # 2️⃣ Detach and Delete Internet Gateway
        # ---------------------------------------------------
        igw_info = item.get('internet_gateway', {})
        igw_id = igw_info.get('igw_id')
        if igw_id:
            try:
                ec2_regional.detach_internet_gateway(VpcId=vpc_id, InternetGatewayId=igw_id)
            except ClientError:
                pass
            try:
                ec2_regional.delete_internet_gateway(InternetGatewayId=igw_id)
            except ClientError:
                pass

        # ---------------------------------------------------
        # 3️⃣ Delete Subnets
        # ---------------------------------------------------
        for sn in item.get('subnets', []):
            sn_id = sn.get('subnet_id')
            if sn_id:
                try:
                    ec2_regional.delete_subnet(SubnetId=sn_id)
                except ClientError:
                    pass

        # ---------------------------------------------------
        # 4️⃣ Delete Non-default Security Groups
        # ---------------------------------------------------
        try:
            sgs = ec2_regional.describe_security_groups(Filters=[{"Name": "vpc-id", "Values": [vpc_id]}])['SecurityGroups']
            for sg in sgs:
                if sg['GroupName'] != 'default':
                    try:
                        ec2_regional.delete_security_group(GroupId=sg['GroupId'])
                    except ClientError:
                        pass
        except ClientError:
            pass

        # ---------------------------------------------------
        # 5️⃣ Delete the VPC
        # ---------------------------------------------------
        try:
            ec2_regional.delete_vpc(VpcId=vpc_id)
        except ClientError as e:
            return {"statusCode": 500, "body": json.dumps({"message": f"Failed to delete VPC: {str(e)}"})}

        # ---------------------------------------------------
        # 6️⃣ Delete record from DynamoDB
        # ---------------------------------------------------
        try:
            table.delete_item(Key={"resource_id": resource_id})
        except ClientError as e:
            return {"statusCode": 500, "body": json.dumps({"message": f"VPC deleted but DynamoDB cleanup failed: {str(e)}"})}

        # ---------------------------------------------------
        # ✅ Final success response
        # ---------------------------------------------------
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": f"VPC {vpc_id} and all its components deleted successfully",
                "resource_id": resource_id,
                "deleted_at": datetime.utcnow().isoformat() + "Z"
            })
        }

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
