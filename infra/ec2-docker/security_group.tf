resource "aws_security_group" "ec2_sg" {
  name        = "ec2-docker-sg"
  description = "Course: allow SSH 22 and ALL TCP (or 80/8080/9090)"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "Jupyter Notebook"
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # para laboratório; produção deve restringir
  }

  # ALL TCP (course option)
  dynamic "ingress" {
    for_each = var.allow_all_tcp ? [1] : []
    content {
      description = "ALL TCP (LAB ONLY)"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Only specific ports (more sane)
  dynamic "ingress" {
    for_each = var.allow_all_tcp ? [] : [1]
    content {
      description = "HTTP 80"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.allow_all_tcp ? [] : [1]
    content {
      description = "App 8080"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.allow_all_tcp ? [] : [1]
    content {
      description = "Metrics 9090"
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-sg"
    }
  )
}
