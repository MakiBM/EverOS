# EverOS for Claude Code (Anthropic API, local embeddings)

Memory for Claude Code agents: EverOS keeps it as markdown under `~/.everos`; the agent reads and
writes it itself through EverOS's own MCP server (`everos-mcp`: `get_profile`, `add_memory`,
`search_memory`, `list_memories`, `record_trajectory`, `recall_agent_experience`,
`forget_session`), following the instructions that server gives the agent. Nothing else is
added to Claude Code.

This fork (`github.com/MakiBM/EverOS`, branch `claude-code`) adds three model capabilities to
`[llm]`, `[decider]` and `[multimodal]`, all needed by Anthropic's OpenAI-compatible endpoint:

| setting | why |
|---|---|
| `temperature_supported = false` | every Claude 5.5 model answers HTTP 400 to `temperature` |
| `recursive_schemas_supported = false` | the endpoint rejects a self-referring strict schema (the knowledge topic tree) |
| `pdf_input_supported = false` | the endpoint takes images but no PDF: pages go as PNG images |

## What runs

| process | port | memory |
|---|---|---|
| `everos server start` (memory server) | 127.0.0.1:8000 | about 0.5 GB |
| `infinity_emb` (bge-m3 embeddings + bge-reranker-v2-m3 rerank, CPU) | 127.0.0.1:7997 | about 4 GB; the first start downloads about 4.5 GB of weights |
| `everos-mcp` (started by Claude Code over stdio) | none | small |

The embedding server can be one for every project: install with
`EVEROS_EMBED_URL=http://<host>:7997` and the project uses that one instead of its own.

Models: `claude-haiku-5-5` for extraction, retrieval decisions and images (the Anthropic API key,
billed per use; measured 2026-11-09 against `claude-opus-5-5` on the same inputs: the same facts,
profile, case, skill and search hits, at a fortieth of the price per token). Embeddings and rerank
never leave the machine.

## Install (in the project directory)

```bash
deploy/claude-code/install.sh          # tools, ~/.everos config, the Claude Code MCP entry (local scope)
```

Options through the environment: `EVEROS_ROOT`, `EVEROS_REF`, `EVEROS_USER_ID` (owner of the
operator's memories), `EVEROS_APP_ID` (this project's scope, default the directory name),
`EVEROS_EMBED_URL`. `--no-mcp` skips `claude mcp add`.

## Start, check, stop

```bash
ANTHROPIC_API_KEY="$(op read op://<project vault>/<item>/credential)" ~/.everos/start.sh
~/.everos/health.sh     # "everos 1.6.0 ok" when every capability is on and nothing is disabled
~/.everos/stop.sh       # --embed also stops the embedding server
```

The key is never written to a file: `start.sh` hands it to the server process only. Start the
server before Claude Code sessions (for example from the container's on-work service start) and
keep it running while they work.

## Verified (2026-11-09, sandbox)

All capabilities on, no disabled feature; conversation memory (episode, atomic facts, profile) in
Polish (the fork keeps a Polish conversation in Polish; upstream wrote it in Spanish); search by hybrid, vector, keyword and agentic methods; a recorded agent trajectory became
an agent case and a skill (`skills/skill_*/SKILL.md`), returned by `recall_agent_experience`
through MCP; weekly reflection run by hand (`POST /api/v2/ome/trigger reflect_episodes`);
a knowledge document split into topics and found by search; an image and a PDF in one message,
the PDF's text found by search.

## Not covered

- Audio messages: Claude has no audio input, so the parser cannot read them.
- Office documents (DOCX, XLSX, PPTX): EverOS converts them with LibreOffice (`soffice` on
  PATH), which is not part of this install.
