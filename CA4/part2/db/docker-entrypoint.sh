#!/bin/sh
# Creates the database once (with the application credentials) and starts H2 in TCP server mode.
set -eu

# The password can come from H2_PASSWORD or from a file (Docker/Podman secrets): H2_PASSWORD_FILE
if [ -n "${H2_PASSWORD_FILE:-}" ]; then
  H2_PASSWORD=$(cat "$H2_PASSWORD_FILE")
fi
: "${H2_USER:?H2_USER is required}"
: "${H2_PASSWORD:?H2_PASSWORD (or H2_PASSWORD_FILE) is required}"

H2="java ${H2_JAVA_OPTS:-} -cp /opt/h2/h2.jar"
DB_FILE="$H2_DATA_DIR/$H2_DB_NAME.mv.db"

# The server runs WITHOUT -ifNotExists: remote clients can never create databases.
# So the database is created here, locally, the first time the volume is empty.
if [ ! -f "$DB_FILE" ]; then
  echo "[db] Creating database '$H2_DB_NAME' (user '$H2_USER') in $H2_DATA_DIR"
  $H2 org.h2.tools.Shell -url "jdbc:h2:$H2_DATA_DIR/$H2_DB_NAME" \
      -user "$H2_USER" -password "$H2_PASSWORD" -sql "SELECT 1" > /dev/null
else
  echo "[db] Database '$H2_DB_NAME' already exists in $H2_DATA_DIR"
fi

echo "[db] Starting H2 TCP server on port $H2_PORT"
# exec: Java becomes PID 1 and receives the SIGTERM from "docker stop" (clean shutdown)
exec $H2 org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort "$H2_PORT" -baseDir "$H2_DATA_DIR"
