#!/usr/bin/env bash
# Exit 0 when the memory server runs with every capability (LLM, embedding, rerank, multimodal)
# and no feature is disabled; prints what is missing otherwise.
curl -fs -m 5 http://127.0.0.1:8000/health | python3 -c '
import json, sys
h = json.load(sys.stdin)
missing = [k for k, v in h["capabilities"].items() if not v] + h.get("disabled_features", [])
print("everos", h["version"], "ok" if not missing else "missing: " + ", ".join(missing))
sys.exit(1 if missing else 0)'
