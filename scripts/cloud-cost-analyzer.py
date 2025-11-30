#!/usr/bin/env python3
"""
Cloud Cost Analyzer
Analyzes AWS resources for cost optimization opportunities.
"""

import boto3
import json
from datetime import datetime, timedelta
from collections import defaultdict

class CloudCostAnalyzer:
    """Analyze cloud resources for cost optimization."""

    def __init__(self, region='us-east-1'):
        self.ec2 = boto3.client('ec2', region_name=region)
        self.rds = boto3.client('rds', region_name=region)
        self.elb = boto3.client('elbv2', region_name=region)
        self.cloudwatch = boto3.client('cloudwatch', region_name=region)
        self.region = region
        self.findings = []

    def analyze_ec2_instances(self):
        """Analyze EC2 instances for optimization."""
        print("🔍 Analyzing EC2 Instances...")

        try:
            instances = self.ec2.describe_instances()

            for reservation in instances['Reservations']:
                for instance in reservation['Instances']:
                    instance_id = instance['InstanceId']
                    instance_type = instance['InstanceType']
                    state = instance['State']['Name']

                    # Check for stopped instances
                    if state == 'stopped':
                        self.findings.append({
                            'resource': instance_id,
                            'type': 'EC2',
                            'issue': 'Stopped instance still incurring EBS costs',
                            'recommendation': 'Terminate if not needed or create AMI and terminate',
                            'potential_savings': 'Low'
                        })

                    # Check for old generation instances
                    if instance_type.startswith(('t2', 'm4', 'c4')):
                        new_gen = instance_type.replace('t2', 't3').replace('m4', 'm5').replace('c4', 'c5')
                        self.findings.append({
                            'resource': instance_id,
                            'type': 'EC2',
                            'issue': f'Old generation instance type: {instance_type}',
                            'recommendation': f'Upgrade to {new_gen} for better price/performance',
                            'potential_savings': 'Medium'
                        })

                    # Check CPU utilization
                    if state == 'running':
                        avg_cpu = self.get_average_cpu(instance_id)
                        if avg_cpu is not None and avg_cpu < 10:
                            self.findings.append({
                                'resource': instance_id,
                                'type': 'EC2',
                                'issue': f'Low CPU utilization: {avg_cpu:.1f}%',
                                'recommendation': 'Consider downsizing or terminating',
                                'potential_savings': 'High'
                            })

        except Exception as e:
            print(f"❌ Error analyzing EC2: {e}")

    def get_average_cpu(self, instance_id):
        """Get average CPU utilization for last 7 days."""
        try:
            response = self.cloudwatch.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='CPUUtilization',
                Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
                StartTime=datetime.utcnow() - timedelta(days=7),
                EndTime=datetime.utcnow(),
                Period=86400,  # 1 day
                Statistics=['Average']
            )

            if response['Datapoints']:
                return sum(d['Average'] for d in response['Datapoints']) / len(response['Datapoints'])
            return None
        except:
            return None

    def analyze_ebs_volumes(self):
        """Analyze EBS volumes for optimization."""
        print("🔍 Analyzing EBS Volumes...")

        try:
            volumes = self.ec2.describe_volumes()

            for volume in volumes['Volumes']:
                volume_id = volume['VolumeId']
                volume_type = volume['VolumeType']
                size = volume['Size']
                state = volume['State']

                # Check for unattached volumes
                if state == 'available':
                    self.findings.append({
                        'resource': volume_id,
                        'type': 'EBS',
                        'issue': f'Unattached {size}GB volume',
                        'recommendation': 'Delete if not needed (create snapshot first)',
                        'potential_savings': f'~${size * 0.10}/month'
                    })

                # Check for old volume types
                if volume_type in ['standard', 'io1']:
                    new_type = 'gp3' if volume_type == 'standard' else 'io2'
                    self.findings.append({
                        'resource': volume_id,
                        'type': 'EBS',
                        'issue': f'Old volume type: {volume_type}',
                        'recommendation': f'Migrate to {new_type} for better cost/performance',
                        'potential_savings': 'Low-Medium'
                    })

        except Exception as e:
            print(f"❌ Error analyzing EBS: {e}")

    def analyze_snapshots(self):
        """Analyze EBS snapshots for old/unused snapshots."""
        print("🔍 Analyzing EBS Snapshots...")

        try:
            snapshots = self.ec2.describe_snapshots(OwnerIds=['self'])

            old_threshold = datetime.now() - timedelta(days=90)

            for snapshot in snapshots['Snapshots']:
                snapshot_id = snapshot['SnapshotId']
                start_time = snapshot['StartTime'].replace(tzinfo=None)
                size = snapshot['VolumeSize']

                if start_time < old_threshold:
                    self.findings.append({
                        'resource': snapshot_id,
                        'type': 'Snapshot',
                        'issue': f'Snapshot older than 90 days ({size}GB)',
                        'recommendation': 'Review if still needed, delete if not',
                        'potential_savings': f'~${size * 0.05}/month'
                    })

        except Exception as e:
            print(f"❌ Error analyzing snapshots: {e}")

    def analyze_elastic_ips(self):
        """Analyze Elastic IPs for unassociated IPs."""
        print("🔍 Analyzing Elastic IPs...")

        try:
            eips = self.ec2.describe_addresses()

            for eip in eips['Addresses']:
                if 'AssociationId' not in eip:
                    self.findings.append({
                        'resource': eip.get('PublicIp', 'Unknown'),
                        'type': 'EIP',
                        'issue': 'Unassociated Elastic IP',
                        'recommendation': 'Release if not needed',
                        'potential_savings': '~$3.60/month'
                    })

        except Exception as e:
            print(f"❌ Error analyzing Elastic IPs: {e}")

    def generate_report(self):
        """Generate cost optimization report."""
        if not self.findings:
            print("\n✅ No cost optimization opportunities found!")
            return

        print("\n" + "="*80)
        print("Cloud Cost Optimization Report")
        print("="*80)

        # Group by resource type
        by_type = defaultdict(list)
        for finding in self.findings:
            by_type[finding['type']].append(finding)

        for resource_type, findings in by_type.items():
            print(f"\n{resource_type} ({len(findings)} findings):")
            print("-" * 80)

            for i, finding in enumerate(findings, 1):
                print(f"\n  {i}. Resource: {finding['resource']}")
                print(f"     Issue: {finding['issue']}")
                print(f"     Recommendation: {finding['recommendation']}")
                print(f"     Potential Savings: {finding['potential_savings']}")

        print("\n" + "="*80)
        print(f"Total Findings: {len(self.findings)}")
        print("="*80)

    def export_json(self, filename='cost-analysis.json'):
        """Export findings to JSON."""
        with open(filename, 'w') as f:
            json.dump({
                'analysis_date': datetime.now().isoformat(),
                'region': self.region,
                'total_findings': len(self.findings),
                'findings': self.findings
            }, f, indent=2)
        print(f"\n📄 Report exported to {filename}")


def main():
    """Main execution."""
    import argparse

    parser = argparse.ArgumentParser(description='Analyze AWS costs and find optimization opportunities')
    parser.add_argument('--region', default='us-east-1', help='AWS region')
    parser.add_argument('--export', help='Export to JSON file')

    args = parser.parse_args()

    print("AWS Cloud Cost Analyzer")
    print("="*80)

    analyzer = CloudCostAnalyzer(region=args.region)

    # Run all analyses
    analyzer.analyze_ec2_instances()
    analyzer.analyze_ebs_volumes()
    analyzer.analyze_snapshots()
    analyzer.analyze_elastic_ips()

    # Generate report
    analyzer.generate_report()

    # Export if requested
    if args.export:
        analyzer.export_json(args.export)


if __name__ == '__main__':
    main()
