# Few-Shot Example: Python System Script

## Example: AWS Resource Inventory Script

### Input
"Create a Python script to inventory AWS resources across regions"

### Output

**File: `scripts/aws-inventory.py`**
```python
#!/usr/bin/env python3
"""
AWS Resource Inventory Script

Collects inventory of AWS resources across all regions and exports to JSON/CSV.
"""

import argparse
import json
import csv
import sys
from typing import List, Dict, Any
from datetime import datetime
import boto3
from botocore.exceptions import ClientError, NoCredentialsError


class AWSInventory:
    """Collect AWS resource inventory across regions."""

    def __init__(self, profile: str = None, regions: List[str] = None):
        """
        Initialize AWS inventory collector.

        Args:
            profile: AWS profile name
            regions: List of regions to scan (defaults to all)
        """
        self.session = boto3.Session(profile_name=profile) if profile else boto3.Session()
        self.regions = regions or self._get_all_regions()
        self.inventory = []

    def _get_all_regions(self) -> List[str]:
        """Get list of all AWS regions."""
        ec2 = self.session.client('ec2', region_name='us-east-1')
        try:
            response = ec2.describe_regions()
            return [region['RegionName'] for region in response['Regions']]
        except ClientError as e:
            print(f"Error getting regions: {e}", file=sys.stderr)
            return ['us-east-1']  # Fallback to default region

    def collect_ec2_instances(self, region: str) -> List[Dict[str, Any]]:
        """
        Collect EC2 instance inventory for a region.

        Args:
            region: AWS region name

        Returns:
            List of EC2 instance details
        """
        ec2 = self.session.client('ec2', region_name=region)
        instances = []

        try:
            response = ec2.describe_instances()
            for reservation in response['Reservations']:
                for instance in reservation['Instances']:
                    # Extract name from tags
                    name = next(
                        (tag['Value'] for tag in instance.get('Tags', [])
                         if tag['Key'] == 'Name'),
                        'N/A'
                    )

                    instances.append({
                        'service': 'EC2',
                        'region': region,
                        'id': instance['InstanceId'],
                        'name': name,
                        'type': instance['InstanceType'],
                        'state': instance['State']['Name'],
                        'private_ip': instance.get('PrivateIpAddress', 'N/A'),
                        'public_ip': instance.get('PublicIpAddress', 'N/A'),
                        'launch_time': instance['LaunchTime'].isoformat(),
                    })
        except ClientError as e:
            print(f"Error collecting EC2 instances in {region}: {e}", file=sys.stderr)

        return instances

    def collect_s3_buckets(self) -> List[Dict[str, Any]]:
        """
        Collect S3 bucket inventory.

        Returns:
            List of S3 bucket details
        """
        s3 = self.session.client('s3')
        buckets = []

        try:
            response = s3.list_buckets()
            for bucket in response['Buckets']:
                bucket_name = bucket['Name']

                # Get bucket region
                try:
                    location = s3.get_bucket_location(Bucket=bucket_name)
                    region = location['LocationConstraint'] or 'us-east-1'
                except ClientError:
                    region = 'unknown'

                buckets.append({
                    'service': 'S3',
                    'region': region,
                    'id': bucket_name,
                    'name': bucket_name,
                    'creation_date': bucket['CreationDate'].isoformat(),
                })
        except ClientError as e:
            print(f"Error collecting S3 buckets: {e}", file=sys.stderr)

        return buckets

    def collect_rds_instances(self, region: str) -> List[Dict[str, Any]]:
        """
        Collect RDS instance inventory for a region.

        Args:
            region: AWS region name

        Returns:
            List of RDS instance details
        """
        rds = self.session.client('rds', region_name=region)
        instances = []

        try:
            response = rds.describe_db_instances()
            for db in response['DBInstances']:
                instances.append({
                    'service': 'RDS',
                    'region': region,
                    'id': db['DBInstanceIdentifier'],
                    'name': db['DBInstanceIdentifier'],
                    'engine': db['Engine'],
                    'engine_version': db['EngineVersion'],
                    'instance_class': db['DBInstanceClass'],
                    'status': db['DBInstanceStatus'],
                    'storage': db['AllocatedStorage'],
                })
        except ClientError as e:
            print(f"Error collecting RDS instances in {region}: {e}", file=sys.stderr)

        return instances

    def collect_all(self) -> List[Dict[str, Any]]:
        """
        Collect inventory for all resources across all regions.

        Returns:
            Complete inventory list
        """
        print("Collecting AWS resource inventory...")

        # S3 buckets (global)
        print("Collecting S3 buckets...")
        self.inventory.extend(self.collect_s3_buckets())

        # Regional resources
        for region in self.regions:
            print(f"Scanning region: {region}")

            # EC2 instances
            self.inventory.extend(self.collect_ec2_instances(region))

            # RDS instances
            self.inventory.extend(self.collect_rds_instances(region))

        print(f"Collected {len(self.inventory)} resources")
        return self.inventory

    def export_json(self, filename: str):
        """Export inventory to JSON file."""
        with open(filename, 'w') as f:
            json.dump(self.inventory, f, indent=2, default=str)
        print(f"Exported inventory to {filename}")

    def export_csv(self, filename: str):
        """Export inventory to CSV file."""
        if not self.inventory:
            print("No inventory data to export")
            return

        keys = self.inventory[0].keys()
        with open(filename, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=keys)
            writer.writeheader()
            writer.writerows(self.inventory)
        print(f"Exported inventory to {filename}")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Collect AWS resource inventory'
    )
    parser.add_argument(
        '--profile',
        help='AWS profile name',
        default=None
    )
    parser.add_argument(
        '--regions',
        help='Comma-separated list of regions (default: all)',
        default=None
    )
    parser.add_argument(
        '--output',
        help='Output file path',
        default=f'aws-inventory-{datetime.now().strftime("%Y%m%d-%H%M%S")}'
    )
    parser.add_argument(
        '--format',
        help='Output format',
        choices=['json', 'csv', 'both'],
        default='json'
    )

    args = parser.parse_args()

    # Parse regions
    regions = args.regions.split(',') if args.regions else None

    try:
        # Collect inventory
        inventory = AWSInventory(profile=args.profile, regions=regions)
        inventory.collect_all()

        # Export based on format
        if args.format in ['json', 'both']:
            inventory.export_json(f"{args.output}.json")
        if args.format in ['csv', 'both']:
            inventory.export_csv(f"{args.output}.csv")

    except NoCredentialsError:
        print("Error: AWS credentials not found", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
```

**Usage Examples:**
```bash
# Default usage (all regions, JSON output)
python scripts/aws-inventory.py

# Specific profile and regions
python scripts/aws-inventory.py --profile production --regions us-east-1,us-west-2

# CSV output
python scripts/aws-inventory.py --format csv --output inventory

# Both JSON and CSV
python scripts/aws-inventory.py --format both
```

**Requirements file: `requirements.txt`**
```
boto3>=1.26.0
botocore>=1.29.0
```
