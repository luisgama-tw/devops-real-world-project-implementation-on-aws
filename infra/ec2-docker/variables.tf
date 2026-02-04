variable "aws_region" {
  description = "AWS region (course: any, e.g. us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use (your SSO profile)"
  type        = string
  default     = "tw-poweruserplus"
}

variable "key_name" {
  description = "EC2 Key Pair name (select an existing key pair)"
  type        = string
}

variable "allow_all_tcp" {
  description = "Course setting: allow ALL TCP (true) or only 80/8080/9090 (false)"
  type        = bool
  default     = true
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH (best practice). For lab you can use 0.0.0.0/0, but prefer your public IP /32."
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpc_id" {
  description = "vpc-0c18a24fe2f3bcf1a"
  type        = string
}

variable "subnet_id" {
  description = "subnet-0dfdde0639e1491dc"
  type        = string
}

variable "dockerhub_token" {
  description = "Docker Hub access token (will be stored in AWS Secrets Manager)"
  type        = string
  default     = "placeholder"
  sensitive   = true
}

