#!/usr/bin/env bash
# Waits until the H2 TCP port answers. Used before every Bookstore start (systemd ExecStartPre).
# Usage: wait-for-h2.sh <host> <port> [timeout-seconds]
HOST="${1:?host}"
PORT="${2:?port}"
TIMEOUT="${3:-60}"

for i in $(seq 1 "$TIMEOUT"); do
  if timeout 1 bash -c "exec 3<>/dev/tcp/$HOST/$PORT" 2>/dev/null; then
    echo "[wait-for-h2] H2 disponivel em $HOST:$PORT (${i}s)"
    exit 0
  fi
  sleep 1
done
echo "[wait-for-h2] H2 indisponivel em $HOST:$PORT apos ${TIMEOUT}s" >&2
exit 1
