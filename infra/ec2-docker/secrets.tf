# AWS Secrets Manager for Docker Hub token
resource "aws_secretsmanager_secret" "dockerhub_token" {
  name        = "MyTWTestToken"
  description = "Docker Hub access token for luisgamatw"

  tags = {
    Name        = "MyTWTestToken"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Secret version - value will be set manually via AWS CLI or Console
resource "aws_secretsmanager_secret_version" "dockerhub_token_version" {
  secret_id     = aws_secretsmanager_secret.dockerhub_token.id
  secret_string = var.dockerhub_token

  lifecycle {
    ignore_changes = [secret_string]
  }
}
