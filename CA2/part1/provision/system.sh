#!/usr/bin/env bash
# Installs the system dependencies. Idempotent: only installs what is missing.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

PACKAGES="git curl unzip maven openjdk-17-jdk-headless openjdk-21-jdk-headless"

missing=""
for p in $PACKAGES; do
  dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
done

if [ -n "$missing" ]; then
  echo "[system] A instalar:$missing"
  apt-get update -qq
  apt-get install -y -qq $missing
else
  echo "[system] Todos os pacotes ja estao instalados - nada a fazer"
fi

echo "[system] JDKs disponiveis:"; ls /usr/lib/jvm
git --version
mvn -v | head -1