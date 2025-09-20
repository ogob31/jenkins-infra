#!/bin/bash
set -euxo pipefail

# Log all output to cloud-init logs too
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update and install Docker
apt-get update -y
apt-get install -y docker.io curl
systemctl enable docker
systemctl start docker

# Add ubuntu user to the docker group (takes effect on next login)
usermod -aG docker ubuntu

# Pre-pull Jenkins image (lts uses recent JDK; fine)
JENKINS_IMAGE="jenkins/jenkins:lts"
docker pull "${JENKINS_IMAGE}"

# Generate an SSH key for Jenkins agent usage (optional)
sudo -u ubuntu mkdir -p /home/ubuntu/.ssh
sudo -u ubuntu ssh-keygen -t rsa -b 4096 -f /home/ubuntu/.ssh/id_rsa -N "" || true

# Get host docker group id for socket permissions
DOCKER_GID=$(getent group docker | cut -d: -f3)

# Run Jenkins (IMPORTANT: no comment after backslash)
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --group-add "${DOCKER_GID}" \
  --restart unless-stopped \
  "${JENKINS_IMAGE}"

echo "=========================================="
echo "YOUR JENKINS SERVER'S PUBLIC SSH KEY:"
cat /home/ubuntu/.ssh/id_rsa.pub || true
echo "=========================================="

echo "Waiting for Jenkins to initialize (this can take a couple of minutes)..."
# Poll for admin password for up to ~4 minutes
for i in {1..24}; do
  if docker exec jenkins sh -c 'cat /var/jenkins_home/secrets/initialAdminPassword' >/tmp/adminpass 2>/dev/null; then
    echo "Initial Admin Password:"
    cat /tmp/adminpass
    break
  fi
  sleep 10
done

echo "If password not shown yet, run:  docker logs jenkins  | tail -n 50"
