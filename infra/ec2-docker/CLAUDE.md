# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Terraform-based infrastructure automation project** that deploys a Docker-enabled EC2 instance on AWS. It demonstrates production-ready practices including remote state management, IAM least privilege, and comprehensive automation.

**Architecture**: Single EC2 instance (t3.large, Amazon Linux 2023) running a Docker container via systemd service, with remote state storage in S3, DynamoDB state locking, and Secrets Manager for credentials.

**Cost**: ~$64/month running, ~$3.30/month when stopped (use `make stop` to save costs).

## Essential Commands

### Core Workflow
```bash
# Initial Setup
make aws-login          # Authenticate to AWS via SSO
make init               # Initialize Terraform (required first)
make validate           # Validate configuration syntax

# Deployment
make plan               # Preview infrastructure changes (always run before apply)
make apply              # Deploy infrastructure (~5-10 minutes)
make health             # Verify application is responding

# Instance Access
make ssh                # SSH into EC2 instance
make logs               # Stream Docker container logs in real-time
make status             # Check systemd service and container status

# Lifecycle Management
make destroy-app        # Safe destroy (keeps backend/state)
make stop               # Suspend instance (save ~95% costs)
make start              # Resume stopped instance
```

### Backend & State
```bash
make backend-status     # Show S3 bucket and state file location
make state-list         # List all managed resources
make state-versions     # View state file version history in S3
```

### Maintenance
```bash
make update-container VERSION=x.x.x  # Update Docker image
make restart                         # Restart myapp1 service
make docker-secret-setup             # Store Docker Hub token in Secrets Manager
make get-my-ip                       # Get your public IP for security group rules
```

### Composite Commands
```bash
make quick-deploy      # init → validate → apply (one command)
make full-cycle        # clean → init → validate → plan → apply → health
```

## Architecture Patterns

### Terraform Module Organization

**locals.tf** - Single source of truth for configuration:
```hcl
container_image = "stacksimplify/retail-store-sample-ui:1.0.0"
container_port  = 8888
service_name    = "myapp1"
common_tags     = { Project = "...", Environment = "dev", ... }
```

**variables.tf** - Input validation patterns:
- AWS region: `^[a-z]{2}-[a-z]+-[0-9]{1}$` (e.g., us-east-1)
- VPC ID: `^vpc-[a-z0-9]{8,}$`
- Subnet ID: `^subnet-[a-z0-9]{8,}$`
- CIDR: `can(cidrhost(var.ssh_cidr, 0))` validates proper notation

**Tag Merging Pattern** (used across all resources):
```hcl
tags = merge(
  local.common_tags,
  { Name = local.instance_name }
)
```

### Remote Backend (S3 + DynamoDB)

**State Location**:
- S3 Bucket: `terraform-state-{ACCOUNT_ID}-{REGION}` (account-specific isolation)
- State Path: `infra/ec2-docker/terraform.tfstate` (monorepo-friendly)
- DynamoDB Table: `terraform-state-locks-ec2-docker` (prevents concurrent modifications)

**Critical**: `backend-resources.tf` has `prevent_destroy = true` on S3/DynamoDB. To fully destroy infrastructure, see `DESTROY-RECREATE-GUIDE.md`.

### IAM Least Privilege Pattern

```hcl
# ec2_role: Assume role from EC2 service
# secrets_manager_policy: Read-only access to SINGLE secret ARN
Actions: ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
Resource: aws_secretsmanager_secret.dockerhub_token.arn  # Not wildcard
```

### Template-Driven User Data

**ec2.tf**:
```hcl
user_data = templatefile("${path.module}/user-data.sh", {
  service_name    = local.service_name
  container_image = local.container_image
  container_port  = local.container_port
})
```

**user-data.sh**: Creates systemd service with auto-restart, pulls Docker image, runs health check loop.

### Dynamic Security Groups

```hcl
dynamic "ingress" {
  for_each = var.allow_all_tcp ? [1] : []
  content { ... }  # Opens all TCP ports for lab mode
}
```

Set `allow_all_tcp = false` in production to restrict to specific ports only.

## Critical Files & Patterns

**terraform.tfvars** (never committed, in .gitignore):
- Contains actual VPC ID, subnet ID, key name
- Use `terraform.tfvars.example` as template
- Required variables: `vpc_id`, `subnet_id`, `key_name`

**user-data.sh**:
- Templated with `locals` values (container_image, service_name, container_port)
- Creates systemd service: `/etc/systemd/system/myapp1.service`
- Restart policy: `Restart=always`, `RestartSec=10`
- Health check: 30 attempts, 2-second intervals, exits with code 1 on failure

**secrets.tf**:
```hcl
lifecycle {
  ignore_changes = [secret_string]  # Manual management after creation
}
```
Prevents Terraform from overwriting manually updated secrets.

## Operational Guidance

### Destroy/Recreate Options

**Option 1 (Recommended): Partial Destroy**
```bash
make destroy-app    # Destroys EC2, SG, IAM, Secrets; keeps backend
make apply          # Recreates everything
```
Backend (S3/DynamoDB) is preserved, so no state history is lost.

**Option 2: Full Destroy**
Requires handling `prevent_destroy` lifecycle. See `DESTROY-RECREATE-GUIDE.md` for complete procedure.

### Security Best Practices

**SSH Access**:
```bash
make get-my-ip     # Returns your public IP
# Update terraform.tfvars:
ssh_cidr = "203.0.113.5/32"  # Replace with your IP from get-my-ip
```

Default `ssh_cidr = "0.0.0.0/0"` is insecure - restrict to your IP/32 for production.

**Secrets Management**:
- Docker Hub token stored in AWS Secrets Manager (not in code)
- Use `make docker-secret-setup` to configure
- Token retrieved by EC2 via IAM role (no credentials in user-data)

### Cost Optimization

```bash
# When not actively using:
make stop          # Reduces cost to ~$3.30/month (EBS + Secrets + Backend only)

# To resume:
make start         # Takes ~1 minute to become available
make health        # Verify application is back online
```

### Troubleshooting

**"Backend configuration changed" error**:
```bash
terraform init -reconfigure
```

**SSH connection fails**:
```bash
make info          # Check instance is running
make sg-rules      # Verify your IP is allowed
```

**Application not responding**:
```bash
make status        # Check systemd service status
make logs          # View container logs
make restart       # Restart service
```

**State file conflicts**:
DynamoDB provides automatic locking. If lock is stuck:
```bash
# Check lock status
make backend-status

# Force unlock (use carefully)
terraform force-unlock LOCK_ID
```

## Development Notes

**Systemd Service Pattern**:
- Service name: `myapp1` (from locals.tf)
- Restart: Always, 10-second delay between attempts
- Docker command: `--restart unless-stopped` (persists across Docker daemon restarts)
- Logs: `make logs` (equivalent to `docker logs -f myapp1`)

**Variable Validation Examples**:
If adding new variables, follow existing patterns:
```hcl
validation {
  condition     = can(regex("^vpc-[a-z0-9]{8,}$", var.vpc_id))
  error_message = "VPC ID must start with 'vpc-' followed by alphanumeric characters."
}
```

**Backend State Path Convention**:
Format: `{parent_dir}/{module_name}/terraform.tfstate`
Current: `infra/ec2-docker/terraform.tfstate`
Enables multiple modules in same S3 bucket.

## Additional Resources

- **README.md**: Comprehensive project documentation with architecture diagrams
- **DESTROY-RECREATE-GUIDE.md**: Full procedures for infrastructure lifecycle management
- **terraform.tfvars.example**: Template with all configurable variables
- **Makefile**: Run `make help` to see all 40+ available commands
