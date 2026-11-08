#!/bin/sh
# Health check: H2 must accept the application credentials and answer a query over TCP.
# An open port is not enough. Exit code 0 = healthy, anything else = unhealthy.
if [ -n "${H2_PASSWORD_FILE:-}" ]; then
  H2_PASSWORD=$(cat "$H2_PASSWORD_FILE")
fi
exec java -Xmx64m -cp /opt/h2/h2.jar org.h2.tools.Shell \
  -url "jdbc:h2:tcp://127.0.0.1:${H2_PORT}/${H2_DB_NAME}" \
  -user "$H2_USER" -password "$H2_PASSWORD" -sql "SELECT 1" > /dev/null 2>&1
