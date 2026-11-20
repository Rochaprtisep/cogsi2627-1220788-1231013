#!/usr/bin/env bash
# ctrl2 bootstrap: Ansible, Docker, Java for Gradle and for the Jenkins agent. Idempotent.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

PKGS="ansible python3-passlib python3-docker git curl docker.io openjdk-17-jdk-headless openjdk-21-jre-headless"
missing=""
for p in $PKGS; do dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"; done
if [ -n "$missing" ]; then
  echo "[ctrl2] A instalar:$missing"
  apt-get -o DPkg::Lock::Timeout=300 update -qq
  apt-get -o DPkg::Lock::Timeout=300 install -y -qq $missing
fi

systemctl enable --now docker
# The Jenkins agent runs as vagrant and must use Docker without sudo
usermod -aG docker vagrant

install -d -o vagrant -g vagrant -m 0700 /home/vagrant/.ssh
install -o vagrant -g vagrant -m 0600 /vagrant/keys/ansible_ed25519 /home/vagrant/.ssh/ansible_ed25519
install -d -o vagrant -g vagrant /home/vagrant/jenkins

ansible --version | head -n 1
docker --version
