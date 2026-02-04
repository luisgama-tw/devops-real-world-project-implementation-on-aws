# Remote Backend Configuration
# This configures Terraform to store state remotely in S3 with DynamoDB locking
#
# Benefits:
# - Centralized state storage (team collaboration)
# - State locking (prevents concurrent modifications)
# - State versioning (rollback capability)
# - Encryption at rest (security)
# - Automatic backup (disaster recovery)

terraform {
  backend "s3" {
    bucket         = "terraform-state-160071257600-us-east-1"
    key            = "infra/ec2-docker/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks-ec2-docker"
    encrypt        = true
    profile        = "tw-poweruserplus"
  }
}
