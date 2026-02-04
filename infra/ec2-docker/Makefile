.PHONY: help init plan apply destroy ssh logs status restart update-container validate clean aws-login aws-logout aws-whoami stats disk-usage info sg-rules cost-estimate stop start docker-login docker-secret-setup docker-secret-update docker-secret-show

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(GREEN)DevOps EC2-Docker Management Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

# Terraform Commands
init: ## Initialize Terraform
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	terraform init

validate: ## Validate Terraform configuration
	@echo "$(GREEN)Validating Terraform configuration...$(NC)"
	terraform validate

plan: ## Show Terraform plan
	@echo "$(GREEN)Planning infrastructure changes...$(NC)"
	terraform plan

apply: ## Apply Terraform configuration
	@echo "$(GREEN)Applying infrastructure...$(NC)"
	terraform apply

apply-auto: ## Apply without confirmation (use with caution!)
	@echo "$(YELLOW)Auto-applying infrastructure...$(NC)"
	terraform apply -auto-approve

destroy: ## Destroy all infrastructure
	@echo "$(RED)Destroying infrastructure...$(NC)"
	terraform destroy

destroy-auto: ## Destroy without confirmation (dangerous!)
	@echo "$(RED)Auto-destroying infrastructure...$(NC)"
	terraform destroy -auto-approve

# Instance Management
ssh: ## SSH into EC2 instance
	@echo "$(GREEN)Connecting to EC2 instance...$(NC)"
	@PUBLIC_IP=$$(terraform output -raw public_ip 2>/dev/null); \
	if [ -z "$$PUBLIC_IP" ]; then \
		echo "$(RED)Error: Could not get public IP. Run 'make apply' first.$(NC)"; \
		exit 1; \
	fi; \
	echo "Connecting to $$PUBLIC_IP..."; \
	ssh -i ~/.ssh/aws-ec2-lab ec2-user@$$PUBLIC_IP

logs: ## Show Docker container logs
	@echo "$(GREEN)Fetching container logs...$(NC)"
	@PUBLIC_IP=$$(terraform output -raw public_ip 2>/dev/null); \
	if [ -z "$$PUBLIC_IP" ]; then \
		echo "$(RED)Error: Could not get public IP.$(NC)"; \
		exit 1; \
	fi; \
	ssh -i ~/.ssh/aws-ec2-lab ec2-user@$$PUBLIC_IP \
		"docker logs myapp1 --tail 100 -f"

status: ## Check service and container status
	@echo "$(GREEN)Checking service status...$(NC)"
	@PUBLIC_IP=$$(terraform output -raw public_ip 2>/dev/null); \
	if [ -z "$$PUBLIC_IP" ]; then \
		echo "$(RED)Error: Could not get public IP.$(NC)"; \
		exit 1; \
	fi; \
	ssh -i ~/.ssh/aws-ec2-lab ec2-user@$$PUBLIC_IP \
		"echo '=== Docker Status ===' && docker ps && echo '' && echo '=== Service Status ===' && sudo systemctl status myapp1 --no-pager"

restart: ## Restart the myapp1 service
	@echo "$(YELLOW)Restarting myapp1 service...$(NC)"
	@PUBLIC_IP=$$(terraform output -raw public_ip 2>/dev/null); \
	if [ -z "$$PUBLIC_IP" ]; then \
		echo "$(RED)Error: Could not get public IP.$(NC)"; \
		exit 1; \
	fi; \
	ssh -i ~/.ssh/aws-ec2-lab ec2-user@$$PUBLIC_IP \
		"sudo systemctl restart myapp1 && sleep 3 && sudo systemctl status myapp1 --no-pager"

# Application Management
update-container: ## Update container to latest version (specify VERSION=x.x.x)
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)Error: VERSION not specified. Usage: make update-container VERSION=1.0.1$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Updating container to version $(VERSION)...$(NC)"
	@PUBLIC_IP=$$(terraform output -raw public_ip 2>/dev/null); \
	if [ -z "$$PUBLIC_IP" ]; then \
		echo "$(RED)Error: Could not get public IP.$(NC)"; \
		exit 1; \
	fi; \
	ssh -i ~/.ssh/aws-ec2-lab ec2-user@$$PUBLIC_IP \
		"docker pull stacksimplify/retail-store-sample-ui:$(VERSION) && \
		 sudo sed -i 's|retail-store-sample-ui:.*|retail-store-sample-ui:$(VERSION)|g' /etc/systemd/system/myapp1.service && \
		 sudo systemctl daemon-reload && \
		 sudo systemctl restart myapp1 && \
		 sleep 5 && \
		 sudo systemctl status myapp1 --no-pager"

health: ## Check application health
	@echo "$(GREEN)Checking application health...$(NC)"
	@PUBLIC_IP=$$(terraform output -raw public_ip 2>/dev/null); \
	if [ -z "$$PUBLIC_IP" ]; then \
		echo "$(RED)Error: Could not get public IP.$(NC)"; \
		exit 1; \
	fi; \
	echo "Testing http://$$PUBLIC_IP:8888"; \
	if curl -fsS http://$$PUBLIC_IP:8888 >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Application is healthy!$(NC)"; \
	else \
		echo "$(RED)✗ Application is not responding$(NC)"; \
		exit 1; \
	fi

open: ## Open application in browser
	@PUBLIC_IP=$$(terraform output -raw public_ip 2>/dev/null); \
	if [ -z "$$PUBLIC_IP" ]; then \
		echo "$(RED)Error: Could not get public IP.$(NC)"; \
		exit 1; \
	fi; \
	echo "$(GREEN)Opening http://$$PUBLIC_IP:8888 in browser...$(NC)"; \
	open http://$$PUBLIC_IP:8888 || xdg-open http://$$PUBLIC_IP:8888

# Utility Commands
output: ## Show all Terraform outputs
	@terraform output

clean: ## Clean Terraform state and cache
	@echo "$(YELLOW)Cleaning Terraform cache...$(NC)"
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	@echo "$(GREEN)Done! Run 'make init' to reinitialize.$(NC)"

fmt: ## Format Terraform files
	@echo "$(GREEN)Formatting Terraform files...$(NC)"
	terraform fmt -recursive

# AWS Authentication
aws-login: ## Login to AWS via SSO
	@echo "$(GREEN)Logging into AWS SSO...$(NC)"
	@AWS_PROFILE=$$(awk '/variable "aws_profile"/,/}/' variables.tf | grep 'default' | grep -o '"[^"]*"' | tr -d '"'); \
	if [ -z "$$AWS_PROFILE" ]; then \
		AWS_PROFILE="tw-poweruserplus"; \
	fi; \
	echo "Using profile: $$AWS_PROFILE"; \
	aws sso login --profile $$AWS_PROFILE

aws-logout: ## Logout from AWS SSO
	@echo "$(YELLOW)Logging out from AWS SSO...$(NC)"
	@aws sso logout
	@echo "$(GREEN)Logged out successfully!$(NC)"

aws-whoami: ## Show current AWS identity
	@echo "$(GREEN)Current AWS Identity:$(NC)"
	@AWS_PROFILE=$$(awk '/variable "aws_profile"/,/}/' variables.tf | grep 'default' | grep -o '"[^"]*"' | tr -d '"'); \
	if [ -z "$$AWS_PROFILE" ]; then \
		AWS_PROFILE="tw-poweruserplus"; \
	fi; \
	aws sts get-caller-identity --profile $$AWS_PROFILE || echo "$(RED)Not logged in. Run 'make aws-login' first.$(NC)"

# Docker Hub Authentication
docker-secret-setup: ## Create/update Docker Hub token in AWS Secrets Manager
	@echo "$(GREEN)Setting up Docker Hub token in AWS Secrets Manager...$(NC)"
	@echo ""
	@AWS_PROFILE=$$(awk '/variable "aws_profile"/,/}/' variables.tf | grep 'default' | grep -o '"[^"]*"' | tr -d '"'); \
	if [ -z "$$AWS_PROFILE" ]; then \
		AWS_PROFILE="tw-poweruserplus"; \
	fi; \
	echo "1. Generate token at: https://hub.docker.com/settings/security"; \
	echo "2. Enter your Docker Hub access token:"; \
	read -s TOKEN; \
	echo ""; \
	echo "Storing token in AWS Secrets Manager (MyTWTestToken)..."; \
	aws secretsmanager put-secret-value \
		--secret-id MyTWTestToken \
		--secret-string "$$TOKEN" \
		--profile $$AWS_PROFILE && \
	echo "$(GREEN)✓ Token stored successfully in AWS Secrets Manager!$(NC)"

docker-secret-update: ## Update Docker Hub token in AWS Secrets Manager
	@echo "$(YELLOW)Updating Docker Hub token...$(NC)"
	@AWS_PROFILE=$$(awk '/variable "aws_profile"/,/}/' variables.tf | grep 'default' | grep -o '"[^"]*"' | tr -d '"'); \
	if [ -z "$$AWS_PROFILE" ]; then \
		AWS_PROFILE="tw-poweruserplus"; \
	fi; \
	echo "Enter new Docker Hub access token:"; \
	read -s TOKEN; \
	echo ""; \
	aws secretsmanager put-secret-value \
		--secret-id MyTWTestToken \
		--secret-string "$$TOKEN" \
		--profile $$AWS_PROFILE && \
	echo "$(GREEN)✓ Token updated successfully!$(NC)"

docker-secret-show: ## Show Docker Hub secret metadata (not the token value)
	@echo "$(GREEN)Docker Hub Secret Information:$(NC)"
	@AWS_PROFILE=$$(awk '/variable "aws_profile"/,/}/' variables.tf | grep 'default' | grep -o '"[^"]*"' | tr -d '"'); \
	if [ -z "$$AWS_PROFILE" ]; then \
		AWS_PROFILE="tw-poweruserplus"; \
	fi; \
	aws secretsmanager describe-secret \
		--secret-id MyTWTestToken \
		--profile $$AWS_PROFILE \
		--output table || echo "$(RED)Secret not found. Run 'make apply' first.$(NC)"

docker-login: ## Login to Docker Hub using token from AWS Secrets Manager
	@echo "$(GREEN)Logging into Docker Hub...$(NC)"
	@AWS_PROFILE=$$(awk '/variable "aws_profile"/,/}/' variables.tf | grep 'default' | grep -o '"[^"]*"' | tr -d '"'); \
	if [ -z "$$AWS_PROFILE" ]; then \
		AWS_PROFILE="tw-poweruserplus"; \
	fi; \
	echo "Fetching token from AWS Secrets Manager..."; \
	TOKEN=$$(aws secretsmanager get-secret-value \
		--secret-id MyTWTestToken \
		--profile $$AWS_PROFILE \
		--query SecretString \
		--output text 2>/dev/null); \
	if [ -z "$$TOKEN" ]; then \
		echo "$(RED)Error: Could not retrieve token from AWS Secrets Manager.$(NC)"; \
		echo "Run 'make docker-secret-setup' first or check your AWS login."; \
		exit 1; \
	fi; \
	echo "Username: luisgamatw"; \
	echo "$$TOKEN" | docker login -u luisgamatw --password-stdin && \
	echo "$(GREEN)✓ Successfully logged into Docker Hub!$(NC)"

# Monitoring & Statistics
stats: ## Show real-time instance statistics (CPU, memory, disk)
	@echo "$(GREEN)Fetching instance statistics...$(NC)"
	@PUBLIC_IP=$$(terraform output -raw public_ip 2>/dev/null); \
	if [ -z "$$PUBLIC_IP" ]; then \
		echo "$(RED)Error: Could not get public IP.$(NC)"; \
		exit 1; \
	fi; \
	ssh -i ~/.ssh/aws-ec2-lab -o StrictHostKeyChecking=no ec2-user@$$PUBLIC_IP \
		"echo '=== System Info ===' && \
		 uptime && \
		 echo '' && \
		 echo '=== CPU & Memory ===' && \
		 top -bn1 | head -15 && \
		 echo '' && \
		 echo '=== Disk Usage ===' && \
		 df -h /"

disk-usage: ## Show detailed disk usage
	@echo "$(GREEN)Analyzing disk usage...$(NC)"
	@PUBLIC_IP=$$(terraform output -raw public_ip 2>/dev/null); \
	if [ -z "$$PUBLIC_IP" ]; then \
		echo "$(RED)Error: Could not get public IP.$(NC)"; \
		exit 1; \
	fi; \
	ssh -i ~/.ssh/aws-ec2-lab -o StrictHostKeyChecking=no ec2-user@$$PUBLIC_IP \
		"echo '=== Disk Space ===' && \
		 df -h && \
		 echo '' && \
		 echo '=== Docker Usage ===' && \
		 docker system df && \
		 echo '' && \
		 echo '=== Top Directories ===' && \
		 sudo du -sh /var/lib/docker/* 2>/dev/null | sort -h"

# Information & Security
info: ## Show detailed instance information
	@echo "$(GREEN)Instance Information:$(NC)"
	@terraform show -json | jq -r '.values.root_module.resources[] | select(.type=="aws_instance") | {instance_id: .values.id, instance_type: .values.instance_type, availability_zone: .values.availability_zone, public_ip: .values.public_ip, private_ip: .values.private_ip, state: .values.instance_state}' 2>/dev/null || \
	(echo "Instance ID: $$(terraform output -raw instance_id 2>/dev/null || echo 'N/A')" && \
	 echo "Public IP: $$(terraform output -raw public_ip 2>/dev/null || echo 'N/A')" && \
	 echo "Run 'terraform show' for full details")

sg-rules: ## Show security group rules
	@echo "$(GREEN)Security Group Rules:$(NC)"
	@AWS_PROFILE=$$(awk '/variable "aws_profile"/,/}/' variables.tf | grep 'default' | grep -o '"[^"]*"' | tr -d '"'); \
	if [ -z "$$AWS_PROFILE" ]; then \
		AWS_PROFILE="tw-poweruserplus"; \
	fi; \
	SG_ID=$$(terraform state show aws_security_group.ec2_sg 2>/dev/null | grep "^[[:space:]]*id" | awk '{print $$3}' | tr -d '"'); \
	if [ -z "$$SG_ID" ]; then \
		echo "$(RED)Security group not found. Run 'make apply' first.$(NC)"; \
		exit 1; \
	fi; \
	echo "Security Group ID: $$SG_ID"; \
	echo ""; \
	aws ec2 describe-security-groups --group-ids $$SG_ID --profile $$AWS_PROFILE --output table

# Cost Management
cost-estimate: ## Estimate monthly AWS costs
	@echo "$(GREEN)Monthly Cost Estimate:$(NC)"
	@echo ""
	@echo "Instance Type: t3.large"
	@echo "  - On-Demand: ~\$$0.0832/hour"
	@echo "  - Monthly (730h): ~\$$60.74"
	@echo ""
	@echo "EBS Volume (gp3, 30GB):"
	@echo "  - Storage: ~\$$2.40/month"
	@echo "  - IOPS (3000): Included"
	@echo "  - Throughput (125 MB/s): Included"
	@echo ""
	@echo "AWS Secrets Manager:"
	@echo "  - Secret storage (MyTWTestToken): ~\$$0.40/month"
	@echo "  - API calls: ~\$$0.05/10,000 calls (negligible)"
	@echo ""
	@echo "Data Transfer:"
	@echo "  - Inbound: Free"
	@echo "  - Outbound (first 100GB): Free"
	@echo "  - Outbound (>100GB): ~\$$0.09/GB"
	@echo ""
	@echo "$(YELLOW)Estimated Total: ~\$$63.54/month$(NC)"
	@echo ""
	@echo "💡 Tip: Use 'make stop' when not in use to save costs"
	@echo "   - Stopped instance: ~\$$2.80/month (EBS + Secrets Manager only)"

# Instance Operations
stop: ## Stop EC2 instance (saves costs, keeps EBS)
	@echo "$(YELLOW)Stopping EC2 instance...$(NC)"
	@AWS_PROFILE=$$(awk '/variable "aws_profile"/,/}/' variables.tf | grep 'default' | grep -o '"[^"]*"' | tr -d '"'); \
	if [ -z "$$AWS_PROFILE" ]; then \
		AWS_PROFILE="tw-poweruserplus"; \
	fi; \
	INSTANCE_ID=$$(terraform state show aws_instance.docker_host 2>/dev/null | grep "^[[:space:]]*id" | awk '{print $$3}' | tr -d '"'); \
	if [ -z "$$INSTANCE_ID" ]; then \
		echo "$(RED)Instance not found. Run 'make apply' first.$(NC)"; \
		exit 1; \
	fi; \
	echo "Stopping instance: $$INSTANCE_ID"; \
	aws ec2 stop-instances --instance-ids $$INSTANCE_ID --profile $$AWS_PROFILE && \
	echo "$(GREEN)Instance stopped successfully!$(NC)" && \
	echo "Run 'make start' to start it again."

start: ## Start stopped EC2 instance
	@echo "$(GREEN)Starting EC2 instance...$(NC)"
	@AWS_PROFILE=$$(awk '/variable "aws_profile"/,/}/' variables.tf | grep 'default' | grep -o '"[^"]*"' | tr -d '"'); \
	if [ -z "$$AWS_PROFILE" ]; then \
		AWS_PROFILE="tw-poweruserplus"; \
	fi; \
	INSTANCE_ID=$$(terraform state show aws_instance.docker_host 2>/dev/null | grep "^[[:space:]]*id" | awk '{print $$3}' | tr -d '"'); \
	if [ -z "$$INSTANCE_ID" ]; then \
		echo "$(RED)Instance not found. Run 'make apply' first.$(NC)"; \
		exit 1; \
	fi; \
	echo "Starting instance: $$INSTANCE_ID"; \
	aws ec2 start-instances --instance-ids $$INSTANCE_ID --profile $$AWS_PROFILE && \
	echo "$(GREEN)Instance starting...$(NC)" && \
	echo "Waiting for instance to be ready..." && \
	sleep 10 && \
	echo "Run 'make health' to check if the application is ready."

# Quick Deploy
quick-deploy: init validate apply ## Initialize, validate and apply in one command
	@echo "$(GREEN)Quick deploy completed!$(NC)"

# Full Cycle
full-cycle: clean init validate plan apply health ## Full deployment cycle with health check
	@echo "$(GREEN)Full deployment cycle completed successfully!$(NC)"
