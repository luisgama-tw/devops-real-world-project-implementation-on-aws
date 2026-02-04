locals {
  # Project identification
  project_name = "ec2-docker"
  environment  = "dev"

  # Container configuration
  container_image = "stacksimplify/retail-store-sample-ui:1.0.0"
  container_port  = 8888
  service_name    = "myapp1"

  # Common tags
  common_tags = {
    Project     = "EC2-Docker-Lab"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "DevOps-Team"
  }

  # EC2 configuration
  instance_name = "${local.project_name}-${local.environment}"
}
