#!/bin/sh
set -eu
if [ "$#" -gt 0 ]; then
  exec /usr/local/bin/ryu-core "$@"
fi
: "${RYU_WEB_PASSWORD_HASH:?Set a Caddy bcrypt password hash}"
: "${RYU_WEB_ORIGIN:?Set the public HTTPS origin}"
export RYU_BIND=127.0.0.1:7980
core_pid=
web_pid=
stop() {
  trap - TERM INT
  [ -z "$web_pid" ] || kill -TERM "$web_pid" 2>/dev/null || true
  [ -z "$core_pid" ] || kill -TERM "$core_pid" 2>/dev/null || true
  wait || true
}
trap 'stop; exit 0' TERM INT
/usr/local/bin/ryu-core &
core_pid=$!
tries=0
until curl -fsS http://127.0.0.1:7980/api/health >/dev/null 2>&1; do
  if ! kill -0 "$core_pid" 2>/dev/null; then
    wait "$core_pid"
    exit 1
  fi
  tries=$((tries + 1))
  if [ "$tries" -ge 600 ]; then
    stop
    exit 1
  fi
  sleep 1
done
RYU_NODE_AUTH_TOKEN=$(cat "${RYU_DIR:-/data}/secrets/node-auth.token")
export RYU_NODE_AUTH_TOKEN
[ -n "$RYU_NODE_AUTH_TOKEN" ] || { stop; exit 1; }
/usr/local/bin/caddy run --config /etc/ryu/Caddyfile --adapter caddyfile &
web_pid=$!
status=0
wait "$web_pid" || status=$?
stop
exit "$status"
