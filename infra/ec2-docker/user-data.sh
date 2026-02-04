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
cat >/etc/systemd/system/${service_name}.service <<'SERVICE'
[Unit]
Description=Retail UI container
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=10
ExecStartPre=-/usr/bin/docker rm -f ${service_name}
ExecStartPre=/usr/bin/docker pull ${container_image}
ExecStart=/usr/bin/docker run --name ${service_name} --restart unless-stopped -p ${container_port}:8080 ${container_image}
ExecStop=/usr/bin/docker stop ${service_name}

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now ${service_name}

# validate locally (give app time)
for i in {1..30}; do
  if curl -fsS http://localhost:${container_port} >/dev/null 2>&1; then
    echo "Retail UI OK on localhost:${container_port}"
    exit 0
  fi
  sleep 2
done

echo "Retail UI did not become ready in time" >&2
systemctl status ${service_name} --no-pager || true
docker ps -a || true
exit 1
