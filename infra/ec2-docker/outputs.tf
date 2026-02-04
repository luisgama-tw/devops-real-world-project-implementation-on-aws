output "public_ip" {
  value = aws_instance.docker_host.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/<YOUR_PRIVATE_KEY> ec2-user@${aws_instance.docker_host.public_ip}"
}

output "dockerhub_secret_arn" {
  value       = aws_secretsmanager_secret.dockerhub_token.arn
  description = "ARN of the Docker Hub token secret"
}

output "dockerhub_secret_name" {
  value       = aws_secretsmanager_secret.dockerhub_token.name
  description = "Name of the Docker Hub token secret"
}

output "instance_id" {
  value       = aws_instance.docker_host.id
  description = "ID of the EC2 instance"
}

output "security_group_id" {
  value       = aws_security_group.ec2_sg.id
  description = "ID of the security group"
}

output "private_ip" {
  value       = aws_instance.docker_host.private_ip
  description = "Private IP of the EC2 instance"
}

# Backend outputs
output "backend_bucket" {
  value       = aws_s3_bucket.terraform_state.id
  description = "S3 bucket name for Terraform state"
}

output "backend_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "ARN of the S3 bucket for Terraform state"
}

output "backend_dynamodb_table" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "DynamoDB table name for state locking"
}

output "iam_role_arn" {
  value       = aws_iam_role.ec2_role.arn
  description = "ARN of the EC2 IAM role"
}
