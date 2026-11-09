#!/usr/bin/env bash
# The local embedding and rerank server (bge-m3 + bge-reranker-v2-m3, CPU, about 4 GB RAM; the
# first start downloads about 4.5 GB of weights). One such server can serve every project.
set -euo pipefail
port="${EVEROS_EMBED_PORT:-7997}"
logs="${EVEROS_ROOT:-$HOME/.everos}/.logs"
mkdir -p "$logs"
curl -fs -m 2 "http://127.0.0.1:${port}/health" >/dev/null && exit 0
INFINITY_ANONYMOUS_USAGE_STATS=0 DO_NOT_TRACK=1 nohup nice -n 10 infinity_emb v2 \
  --model-id BAAI/bge-m3 --model-id BAAI/bge-reranker-v2-m3 \
  --host 127.0.0.1 --port "$port" >> "$logs/embed.log" 2>&1 &
for _ in $(seq 1 600); do
  curl -fs -m 2 "http://127.0.0.1:${port}/health" >/dev/null && exit 0
  sleep 2
done
echo "embedding server did not start, see $logs/embed.log" >&2
exit 1
