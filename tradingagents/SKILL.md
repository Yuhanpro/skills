---
name: tradingagents
description: Run the TauricResearch/TradingAgents multi-agent LLM trading research framework. Use when the user wants a TradingAgents-style debate-based analysis on a ticker (analysts → bull/bear research → trader → risk management → portfolio manager), launches the interactive CLI, or programmatically calls TradingAgentsGraph. Triggers include "TradingAgents", "用 TradingAgents 分析", "run TradingAgents on a ticker", "trading agents debate", "multi-agent trading analysis".
---

# TradingAgents

TauricResearch's open-source multi-agent LLM trading research framework, installed locally and wrapped as a skill. This is **research only — not financial advice**.

## Where it lives

- Repo: `%USERPROFILE%\projects\TradingAgents`
- Python: managed by `uv`, virtualenv at `.venv` (Python 3.12)
- `uv` binary: `%USERPROFILE%\AppData\Local\Microsoft\WinGet\Packages\astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe\uv.exe`
  - Prefer using `uv run ...` from inside the repo so the venv is auto-activated. After `winget` PATH refresh in a new shell, plain `uv` works.
- Env file: `%USERPROFILE%\projects\TradingAgents\.env` (copied from `.env.example`). **API keys must be filled here before any run.**
- Persistent decision log (always on): `~\.tradingagents\memory\trading_memory.md`

## API key requirements

`.env` lists every supported provider — only fill the one(s) you actually use. Common picks:

- `OPENAI_API_KEY` — default in the framework's DEFAULT_CONFIG
- `ANTHROPIC_API_KEY` — Claude models
- `GOOGLE_API_KEY` — Gemini
- `DEEPSEEK_API_KEY`, `ZHIPU_CN_API_KEY` (GLM), `DASHSCOPE_CN_API_KEY` (Qwen) — common CN providers
- `OPENROUTER_API_KEY` — meta-router

Data sources (Yahoo Finance for tickers) need no key. Alpha Vantage is optional.

Before running, check if `.env` has at least one provider key set — if all are empty, tell the user and stop. Do NOT invent keys.

## How to invoke

### 1) Interactive CLI (default; recommended for first runs)

Walks the user through ticker → date → provider → models → debate depth → language.

```powershell
cd %USERPROFILE%\projects\TradingAgents
uv run tradingagents
```

Flags:
- `--checkpoint` — save state after each node so a crashed run can resume (per-ticker SQLite under `.tradingagents/checkpoints/`)
- `--clear-checkpoints` — wipe checkpoints and start fresh

### 2) Non-interactive via env vars (good for scripting / unattended)

Set `TRADINGAGENTS_*` env vars to skip the interactive prompts. The CLI still runs but won't ask for the selections you've pre-set.

```powershell
$env:TRADINGAGENTS_LLM_PROVIDER     = "openai"
$env:TRADINGAGENTS_DEEP_THINK_LLM   = "gpt-5.4"
$env:TRADINGAGENTS_QUICK_THINK_LLM  = "gpt-5.4-mini"
$env:TRADINGAGENTS_MAX_DEBATE_ROUNDS= "1"
$env:TRADINGAGENTS_TEMPERATURE      = "0.0"
$env:TRADINGAGENTS_OUTPUT_LANGUAGE  = "Chinese"
cd %USERPROFILE%\projects\TradingAgents
uv run tradingagents
```

The full list of overridable keys lives in `tradingagents\default_config.py`. Any `TRADINGAGENTS_<KEY>` env var replaces the matching `default_config` key (coerced to the existing type).

### 3) Python API

For programmatic use / integration into other scripts:

```powershell
cd %USERPROFILE%\projects\TradingAgents
uv run python -c "from tradingagents.graph.trading_graph import TradingAgentsGraph; from tradingagents.default_config import DEFAULT_CONFIG; ta = TradingAgentsGraph(debug=True, config=DEFAULT_CONFIG.copy()); _, decision = ta.propagate('NVDA', '2026-01-15'); print(decision)"
```

Config knobs (pass via `DEFAULT_CONFIG.copy()` then mutate):
- `llm_provider`, `deep_think_llm`, `quick_think_llm`, `backend_url`
- `max_debate_rounds`, `max_risk_discuss_rounds`
- `temperature`
- `output_language`

## Tickers

Yahoo Finance-style symbols: `NVDA`, `AAPL` (US); `0700.HK` (HK); `7203.T` (Tokyo); `600519.SS` / `000001.SZ` (China A); `BTC-USD` (crypto). The ticker prompt's help text in the CLI lists more.

## Reproducibility caveat

LLM sampling is non-deterministic and live data shifts intraday, so two runs on the same ticker/date can differ. To minimize drift, set `TRADINGAGENTS_TEMPERATURE=0.0` and pick a non-reasoning model (e.g. `gpt-4.1` style). The README is explicit that no setting makes output fully deterministic.

## Updating

```powershell
cd %USERPROFILE%\projects\TradingAgents
git pull
uv sync --python 3.12
```

If `uv sync --frozen` (using the committed `uv.lock`) fails on Windows with a `cffi`/`zstandard` MSVC build error, drop `--frozen` so uv can pick wheels-available versions (this is how it was installed initially — Python 3.13 + the locked `cffi==1.17.0rc1` had no wheel; 3.12 + a stable cffi does).

## What to do when the user asks for an analysis

1. Confirm `.env` has the relevant provider key set. If not, tell the user which `*_API_KEY` to fill in `%USERPROFILE%\projects\TradingAgents\.env` and stop.
2. Ask which ticker, date (default = today), and provider (default = OpenAI) if not given.
3. Prefer the **interactive CLI** for the user's first run (they see the agent debate live).
4. For unattended / scripted runs, use the env-var path or the Python API.
5. Surface the final decision and where the persistent memory log was updated.
