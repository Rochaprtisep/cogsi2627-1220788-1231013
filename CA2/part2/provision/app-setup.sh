#!/usr/bin/env bash
# app VM: system packages and firewall. Idempotent.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

: "${PROXY_IP:?}"

missing=""
for p in git curl ufw openjdk-17-jdk-headless; do
  dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
done
if [ -n "$missing" ]; then
  echo "[app-setup] A instalar:$missing"
  apt-get update -qq
  apt-get install -y -qq $missing
else
  echo "[app-setup] Todos os pacotes ja estao instalados - nada a fazer"
fi

# Only the proxy VM may reach the Bookstore on 8080; SSH stays open for Vagrant
ufw default deny incoming  >/dev/null
ufw default allow outgoing >/dev/null
ufw allow 22/tcp >/dev/null
ufw allow from "$PROXY_IP" to any port 8080 proto tcp comment 'Bookstore from proxy VM' >/dev/null
ufw --force enable >/dev/null
ufw status numbered
