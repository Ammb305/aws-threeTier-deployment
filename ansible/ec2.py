#!/usr/bin/env python3

import boto3
import json
import sys

# Replace these with your actual target group ARNs
presentation_target_group_arn = 'arn:aws:elasticloadbalancing:us-east-1:339713176242:targetgroup/tf-lb-tg/c00fe3a111e0fdce'
application_target_group_arn = 'arn:aws:elasticloadbalancing:us-east-1:339713176242:targetgroup/application-tg/6e4ddcbb35247c0a'
def get_instances_from_target_group(target_group_arn):
    elbv2 = boto3.client('elbv2')
    try:
        response = elbv2.describe_target_health(TargetGroupArn=target_group_arn)
        instances = [target['Target']['Id'] for target in response['TargetHealthDescriptions']]
        return instances
    except Exception as e:
        print(f"Error retrieving target health for {target_group_arn}: {e}", file=sys.stderr)
        return []

def get_instance_ips(ec2, instance_ids, public=False):
    if not instance_ids:
        return []

    try:
        instances_info = ec2.describe_instances(InstanceIds=instance_ids)
        ips = []
        for reservation in instances_info['Reservations']:
            for instance in reservation['Instances']:
                if public:
                    ip = instance.get('PublicIpAddress')
                else:
                    ip = instance.get('PrivateIpAddress')

                if ip:
                    ips.append(ip)
        return ips
    except Exception as e:
        print(f"Error retrieving instance IPs: {e}", file=sys.stderr)
        return []

def main():
    # Initialize a session using your AWS credentials
    session = boto3.Session()
    ec2 = session.client('ec2')

    # Get instances from the Presentation Target Group
    presentation_instances = get_instances_from_target_group(presentation_target_group_arn)
    # Get instances from the Application Target Group
    application_instances = get_instances_from_target_group(application_target_group_arn)

    # Retrieve public IP addresses for each instance ID
    presentation_ips = get_instance_ips(ec2, presentation_instances, public=True)
    application_ips = get_instance_ips(ec2, application_instances, public=False)  # Change to True if needed

    # Construct the inventory
    inventory = {
        'presentation': {
            'hosts': presentation_ips,
            'vars': {
                'ansible_ssh_private_key_file': './three-tier.pem',  # Update this path
            }
        },
        'application': {
            'hosts': application_ips,
            'vars': {
                'ansible_ssh_private_key_file': './three-tier.pem',  # Update this path
            }
        }
    }

    print(json.dumps(inventory, indent=4))

if __name__ == '__main__':
    main()