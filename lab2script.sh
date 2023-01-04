#!/bin/bash

## create vpc (not default!!) (put 10.0.0.., not 10.10.0..)
aws ec2 create-vpc --cidr-block 10.0.0.0/16

## creating subnets
##public
aws ec2 create-subnet --vpc-id vpc-00a67537573b9bd10 --cidr-block 10.0.1.0/24
aws ec2 create-tags --resources subnet-01a1d5bd8ff785c90 --tags Key=public,Value=public
##private
aws ec2 create-subnet --vpc-id vpc-00a67537573b9bd10 --cidr-block 10.0.2.0/24
aws ec2 create-tags --resources subnet-04b09689bbb7d5f0a --tags Key=private,Value=private

##internet gateway
aws ec2 create-internet-gateway

##attach gateway to net1
aws ec2 attach-internet-gateway --internet-gateway-id igw-0f7b76eedde6cfc73 --vpc-id vpc-065ce59e9d41ce119

##create ellastic ip
aws ec2 allocate-address --domain vpc
##connecting nat to elastic ip
aws ec2 create-nat-gateway --subnet-id subnet-01a1d5bd8ff785c90 --allocation-id eipalloc-097b1ba265e0afdce

##create route table
aws ec2 create-route-table --vpc-id vpc-00a67537573b9bd10

##tag the first route table as public
aws ec2 create-tags --resources rtb-0c367934250368a2b --tags Key=public,Value=public

##creating a routes for routes table
aws ec2 create-route --route-table-id rtb-0c367934250368a2b --destination-cidr-block 0.0.0.0/0 --gateway-id igw-0481d6693b68a26ea

##associate route table to subnet
aws ec2 associate-route-table --route-table-id rtb-0c367934250368a2b --subnet-id subnet-01a1d5bd8ff785c90


##create key pair
aws ec2 create-key-pair --key-name cli-keyPair --query 'KeyMaterial' --output text > cli-keyPair.pem

##create ec2 instance
