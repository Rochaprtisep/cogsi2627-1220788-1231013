#!/usr/bin/env bash
# db VM: H2 in server (TCP) mode as a systemd service, protected by ufw. Idempotent.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

: "${H2_VERSION:?}" "${H2_PORT:?}" "${DB_USER:?}" "${DB_PASSWORD:?}" "${APP_IP:?}"
DB_NAME=bookstore
H2_DIR=/opt/h2
DATA_DIR=/srv/h2
H2_JAR="$H2_DIR/h2-$H2_VERSION.jar"
H2_URL="https://repo1.maven.org/maven2/com/h2database/h2/$H2_VERSION/h2-$H2_VERSION.jar"
H2_RUN="java -cp $H2_DIR/h2.jar"

# --- 1. Packages (only a JRE: the db VM never compiles anything) ---
missing=""
for p in openjdk-17-jre-headless curl ufw; do
  dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
done
if [ -n "$missing" ]; then
  echo "[db] A instalar:$missing"
  apt-get update -qq
  apt-get install -y -qq $missing
else
  echo "[db] Todos os pacotes ja estao instalados - nada a fazer"
fi

# --- 2. Dedicated service account and directories ---
id h2 >/dev/null 2>&1 || useradd --system --home-dir "$DATA_DIR" --shell /usr/sbin/nologin h2
install -d -o root -g root -m 0755 "$H2_DIR"
install -d -o h2   -g h2   -m 0750 "$DATA_DIR"

# --- 3. H2 jar: same version as the driver inside the Bookstore, checked against Maven Central's SHA-1 ---
if [ ! -f "$H2_JAR" ]; then
  echo "[db] A descarregar o H2 $H2_VERSION"
  tmp=$(mktemp -d)
  curl -fsSL --retry 3 -o "$tmp/h2.jar"      "$H2_URL"
  curl -fsSL --retry 3 -o "$tmp/h2.jar.sha1" "$H2_URL.sha1"
  echo "$(cut -c1-40 "$tmp/h2.jar.sha1")  $tmp/h2.jar" | sha1sum -c --quiet
  install -o root -g root -m 0644 "$tmp/h2.jar" "$H2_JAR"
  rm -rf "$tmp"
else
  echo "[db] H2 $H2_VERSION ja instalado"
fi
ln -sfn "$H2_JAR" "$H2_DIR/h2.jar"

# --- 4. Create the database once, locally, with the application credentials ---
# The server runs WITHOUT -ifNotExists, so remote clients can never create databases.
if [ ! -f "$DATA_DIR/$DB_NAME.mv.db" ]; then
  echo "[db] A criar a base de dados '$DB_NAME' (utilizador $DB_USER)"
  systemctl stop h2 2>/dev/null || true
  runuser -u h2 -- $H2_RUN org.h2.tools.Shell \
    -url "jdbc:h2:$DATA_DIR/$DB_NAME" -user "$DB_USER" -password "$DB_PASSWORD" -sql "SELECT 1" >/dev/null
else
  echo "[db] A base de dados '$DB_NAME' ja existe"
fi

# --- 5. systemd unit (only rewritten and restarted when it changes) ---
UNIT=/etc/systemd/system/h2.service
new=$(mktemp)
cat > "$new" <<EOF
[Unit]
Description=H2 Database (TCP server mode)
After=network-online.target
Wants=network-online.target

[Service]
User=h2
Group=h2
WorkingDirectory=$DATA_DIR
ExecStart=/usr/bin/java -Xmx512m -cp $H2_DIR/h2.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort $H2_PORT -baseDir $DATA_DIR
SuccessExitStatus=143
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
if ! cmp -s "$new" "$UNIT"; then
  install -m 0644 "$new" "$UNIT"
  systemctl daemon-reload
  systemctl enable --quiet h2
  systemctl restart h2
  echo "[db] h2.service instalado/atualizado e reiniciado"
else
  systemctl enable --quiet --now h2
  echo "[db] h2.service sem alteracoes"
fi
rm -f "$new"

# --- 6. Firewall: SSH for Vagrant, H2 only from the app VM ---
ufw default deny incoming  >/dev/null
ufw default allow outgoing >/dev/null
ufw allow 22/tcp >/dev/null
ufw allow from "$APP_IP" to any port "$H2_PORT" proto tcp comment 'H2 from app VM' >/dev/null
ufw --force enable >/dev/null
ufw status numbered

# --- 7. Health check: H2 must answer a SQL query over TCP (an open port is not enough) ---
ok=0
for i in $(seq 1 30); do
  if runuser -u h2 -- $H2_RUN org.h2.tools.Shell -url "jdbc:h2:tcp://localhost:$H2_PORT/$DB_NAME" \
       -user "$DB_USER" -password "$DB_PASSWORD" -sql "SELECT 1" >/dev/null 2>&1; then
    ok=1; break
  fi
  sleep 1
done
if [ "$ok" = 1 ]; then
  echo "[db] H2 UP na porta $H2_PORT e responde a SQL"
else
  echo "[db] H2 nao responde. Ver: journalctl -u h2 -n 50" >&2
  exit 1
fi
