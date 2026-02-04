resource "aws_instance" "docker_host" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.large" # course requirement
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 30 # course requirement
    volume_type = "gp3"
  }

  user_data = <<-EOF
            #!/bin/bash
            set -euxo pipefail

            dnf -y update
            dnf -y install docker
            systemctl enable --now docker

            # wait docker be ready
            until docker info >/dev/null 2>&1; do
              sleep 3
            done

            # create systemd service (reproducible, recreated on every instance)
            cat >/etc/systemd/system/myapp1.service <<'SERVICE'
            [Unit]
            Description=Retail UI container
            After=docker.service
            Requires=docker.service

            [Service]
            Restart=always
            RestartSec=10
            ExecStartPre=-/usr/bin/docker rm -f myapp1
            ExecStartPre=/usr/bin/docker pull stacksimplify/retail-store-sample-ui:1.0.0
            ExecStart=/usr/bin/docker run --name myapp1 --restart unless-stopped -p 8888:8080 stacksimplify/retail-store-sample-ui:1.0.0
            ExecStop=/usr/bin/docker stop myapp1

            [Install]
            WantedBy=multi-user.target
            SERVICE

            systemctl daemon-reload
            systemctl enable --now myapp1

            # validate locally (give app time)
            for i in {1..30}; do
              if curl -fsS http://localhost:8888 >/dev/null 2>&1; then
                echo "Retail UI OK on localhost:8888"
                exit 0
              fi
              sleep 2
            done

            echo "Retail UI did not become ready in time" >&2
            systemctl status myapp1 --no-pager || true
            docker ps -a || true
            exit 1
            EOF

  tags = {
    Name = "docker-ec2-lab"
  }
}

