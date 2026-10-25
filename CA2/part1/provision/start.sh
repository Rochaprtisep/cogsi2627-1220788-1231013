#!/usr/bin/env bash
# Installs the built artifacts as systemd services and (re)starts them.
# Runs on every `vagrant up`/`reload`, after Vagrant has mounted the synced folders.
set -euo pipefail

if [ "${START_APPS:-true}" != "true" ]; then
  echo "[start] START_APPS=false - servicos nao arrancados"
  exit 0
fi

REPO_DIR=/home/vagrant/cogsi
CHAT_LIBS="$REPO_DIR/CA1/part1/app/build/libs"
BOOK_LIBS="$REPO_DIR/CA1/part2/app/build/libs"

if [ ! -d "$CHAT_LIBS" ] || [ ! -d "$BOOK_LIBS" ]; then
  echo "[start] ERRO: aplicacoes ainda nao compiladas. Corre com BUILD_APPS=true." >&2
  exit 1
fi

# --- Copy artifacts to /opt (the services never run from the git working copy) ---
install -d -o vagrant -g vagrant /opt/chat /opt/bookstore
rm -rf /opt/chat/*.jar /opt/chat/lib
cp "$CHAT_LIBS"/chat-server-*.jar /opt/chat/
cp -r "$CHAT_LIBS/lib" /opt/chat/lib
BOOT_JAR=$(ls "$BOOK_LIBS"/bookstore-*.jar | grep -v -- '-plain' | head -1)
cp "$BOOT_JAR" /opt/bookstore/bookstore.jar

# --- H2 persistence: external config pointing to the synced folder ---
cp /vagrant/config/application.properties /opt/bookstore/application.properties
# --- systemd units ---
cat > /etc/systemd/system/chat-server.service <<'UNIT'
[Unit]
Description=Gradle demo chat server
After=network.target

[Service]
User=vagrant
WorkingDirectory=/opt/chat
ExecStart=/usr/bin/java -cp "/opt/chat/*:/opt/chat/lib/*" org.example.ChatServerApp 59001
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

cat > /etc/systemd/system/bookstore.service <<'UNIT'
[Unit]
Description=Bookstore Spring Boot application
After=network.target
ConditionPathIsMountPoint=/home/vagrant/h2-data

[Service]
User=vagrant
WorkingDirectory=/opt/bookstore
ExecStart=/usr/bin/java -jar /opt/bookstore/bookstore.jar
SuccessExitStatus=143
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl restart chat-server bookstore

# --- Wait until the Bookstore answers ---
echo "[start] A aguardar pelo Bookstore..."
for i in $(seq 1 60); do
  if curl -fs http://localhost:8080/actuator/health >/dev/null; then
    echo "[start] Bookstore UP em http://localhost:8080 (${i}s)"
    break
  fi
  sleep 1
done
curl -fs http://localhost:8080/actuator/health >/dev/null || { echo "[start] Bookstore nao arrancou: journalctl -u bookstore" >&2; exit 1; }
systemctl is-active --quiet chat-server && echo "[start] Chat server UP na porta 59001"