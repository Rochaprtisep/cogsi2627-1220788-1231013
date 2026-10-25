#!/usr/bin/env bash
# proxy VM: Nginx as reverse proxy for the Bookstore on the app VM. Idempotent.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

: "${APP_IP:?}"
SITE=/etc/nginx/sites-available/bookstore

missing=""
for p in nginx curl; do
  dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
done
if [ -n "$missing" ]; then
  echo "[proxy] A instalar:$missing"
  apt-get update -qq
  apt-get install -y -qq $missing
else
  echo "[proxy] Todos os pacotes ja estao instalados - nada a fazer"
fi

# Render the site with the app IP and install it only if it changed
changed=0
rendered=$(mktemp)
sed -e "s/__APP_IP__/$APP_IP/" -e 's/\r$//' /vagrant/config/nginx/bookstore.conf > "$rendered"
if ! cmp -s "$rendered" "$SITE"; then
  install -m 0644 "$rendered" "$SITE"
  changed=1
  echo "[proxy] Configuracao do site atualizada"
fi
rm -f "$rendered"

ln -sfn "$SITE" /etc/nginx/sites-enabled/bookstore
if [ -e /etc/nginx/sites-enabled/default ]; then
  rm -f /etc/nginx/sites-enabled/default
  changed=1
fi

nginx -t -q                       # never reload a broken configuration
systemctl enable --quiet --now nginx
if [ "$changed" = 1 ]; then
  systemctl reload nginx
  echo "[proxy] Nginx recarregado"
else
  echo "[proxy] Nginx sem alteracoes"
fi

# --- Health checks: Nginx answers AND forwards to a working Bookstore ---
curl -fs http://localhost/nginx-health >/dev/null && echo "[proxy] Nginx UP"
for i in $(seq 1 60); do
  if curl -fs http://localhost/actuator/health | grep -q '"db":{"status":"UP"' \
     && curl -fs http://localhost/books | grep -q '"title"'; then
    echo "[proxy] Proxy -> app -> db OK (${i}s). Abre http://localhost:8080/books no host"
    exit 0
  fi
  sleep 1
done
echo "[proxy] O proxy nao chega ao Bookstore em $APP_IP:8080 (502?). Ver: journalctl -u bookstore na VM app" >&2
exit 1
