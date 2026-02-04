resource "aws_instance" "docker_host" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.large" # course requirement
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30 # course requirement
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    service_name    = local.service_name
    container_image = local.container_image
    container_port  = local.container_port
  })

  tags = merge(
    local.common_tags,
    {
      Name = local.instance_name
    }
  )
}

