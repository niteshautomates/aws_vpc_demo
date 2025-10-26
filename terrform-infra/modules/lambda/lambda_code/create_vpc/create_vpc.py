import os
import json
import boto3
import time
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
ec2 = boto3.client('ec2')

TABLE_NAME = os.environ.get('DDB_TABLE', 'vpc-resources')

def lambda_handler(event, context):
    try:
        body = event.get('body')
        if isinstance(body, str):
            body = json.loads(body)

        # Expected body:
        # {"cidr": "10.0.0.0/16", "subnets": ["10.0.1.0/24","10.0.2.0/24"], "tags": {"env": "dev"}}
        cidr = body.get('cidr')
        subnet_cidrs = body.get('subnets', [])
        tags = body.get('tags', {})

        if not cidr or not subnet_cidrs:
            return {"statusCode": 400, "body": json.dumps({"message": "cidr and subnets required"})}

        tag_list = [{"Key": k, "Value": v} for k, v in tags.items()]
        tag_list.append({"Key": "CreatedBy", "Value": "vpc-api-lambda"})

        # -------------------------------------------------------
        # 1️⃣ Create VPC
        # -------------------------------------------------------
        vpc_resp = ec2.create_vpc(CidrBlock=cidr)
        vpc_id = vpc_resp['Vpc']['VpcId']

        # Enable DNS support + hostnames for EC2 usability
        ec2.modify_vpc_attribute(VpcId=vpc_id, EnableDnsSupport={'Value': True})
        ec2.modify_vpc_attribute(VpcId=vpc_id, EnableDnsHostnames={'Value': True})

        # Tag the VPC
        ec2.create_tags(Resources=[vpc_id], Tags=tag_list)

        # -------------------------------------------------------
        # 2️⃣ Create Subnets
        # -------------------------------------------------------
        subnets = []
        for sn_cidr in subnet_cidrs:
            sn_resp = ec2.create_subnet(CidrBlock=sn_cidr, VpcId=vpc_id)
            sn_id = sn_resp['Subnet']['SubnetId']
            ec2.create_tags(Resources=[sn_id], Tags=tag_list)
            subnets.append({"subnet_id": sn_id, "cidr": sn_cidr})

        # -------------------------------------------------------
        # 3️⃣ Create Internet Gateway (IGW)
        # -------------------------------------------------------
        igw_resp = ec2.create_internet_gateway()
        igw_id = igw_resp['InternetGateway']['InternetGatewayId']
        ec2.attach_internet_gateway(VpcId=vpc_id, InternetGatewayId=igw_id)
        ec2.create_tags(Resources=[igw_id], Tags=tag_list)

        # -------------------------------------------------------
        # 4️⃣ Create Route Table + Public Route
        # -------------------------------------------------------
        rt_resp = ec2.create_route_table(VpcId=vpc_id)
        rt_id = rt_resp['RouteTable']['RouteTableId']
        ec2.create_tags(Resources=[rt_id], Tags=tag_list)

        # Add route to Internet Gateway
        ec2.create_route(
            RouteTableId=rt_id,
            DestinationCidrBlock="0.0.0.0/0",
            GatewayId=igw_id
        )

        # Associate each subnet with the route table
        subnet_associations = []
        for sn in subnets:
            assoc_resp = ec2.associate_route_table(RouteTableId=rt_id, SubnetId=sn['subnet_id'])
            subnet_associations.append({
                "subnet_id": sn['subnet_id'],
                "association_id": assoc_resp['AssociationId']
            })

        # -------------------------------------------------------
        # 5️⃣ Persist to DynamoDB
        # -------------------------------------------------------
        table = dynamodb.Table(TABLE_NAME)
        resource_id = f"vpc-{uuid.uuid4().hex[:8]}"
        item = {
            "resource_id": resource_id,
            "vpc_id": vpc_id,
            "region": ec2.meta.region_name,
            "cidr": cidr,
            "subnets": subnets,
            "internet_gateway": {"igw_id": igw_id},
            "route_table": {
                "route_table_id": rt_id,
                "routes": [{"destination": "0.0.0.0/0", "gateway_id": igw_id}],
                "associations": subnet_associations
            },
            "tags": tags,
            "created_at": datetime.utcnow().isoformat() + "Z",
            "status": "ACTIVE"
        }

        table.put_item(Item=item)

        # -------------------------------------------------------
        # ✅ Return response
        # -------------------------------------------------------
        return {
            "statusCode": 201,
            "body": json.dumps({
                "resource_id": resource_id,
                "vpc_id": vpc_id,
                "subnets": subnets,
                "internet_gateway": igw_id,
                "route_table": rt_id
            })
        }
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

