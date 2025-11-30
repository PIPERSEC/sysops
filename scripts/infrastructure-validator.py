#!/usr/bin/env python3
"""
Infrastructure Best Practices Validator
Validates Terraform, Ansible, and Kubernetes configurations against best practices.
"""

import os
import json
import yaml
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple

class InfrastructureValidator:
    """Validate infrastructure configurations against best practices."""

    def __init__(self):
        self.results = {
            'terraform': {'passed': [], 'failed': [], 'warnings': []},
            'ansible': {'passed': [], 'failed': [], 'warnings': []},
            'kubernetes': {'passed': [], 'failed': [], 'warnings': []},
        }

    def validate_terraform(self, path: str) -> Dict:
        """Validate Terraform configurations."""
        print(f"\n🔍 Validating Terraform in {path}...")

        tf_files = list(Path(path).rglob('*.tf'))
        if not tf_files:
            return {'status': 'skipped', 'message': 'No Terraform files found'}

        checks = []

        # Check 1: Remote state configuration
        has_backend = any('backend' in f.read_text() for f in tf_files)
        if has_backend:
            checks.append(('✅', 'Remote state backend configured'))
            self.results['terraform']['passed'].append('Remote state configured')
        else:
            checks.append(('❌', 'No remote state backend found'))
            self.results['terraform']['failed'].append('Missing remote state backend')

        # Check 2: Provider version constraints
        has_version_constraints = any('required_providers' in f.read_text() for f in tf_files)
        if has_version_constraints:
            checks.append(('✅', 'Provider versions pinned'))
            self.results['terraform']['passed'].append('Provider versions pinned')
        else:
            checks.append(('⚠️', 'Provider versions not explicitly set'))
            self.results['terraform']['warnings'].append('Pin provider versions')

        # Check 3: Resource tagging
        for tf_file in tf_files:
            content = tf_file.read_text()
            if 'resource ' in content and 'tags' not in content:
                checks.append(('⚠️', f'{tf_file.name}: Resources may be missing tags'))
                self.results['terraform']['warnings'].append(f'{tf_file.name}: Add tags')

        # Check 4: Run terraform fmt
        try:
            result = subprocess.run(
                ['terraform', 'fmt', '-check', '-recursive', path],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                checks.append(('✅', 'Terraform formatting is correct'))
                self.results['terraform']['passed'].append('Formatting correct')
            else:
                checks.append(('❌', 'Terraform needs formatting'))
                self.results['terraform']['failed'].append('Run terraform fmt')
        except FileNotFoundError:
            checks.append(('⚠️', 'Terraform not installed'))

        # Check 5: Run terraform validate
        try:
            os.chdir(path)
            result = subprocess.run(['terraform', 'validate'], capture_output=True, text=True)
            if result.returncode == 0:
                checks.append(('✅', 'Terraform configuration is valid'))
                self.results['terraform']['passed'].append('Configuration valid')
            else:
                checks.append(('❌', f'Validation failed: {result.stderr}'))
                self.results['terraform']['failed'].append('Configuration invalid')
        except Exception as e:
            checks.append(('⚠️', f'Could not validate: {str(e)}'))

        for status, message in checks:
            print(f"  {status} {message}")

        return {'status': 'completed', 'checks': checks}

    def validate_ansible(self, path: str) -> Dict:
        """Validate Ansible playbooks."""
        print(f"\n🔍 Validating Ansible in {path}...")

        playbooks = list(Path(path).rglob('*.yml')) + list(Path(path).rglob('*.yaml'))
        if not playbooks:
            return {'status': 'skipped', 'message': 'No Ansible files found'}

        checks = []

        for playbook in playbooks:
            try:
                with open(playbook) as f:
                    content = yaml.safe_load(f)

                if not content:
                    continue

                # Check for tasks with proper structure
                if isinstance(content, list):
                    for play in content:
                        if isinstance(play, dict):
                            # Check 1: Has name
                            if 'name' in play:
                                checks.append(('✅', f'{playbook.name}: Has descriptive name'))
                                self.results['ansible']['passed'].append(f'{playbook.name}: Named')
                            else:
                                checks.append(('⚠️', f'{playbook.name}: Missing name'))
                                self.results['ansible']['warnings'].append(f'{playbook.name}: Add name')

                            # Check 2: Uses become judiciously
                            if 'become' in play:
                                checks.append(('ℹ️', f'{playbook.name}: Uses privilege escalation'))

                            # Check 3: Has tasks
                            if 'tasks' in play:
                                for task in play['tasks']:
                                    if isinstance(task, dict) and 'name' not in task:
                                        checks.append(('⚠️', f'{playbook.name}: Task missing name'))
                                        self.results['ansible']['warnings'].append(f'{playbook.name}: Name all tasks')
                                        break
            except yaml.YAMLError as e:
                checks.append(('❌', f'{playbook.name}: YAML syntax error: {e}'))
                self.results['ansible']['failed'].append(f'{playbook.name}: YAML error')
            except Exception as e:
                checks.append(('⚠️', f'{playbook.name}: Could not parse: {e}'))

        # Check for ansible-lint
        try:
            result = subprocess.run(['ansible-lint', '--version'], capture_output=True)
            if result.returncode == 0:
                checks.append(('✅', 'ansible-lint is available'))
                self.results['ansible']['passed'].append('ansible-lint available')
        except FileNotFoundError:
            checks.append(('⚠️', 'ansible-lint not installed - install for better validation'))
            self.results['ansible']['warnings'].append('Install ansible-lint')

        for status, message in checks:
            print(f"  {status} {message}")

        return {'status': 'completed', 'checks': checks}

    def validate_kubernetes(self, path: str) -> Dict:
        """Validate Kubernetes manifests."""
        print(f"\n🔍 Validating Kubernetes manifests in {path}...")

        manifests = list(Path(path).rglob('*.yaml')) + list(Path(path).rglob('*.yml'))
        if not manifests:
            return {'status': 'skipped', 'message': 'No Kubernetes manifests found'}

        checks = []

        for manifest in manifests:
            try:
                with open(manifest) as f:
                    docs = yaml.safe_load_all(f)

                    for doc in docs:
                        if not doc or 'kind' not in doc:
                            continue

                        kind = doc.get('kind')
                        name = doc.get('metadata', {}).get('name', 'unnamed')

                        # Check 1: Has resource limits (for Deployments/StatefulSets)
                        if kind in ['Deployment', 'StatefulSet', 'DaemonSet']:
                            spec = doc.get('spec', {}).get('template', {}).get('spec', {})
                            containers = spec.get('containers', [])

                            has_limits = all(
                                'resources' in c and 'limits' in c.get('resources', {})
                                for c in containers
                            )

                            if has_limits:
                                checks.append(('✅', f'{manifest.name}: {kind}/{name} has resource limits'))
                                self.results['kubernetes']['passed'].append(f'{manifest.name}: Resource limits')
                            else:
                                checks.append(('❌', f'{manifest.name}: {kind}/{name} missing resource limits'))
                                self.results['kubernetes']['failed'].append(f'{manifest.name}: Add resource limits')

                            # Check 2: Health checks
                            has_health_checks = all(
                                'livenessProbe' in c or 'readinessProbe' in c
                                for c in containers
                            )

                            if has_health_checks:
                                checks.append(('✅', f'{manifest.name}: {kind}/{name} has health checks'))
                                self.results['kubernetes']['passed'].append(f'{manifest.name}: Health checks')
                            else:
                                checks.append(('⚠️', f'{manifest.name}: {kind}/{name} missing health checks'))
                                self.results['kubernetes']['warnings'].append(f'{manifest.name}: Add health checks')

                            # Check 3: Security context
                            has_security_context = any(
                                'securityContext' in c
                                for c in containers
                            )

                            if has_security_context:
                                checks.append(('✅', f'{manifest.name}: {kind}/{name} has security context'))
                                self.results['kubernetes']['passed'].append(f'{manifest.name}: Security context')
                            else:
                                checks.append(('⚠️', f'{manifest.name}: {kind}/{name} missing security context'))
                                self.results['kubernetes']['warnings'].append(f'{manifest.name}: Add security context')

            except yaml.YAMLError as e:
                checks.append(('❌', f'{manifest.name}: YAML syntax error'))
                self.results['kubernetes']['failed'].append(f'{manifest.name}: YAML error')
            except Exception as e:
                checks.append(('⚠️', f'{manifest.name}: Could not parse: {e}'))

        for status, message in checks:
            print(f"  {status} {message}")

        return {'status': 'completed', 'checks': checks}

    def generate_report(self) -> str:
        """Generate a summary report."""
        report = ["\n" + "="*60]
        report.append("Infrastructure Validation Report")
        report.append("="*60)

        for category, results in self.results.items():
            total = len(results['passed']) + len(results['failed']) + len(results['warnings'])
            if total == 0:
                continue

            report.append(f"\n{category.upper()}:")
            report.append(f"  ✅ Passed: {len(results['passed'])}")
            report.append(f"  ❌ Failed: {len(results['failed'])}")
            report.append(f"  ⚠️  Warnings: {len(results['warnings'])}")

            if results['failed']:
                report.append(f"\n  Critical Issues:")
                for issue in results['failed']:
                    report.append(f"    - {issue}")

            if results['warnings']:
                report.append(f"\n  Warnings:")
                for warning in results['warnings'][:5]:  # Limit to 5
                    report.append(f"    - {warning}")

        report.append("\n" + "="*60)
        return "\n".join(report)


def main():
    """Main execution."""
    import argparse

    parser = argparse.ArgumentParser(description='Validate infrastructure configurations')
    parser.add_argument('--terraform-path', default='projects', help='Path to Terraform files')
    parser.add_argument('--ansible-path', default='projects', help='Path to Ansible files')
    parser.add_argument('--k8s-path', default='projects', help='Path to Kubernetes manifests')
    parser.add_argument('--json-output', help='Output results as JSON to file')

    args = parser.parse_args()

    validator = InfrastructureValidator()

    # Run validations
    validator.validate_terraform(args.terraform_path)
    validator.validate_ansible(args.ansible_path)
    validator.validate_kubernetes(args.k8s_path)

    # Print report
    print(validator.generate_report())

    # JSON output if requested
    if args.json_output:
        with open(args.json_output, 'w') as f:
            json.dump(validator.results, f, indent=2)
        print(f"\n📄 Detailed results saved to {args.json_output}")

    # Exit code based on failures
    total_failures = sum(len(r['failed']) for r in validator.results.values())
    sys.exit(1 if total_failures > 0 else 0)


if __name__ == '__main__':
    main()
