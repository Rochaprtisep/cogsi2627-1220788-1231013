#!/usr/bin/env bash
# ctrl VM bootstrap: installs Ansible (Ubuntu 24.04 packages) and the key it uses to reach the other VMs.
# This is the only shell provisioning left: everything else is done by Ansible.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if dpkg -s ansible python3-passlib >/dev/null 2>&1; then
  echo "[ctrl] Ansible ja instalado"
else
  echo "[ctrl] A instalar o Ansible"
  apt-get -o DPkg::Lock::Timeout=300 update -qq
  apt-get -o DPkg::Lock::Timeout=300 install -y -qq ansible python3-passlib
fi

# The synced folder is mounted with fmode=644 and ssh refuses private keys readable by others
install -d -o vagrant -g vagrant -m 0700 /home/vagrant/.ssh
install -o vagrant -g vagrant -m 0600 /vagrant/keys/ansible_ed25519 /home/vagrant/.ssh/ansible_ed25519

ansible --version | head -n 1