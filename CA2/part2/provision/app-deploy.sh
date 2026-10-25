#!/usr/bin/env bash
# app VM: installs the Bookstore as a systemd service that connects to H2 on the db VM. Idempotent.
set -euo pipefail

if [ "${START_APPS:-true}" != "true" ]; then
  echo "[app-deploy] START_APPS=false - servico nao arrancado"
  exit 0
fi
: "${DB_IP:?}" "${H2_PORT:?}" "${DB_USER:?}" "${DB_PASSWORD:?}"

REPO_DIR=/home/vagrant/cogsi
BOOK_LIBS="$REPO_DIR/CA1/part2/app/build/libs"
APP_DIR=/opt/bookstore
ENV_DIR=/etc/bookstore

if [ ! -d "$BOOK_LIBS" ]; then
  echo "[app-deploy] ERRO: o Bookstore ainda nao foi compilado. Corre com BUILD_APPS=true." >&2
  exit 1
fi

# --- Service account and directories (the service never runs as vagrant or root) ---
id bookstore >/dev/null 2>&1 || useradd --system --home-dir "$APP_DIR" --shell /usr/sbin/nologin bookstore
install -d -o root -g bookstore -m 0750 "$APP_DIR" "$ENV_DIR"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Copies a file only when its content changed, and remembers that a restart is needed
changed=0
put() { # put <src> <dst> <mode> <group>
  if ! cmp -s "$1" "$2"; then
    install -o root -g "$4" -m "$3" "$1" "$2"
    changed=1
    echo "[app-deploy] Atualizado: $2"
  fi
}

BOOT_JAR=$(ls "$BOOK_LIBS"/bookstore-*.jar | grep -v -- '-plain' | head -1)
# Text files come from the synced folder: strip Windows line endings (CRLF) first
tr -d '\r' < /vagrant/config/application.properties > "$work/application.properties"
tr -d '\r' < /vagrant/provision/wait-for-h2.sh      > "$work/wait-for-h2.sh"

put "$BOOT_JAR"                      "$APP_DIR/bookstore.jar"          0640 bookstore
put "$work/application.properties"   "$APP_DIR/application.properties" 0640 bookstore
put "$work/wait-for-h2.sh"           /usr/local/bin/wait-for-h2.sh     0755 root

# --- Credentials: only root and the service account can read them ---
cat > "$work/bookstore.env" <<EOF
DB_HOST=$DB_IP
DB_PORT=$H2_PORT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
EOF
put "$work/bookstore.env" "$ENV_DIR/bookstore.env" 0640 bookstore

# --- systemd unit ---
cat > "$work/bookstore.service" <<'UNIT'
[Unit]
Description=Bookstore Spring Boot application
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
User=bookstore
Group=bookstore
WorkingDirectory=/opt/bookstore
EnvironmentFile=/etc/bookstore/bookstore.env
# Health check: do not start the application until the H2 TCP port answers
ExecStartPre=/usr/local/bin/wait-for-h2.sh ${DB_HOST} ${DB_PORT} 60
ExecStart=/usr/bin/java -Xmx768m -jar /opt/bookstore/bookstore.jar
SuccessExitStatus=143
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
put "$work/bookstore.service" /etc/systemd/system/bookstore.service 0644 root

systemctl daemon-reload
systemctl enable --quiet bookstore

# --- Start (or restart only if something changed) ---
/usr/local/bin/wait-for-h2.sh "$DB_IP" "$H2_PORT" 60
if [ "$changed" = 1 ]; then
  systemctl restart bookstore
else
  systemctl start bookstore
  echo "[app-deploy] Nada mudou - servico mantido"
fi

# --- Application-level health check: the app is UP and its DB connection is UP ---
echo "[app-deploy] A aguardar pelo Bookstore..."
for i in $(seq 1 90); do
  health=$(curl -fs http://localhost:8080/actuator/health || true)
  if echo "$health" | grep -q '"db":{"status":"UP"'; then
    echo "[app-deploy] Bookstore UP e ligado ao H2 (${i}s): $health"
    exit 0
  fi
  sleep 1
done
echo "[app-deploy] Bookstore nao arrancou. Ver: journalctl -u bookstore -n 80" >&2
exit 1
