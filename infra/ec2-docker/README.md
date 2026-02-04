# DevOps EC2 Docker Lab

Infrastructure as Code (IaC) project using Terraform to provision an EC2 instance running Docker containers on AWS.

## 📋 Prerequisites

- Terraform >= 1.6
- AWS CLI configured with SSO profile
- SSH key pair for EC2 access
- Docker Hub account (optional, for private images)

## 🏗️ Infrastructure

This project provisions:

- **EC2 Instance**: t3.large with Amazon Linux 2023
- **EBS Volume**: 30GB gp3 storage
- **Security Group**: SSH (22), HTTP (8888), and configurable ports
- **AWS Secrets Manager**: Docker Hub token storage
- **Systemd Service**: Auto-restart Docker container

### Architecture

```
┌─────────────────────────────────────────┐
│           AWS Account                    │
│  ┌────────────────────────────────────┐ │
│  │         VPC                         │ │
│  │  ┌──────────────────────────────┐  │ │
│  │  │  Security Group              │  │ │
│  │  │  - SSH: 22                   │  │ │
│  │  │  - HTTP: 8888                │  │ │
│  │  └──────────────────────────────┘  │ │
│  │  ┌──────────────────────────────┐  │ │
│  │  │  EC2 Instance (t3.large)     │  │ │
│  │  │  ┌────────────────────────┐  │  │ │
│  │  │  │ Docker Engine          │  │  │ │
│  │  │  │  └─ Container (myapp1) │  │  │ │
│  │  │  │     Port: 8888         │  │  │ │
│  │  │  └────────────────────────┘  │  │ │
│  │  └──────────────────────────────┘  │ │
│  └────────────────────────────────────┘ │
│  ┌────────────────────────────────────┐ │
│  │  AWS Secrets Manager               │ │
│  │  └─ Docker Hub Token               │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## 🗄️ Remote Backend (S3 + DynamoDB)

This project uses **remote state management** for production-ready infrastructure:

### Benefits
- ✅ **Team Collaboration**: Centralized state accessible to entire team
- ✅ **State Locking**: Prevents concurrent modifications (DynamoDB)
- ✅ **Versioning**: Full history of state changes in S3
- ✅ **Security**: Encrypted state at rest (AES-256)
- ✅ **Disaster Recovery**: Automatic backup via S3 versioning

### Backend Configuration
- **S3 Bucket**: `terraform-state-<ACCOUNT_ID>-<REGION>`
- **DynamoDB Table**: `terraform-state-locks-ec2-docker`
- **State Path**: `infra/ec2-docker/terraform.tfstate`
- **Encryption**: Server-side (SSE-S3)

### Backend Management Commands
```bash
# View backend status
make backend-status

# List all resources in state
make state-list

# View state file versions
make state-versions
```

### First-Time Setup
The backend is automatically created when you run `make apply`. The state migration happens transparently on first `terraform init`.

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Clone and navigate to project
cd infra/ec2-docker

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
make init

# Review plan
make plan

# Apply changes
make apply

# Verify deployment
make health
```

### 3. Access Application

```bash
# Get public IP
make output

# Open in browser
make open

# Or SSH into instance
make ssh
```

## 📚 Available Commands

View all available commands:
```bash
make help
```

### Common Commands

| Command | Description |
|---------|-------------|
| `make init` | Initialize Terraform |
| `make plan` | Show infrastructure changes |
| `make apply` | Apply infrastructure changes |
| `make destroy` | Destroy all infrastructure |
| `make ssh` | SSH into EC2 instance |
| `make logs` | View container logs |
| `make status` | Check service status |
| `make health` | Check application health |
| `make stop` | Stop EC2 instance (save costs) |
| `make start` | Start stopped instance |

### AWS & Docker Commands

| Command | Description |
|---------|-------------|
| `make aws-login` | Login to AWS via SSO |
| `make aws-whoami` | Show current AWS identity |
| `make docker-login` | Login to Docker Hub |
| `make docker-secret-setup` | Store Docker Hub token in AWS |

### Monitoring Commands

| Command | Description |
|---------|-------------|
| `make stats` | Show CPU, memory, disk usage |
| `make disk-usage` | Detailed disk usage |
| `make info` | Instance information |
| `make sg-rules` | Security group rules |
| `make cost-estimate` | Estimate monthly costs |

### Backend Management

| Command | Description |
|---------|-------------|
| `make backend-status` | Show backend configuration and state |
| `make state-list` | List all resources in Terraform state |
| `make state-versions` | List state file versions in S3 |

## 📁 Project Structure

```
.
├── Makefile                  # Automation commands
├── README.md                 # This file
├── .gitignore               # Git ignore rules
├── terraform.tfvars.example # Example configuration
├── providers.tf             # Terraform & AWS provider config
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── ami.tf                   # AMI data source
├── keypar.tf                # SSH key pair
├── security_group.tf        # Security group rules
├── ec2.tf                   # EC2 instance
└── secrets.tf               # AWS Secrets Manager
```

## ⚙️ Configuration

### Required Variables

Edit `terraform.tfvars` with your values:

```hcl
aws_region  = "us-east-1"
aws_profile = "your-sso-profile"
key_name    = "your-key-pair-name"
vpc_id      = "vpc-xxxxx"
subnet_id   = "subnet-xxxxx"
```

### Optional Variables

```hcl
allow_all_tcp = false  # Only allow specific ports
ssh_cidr      = "YOUR_IP/32"  # Restrict SSH to your IP
```

## 💰 Cost Estimate

Monthly costs (US East 1):

- **EC2 t3.large**: ~$60.74/month
- **EBS 30GB**: ~$2.40/month
- **Secrets Manager**: ~$0.40/month
- **Backend (S3 + DynamoDB)**: ~$0.50/month
- **Total**: ~$64.04/month

**Save costs**: Use `make stop` when not in use (~$3.30/month)

## 🔐 Security Best Practices

1. **SSH Access**: Restrict to your IP
   ```bash
   # Get your IP
   curl ifconfig.me

   # Update terraform.tfvars
   ssh_cidr = "YOUR_IP/32"
   ```

2. **Security Group**: Disable `allow_all_tcp` in production

3. **Secrets**: Never commit `terraform.tfvars` or `.pem` files

4. **AWS Credentials**: Use SSO instead of access keys

## 🔄 Workflow Examples

### Daily Development

```bash
# Start instance
make start
make health

# Work on your project
make ssh

# Stop when done
make stop
```

### Update Application

```bash
# Update container version
make update-container VERSION=1.0.1

# Verify
make health
make logs
```

### Troubleshooting

```bash
# Check status
make status

# View logs
make logs

# Check resources
make stats
make disk-usage

# Restart service
make restart
```

## 🐛 Troubleshooting

### SSH Connection Failed

```bash
# Check instance is running
make info

# Verify security group allows your IP
make sg-rules

# Try direct SSH
ssh -i ~/.ssh/aws-ec2-lab ec2-user@$(terraform output -raw public_ip)
```

### Application Not Responding

```bash
# Check service status
make status

# View container logs
make logs

# Restart service
make restart
```

### Permission Denied (AWS)

```bash
# Login to AWS
make aws-login

# Verify identity
make aws-whoami
```

## 📖 Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/)
- [Docker Documentation](https://docs.docker.com/)

## 👤 Author

Created as part of DevOps training program.

## 📝 License

This project is for educational purposes.
