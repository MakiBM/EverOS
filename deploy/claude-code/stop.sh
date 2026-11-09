#!/usr/bin/env bash
# Stop the memory server; the embedding server is left running when other projects may use it,
# unless --embed is given.
root="${EVEROS_ROOT:-$HOME/.everos}"
[ -f "$root/.logs/everos.pid" ] && kill "$(cat "$root/.logs/everos.pid")" 2>/dev/null
rm -f "$root/.logs/everos.pid"
if [ "${1:-}" = "--embed" ]; then
  pkill -f "infinity_emb v2 --model-id BAAI/bge-m3" 2>/dev/null || true
fi
