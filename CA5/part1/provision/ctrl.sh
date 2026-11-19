#!/usr/bin/env bash
# ctrl bootstrap: Ansible, Gradle prerequisites and Java for the Jenkins agent. Idempotent.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

PKGS="ansible python3-passlib git curl rsync openjdk-17-jdk-headless openjdk-21-jre-headless"
missing=""
for p in $PKGS; do dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"; done
if [ -n "$missing" ]; then
  echo "[ctrl] A instalar:$missing"
  apt-get -o DPkg::Lock::Timeout=300 update -qq
  apt-get -o DPkg::Lock::Timeout=300 install -y -qq $missing
fi

# The synced folder is fmode=644 and ssh refuses private keys readable by others
install -d -o vagrant -g vagrant -m 0700 /home/vagrant/.ssh
install -o vagrant -g vagrant -m 0600 /vagrant/keys/ansible_ed25519 /home/vagrant/.ssh/ansible_ed25519

# Jenkins agent workspace
install -d -o vagrant -g vagrant /home/vagrant/jenkins

ansible --version | head -n 1
ls /usr/lib/jvm
