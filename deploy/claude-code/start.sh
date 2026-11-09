#!/usr/bin/env bash
# Start the memory server (and the local embedding server when it is the configured one).
# ANTHROPIC_API_KEY must be set by the caller, e.g. from the project's 1Password vault:
#   ANTHROPIC_API_KEY="$(op read op://<vault>/<item>/credential)" ~/.everos/start.sh
set -euo pipefail
root="${EVEROS_ROOT:-$HOME/.everos}"
: "${ANTHROPIC_API_KEY:?set ANTHROPIC_API_KEY (from the project vault)}"
if grep -q 'base_url = "http://127.0.0.1:7997"' "$root/everos.toml"; then
  "$root/embed-start.sh"
fi
mkdir -p "$root/.logs"
curl -fs -m 2 http://127.0.0.1:8000/health >/dev/null && exit 0
EVEROS_ROOT="$root" EVEROS_LLM__API_KEY="$ANTHROPIC_API_KEY" \
  EVEROS_DECIDER__API_KEY="$ANTHROPIC_API_KEY" EVEROS_MULTIMODAL__API_KEY="$ANTHROPIC_API_KEY" \
  nohup everos server start >> "$root/.logs/everos.log" 2>&1 &
echo $! > "$root/.logs/everos.pid"
for _ in $(seq 1 90); do
  curl -fs -m 2 http://127.0.0.1:8000/health >/dev/null && exec "$root/health.sh"
  sleep 2
done
echo "memory server did not start, see $root/.logs/everos.log" >&2
exit 1
