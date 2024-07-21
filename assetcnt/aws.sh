#!/bin/bash
defregion="us-east-2"
regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text --region "$defregion")
sum_count=0
for region in $regions; do
	countec2=$(aws ec2 describe-instances --region "$region" --output text --query 'length(Reservations[].Instances[])')
	echo "Ec2 instances in Region: $region is $countec2"
	countebs=$(aws ec2 describe-volumes --region "$region" --query 'length(Volumes[])')
	echo "Elastic Block Storage in Region: $region is $countebs"
	countvpc=$(aws ec2 describe-vpcs --region "$region" --query 'length(Vpcs[])')
	echo "VPC in Region: $region is $countvpc"
	countrds=$(aws rds describe-db-instances --region "$region" --query 'length(DBInstances[])')
	echo "RDS in Region: $region is $countrds"
	countlamb=$(aws lambda list-functions --region "$region" --query 'length(Functions[])')
	echo "Lambda Functions in Region: $region is $countlamb"
	countelb=$(aws elbv2 describe-load-balancers --region "$region" --query 'length(LoadBalancers[])')
	echo -e "Elastic load Balancers in Region: $region is $countelb\n\n"
	sum_count=$((sum_count + countec2 + countebs + countvpc + countrds + countlamb + countelb))
done
counts3=$(aws s3api list-buckets --region $defregion --query 'length(Buckets[])')
echo -e "s3 buckets in the account is $counts3\n\n"
total_count=$((sum_count + counts3 + countiam))
echo "Total Assets in this AWS account is : $total_count"
