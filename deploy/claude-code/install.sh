#!/usr/bin/env bash
# Install EverOS for Claude Code: the memory server (this fork), the MCP server, the local
# embedding server, the config, and the MCP entry of the Claude Code project in the current
# directory. Usage: install.sh [--no-mcp]
#   EVEROS_ROOT      memory root (default ~/.everos)
#   EVEROS_REF       git ref of github.com/MakiBM/EverOS to install (default claude-code)
#   EVEROS_USER_ID   owner of the operator's memories (default: $USER)
#   EVEROS_APP_ID    memory scope of this project (default: the directory name)
#   EVEROS_EMBED_URL embedding + rerank server (default http://127.0.0.1:7997; a shared one later)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="${EVEROS_ROOT:-$HOME/.everos}"
ref="${EVEROS_REF:-claude-code}"
user_id="${EVEROS_USER_ID:-$USER}"
app_id="${EVEROS_APP_ID:-$(basename "$PWD")}"
embed_url="${EVEROS_EMBED_URL:-http://127.0.0.1:7997}"
command -v uv >/dev/null || { echo "uv is required: https://docs.astral.sh/uv/" >&2; exit 1; }

uv tool install --force "everos[multimodal] @ git+https://github.com/MakiBM/EverOS@${ref}"
uv tool install --force "everos-mcp==0.1.1"
if [ "$embed_url" = "http://127.0.0.1:7997" ]; then
  uv tool install --force --python 3.12 "infinity-emb[all]==0.0.80"
fi

if [ ! -f "$root/ome.toml" ]; then
  everos init --root "$root" >/dev/null
fi
sed "s|http://127.0.0.1:7997|${embed_url}|" "$here/everos.toml" > "$root/everos.toml"
install -m 0755 "$here/start.sh" "$here/stop.sh" "$here/embed-start.sh" "$here/health.sh" "$root/"

if [ "${1:-}" != "--no-mcp" ]; then
  claude mcp add --scope local everos \
    -e EVEROS_BASE_URL=http://127.0.0.1:8000 \
    -e EVEROS_USER_ID="$user_id" \
    -e EVEROS_APP_ID="$app_id" \
    -- everos-mcp
fi
echo "installed: $root (start with: ANTHROPIC_API_KEY=... $root/start.sh)"
