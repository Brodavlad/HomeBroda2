#!/bin/bash

## create vpc (not default!!) (put 10.10.0.., not 10.0.0..)
VPS_ID=`aws ec2 create-vpc --cidr-block 10.10.0.0/16 --query Vpc.VpcId --output text`

## creating subnets
##public
SUBNET_PUBLIC_ID=`aws ec2 create-subnet --vpc-id $VPS_ID --cidr-block 10.10.1.0/24 --query Subnet.SubnetId --output text`
##tag subnet as public
aws ec2 create-tags --resources $SUBNET_PUBLIC_ID --tags Key=public,Value=public 
##private
SUBNET_PRIVATE_ID=`aws ec2 create-subnet --vpc-id $VPS_ID --cidr-block 10.10.2.0/24 --query Subnet.SubnetId --output text`
##tag subnet as private 
aws ec2 create-tags --resources $SUBNET_PRIVATE_ID --tags Key=private,Value=private 

## create internet gateway, to make subnet as public subnet
GATEWAY_ID=`aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text`

##attach gateway to net1
aws ec2 attach-internet-gateway --vpc-id $VPS_ID --internet-gateway-id $GATEWAY_ID 

##create custom route table
ROUTE_ID=`aws ec2 create-route-table --vpc-id $VPS_ID --query RouteTable.RouteTableId --output text`
## and update it (route table)
aws ec2 create-route --route-table-id $ROUTE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $GATEWAY_ID

## associate subnet using custom route table to make it as public 
aws ec2 associate-route-table  --subnet-id $SUBNET_PUBLIC_ID --route-table-id $ROUTE_ID

## configure subnet to give a public IP to EC2 instances
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_PUBLIC_ID --map-public-ip-on-launch

## create a key pair and output
aws ec2 create-key-pair --key-name keyBroda --query 'KeyMaterial' --output text > ./keyBroda.pem

## Modify permissions (change acces from modified keypair)
chmod 400 keyBroda.pem

#№ create security group with acces to SSH
GROUP_ID=`aws ec2 create-security-group --group-name SSHAccess --description "security group for ssh " --vpc-id $VPS_ID --query GroupId --output text`

## configure security group for tcp port 22
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

## launch instance in public subnet
INSTANCE_ID=`aws ec2 run-instances --image-id ami-0b5eea76982371e91 --count 1 --instance-type t2.micro --key-name keyBroda --security-group-ids $GROUP_ID --subnet-id $SUBNET_PUBLIC_ID --query Instances[0].InstanceId --output text`
aws ec2 modify-vpc-attribute --enable-dns-hostnames --vpc-id $VPS_ID 

## Retrieve IP address
IP_ADDRESS=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --query Reservations[].Instances[].PublicDnsName --output text`

## connect to instance with key pair and public IP
ssh -i "keyBroda.pem" ec2-user@$IP_ADDRESS

## check instance status
aws ec2 describe-instance-status --instance-id $INSTANCE_ID

sleep 40
