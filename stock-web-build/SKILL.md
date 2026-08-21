---
name: stock-web-build
description: |
  Continue or recover the stock-web project build. Use when working on
  E:\code\projects\stock-web (or the compatibility junction
  %USERPROFILE%\projects\stock-web), when updating its GitHub repo
  Yuhanpro/Multi-agent-stock-analysis-demo, when creating GitHub issues with
  Chinese text, or when recalling the build/deploy decisions from 2026-06-16.
  Covers: architecture, completed 9-task buildout, DeepSeek V4 model split,
  SSE-over-POST, TradingAgents stream quirks, PowerShell/gh UTF-8 pitfalls,
  SSH setup, E:\code migration, and README work-log policy.
---

# stock-web build recovery skill

## Current project location

Primary working path now:

```powershell
E:\code\projects\stock-web
```

Compatibility path still works via junction:

```powershell
%USERPROFILE%\projects  ->  E:\code\projects
%USERPROFILE%\projects\stock-web  ->  E:\code\projects\stock-web
```

Claude-related convenience junctions:

```powershell
E:\code\claude\skills   -> %USERPROFILE%\.claude\skills
E:\code\claude\plans    -> %USERPROFILE%\.claude\plans
E:\code\claude\memory   -> %USERPROFILE%\.claude\projects\C--Users-fuyuh\memory
E:\code\claude\plugins  -> %USERPROFILE%\.claude\plugins
E:\code\claude\settings -> %USERPROFILE%\.claude
```

Before doing heavy work, prefer `E:\code\...` paths in new commands. Old C:
paths remain valid, but do not create new projects under C: unless the user
explicitly asks.

---

## Canonical repo

GitHub:

```text
https://github.com/Yuhanpro/Multi-agent-stock-analysis-demo
```

Local git remote should be SSH, not HTTPS:

```powershell
git remote -v
# origin  git@github.com:Yuhanpro/Multi-agent-stock-analysis-demo.git
```

SSH was configured on 2026-06-17:

- key: `~/.ssh/id_ed25519`
- public key label/comment: `github-fuyuh-stock-web`
- verified with: `ssh -T git@github.com` → `Hi Yuhanpro! You've successfully authenticated`

If GitHub push hangs, check credential state only after confirming remote did
not accidentally switch back to HTTPS.

---

## What shipped on 2026-06-16

All 9 build tasks completed:

1. repo scaffold (`backend/` + `frontend/` + `.gitignore`)
2. FastAPI backend + `/healthz` + `/api/snapshot`
3. Buffett skill runner + `/api/quick` SSE
4. TradingAgents LangGraph runner + `/api/debate` SSE
5. custom per-IP rate-limit + daily budget gate
6. Next.js frontend skeleton + snapshot chart
7. SSE-over-POST client + Quick/Debate streaming UI
8. real LLM e2e validation (Quick zh/en, Debate zh)
9. bare systemd + nginx deployment scaffolding (no Docker)

See README `## 工作日志` and `docs/PLAN.md` for details. Keep README work log
updated daily in Chinese.

---

## Architecture reminders

### Backend

- FastAPI + Python 3.12 + uv
- `backend/app/routes/snapshot.py` — pure data, no LLM
- `backend/app/routes/quick.py` — Buffett prompt → DeepSeek V4-Flash, token SSE
- `backend/app/routes/debate.py` — TradingAgents multi-agent debate → DeepSeek V4-Pro, agent-level SSE
- `backend/app/services/skill_runner.py` — loads `app/prompts/buffett/` into one
  158k-char system prompt + API Mode Adapter
- `backend/app/services/tradingagents_runner.py` — diffs LangGraph
  `stream_mode="values"` snapshots, emits `agent_start / agent_complete /
  debate_turn / final / done`
- `backend/app/services/rate_limit.py` — custom limiter called after ticker
  validation; do not reintroduce slowapi decorators
- `backend/app/services/budget.py` — daily USD cap via Redis or memory fallback

### Frontend

- Next.js 14, Tailwind 3, `output: "export"`
- runtime is static nginx; no Node server in production
- `frontend/lib/sse.ts` is a hand parser because browser `EventSource` is GET-only
- `frontend/lib/i18n.tsx` is the bilingual dictionary (EN/中文); no i18next
- `frontend/components/debate-stream.tsx` owns the final hero conclusion card

### Deploy

Bare-metal, no Docker:

- `deploy/setup-server.sh` — one-time VPS bootstrap
- `deploy/install.sh` — idempotent deploy / rebuild / restart
- `deploy/stock-web-backend.service` — systemd backend
- `deploy/nginx.conf` — static frontend + SSE reverse proxy on port 8080
- `DEPLOY.md` — Stage A IP soft launch, Stage B ICP + HTTPS

#### Production VPS access (Stage A — live)

- Public URL: `http://<SERVER_IP>:18080`
- Login as **`admin@<SERVER_IP>`** (NOT root — root key login is refused), using
  the same `~/.ssh/id_ed25519` key (added to admin's `authorized_keys`).
  Passwordless `sudo` works. Alibaba Cloud Linux 3, 1.8Gi RAM + 2Gi swap.
- Code lives at `~/stock-web` (deploy source, **tarball-deployed, NOT a git
  clone**) and `/opt/stock-web` (where the service runs). `~/stock-web/.env`
  holds secrets — never overwrite it (extract tarballs WITHOUT `rm -rf` first).
- **Proxy-503 gotcha**: the admin shell has leftover OpenClaw `HTTP_PROXY` /
  `ALL_PROXY` env vars, so `curl http://127.0.0.1:8000/healthz` returns an empty
  `503` (proxy, not uvicorn). Use `curl --noproxy "*"` on the server, or verify
  from your own machine against the public `:18080` URL. The app is fine.

#### Update procedure (memory-constrained box)

`install.sh` runs `npm run build` on the server, which risks OOM on 1.8Gi
(openclaw-gateway alone eats ~640MB). Preferred split:

- **Backend-only** (no npm): `package.ps1` → `scp` tarball → on server
  `tar -xzf` over `~/stock-web` (keep .env) → `sudo rsync -a --exclude .venv
  --exclude data ~/stock-web/backend/ /opt/stock-web/backend/` → `sudo chown -R
  stockweb:stockweb /opt/stock-web/backend` → `sudo systemctl restart
  stock-web-backend`. (`/opt/.../.venv` exists, so a full `install.sh` skips
  `uv sync` anyway — fine when no new deps.)
- **Frontend**: build LOCALLY (`NEXT_PUBLIC_API_BASE=http://<SERVER_IP>:18080
  npm run build` → `frontend/out/`), tar + scp, then `sudo rsync -a --delete`
  into `/var/www/stock-web`, chown to nginx/www-data, `sudo nginx -t &&
  systemctl reload nginx`. Avoids server-side npm build entirely.
- git-bash gotcha: `tar`/`scp` read `C:/...` as a remote host (the colon). Use
  msys paths like `/c/Users/...` for local files.

#### Account system + data persistence (added 2026-06-24)

- Email+password accounts, saved reports, and the (now per-user) watchlist live
  in **SQLite at `backend/data/stock-web.db`** (stdlib `sqlite3`, no new pip
  dep — keeps deploys rsync+restart). JWT signing secret persists at
  `backend/data/.jwt_secret`. Auth = `pbkdf2_hmac` password hash + `hmac`-signed
  Bearer token (`app/services/auth.py`). Routes: `/api/auth/{register,login,me}`,
  `/api/reports`, per-user `/api/watchlist`.
- **DEPLOY INVARIANT — never wipe `backend/data/`**: it holds the user DB + JWT
  secret. The backend rsync MUST `--exclude data/` (install.sh already does, line
  ~39). Wiping it logs everyone out and deletes all accounts/reports. When
  extracting a tarball over `~/stock-web`, do NOT `rm -rf` first.
- Frontend talks to the API same-origin in prod (nginx serves both on :18080),
  so the Bearer token needs no CORS credentials. Token is in localStorage.

#### Financials data layer (added 2026-06-24)

- `app/services/financials.py` provides curated multi-period statements
  (income/balance/cash-flow core line items × ~5 annual + recent quarters +
  ratios), cached 6h, feeding the agents. `GET /api/financials?ticker&market`.
- Sources: **US** = yfinance (full 3 statements) with `stock_financial_us_analysis_indicator_em`
  fallback; **CN** = `stock_financial_abstract` (Sina — reliable on VPS; totals
  derived from equity + debt ratio); **HK** = `stock_financial_hk_analysis_indicator_em`
  + `stock_financial_hk_report_em`.
- **VPS reality**: yfinance gets 429'd on the Aliyun box, so US falls back to
  akshare EM. The fallback now pulls the FULL three statements via
  `stock_financial_us_report_em` (综合损益表/资产负债表/现金流量表, 年报) — so US is
  comprehensive on the VPS too (total assets/equity/cash/OCF/capex/FCF + ratios;
  FCF = OCF − |capex| since EM capex is a negative outflow). CN/HK full. EM
  endpoints DO work from the mainland VPS (earlier RemoteDisconnected was transient).
- Wired into all three agent chains: Quick/Serenity via
  `skill_runner._format_snapshot_for_prompt` + `format_for_prompt(financials)`;
  TradingAgents via a `("human", <financials brief>)` message appended to
  `init_state["messages"]` after `create_initial_state` (zero vendored-file
  edits — TA's own data tools are US-centric/weak for CN/HK).

---

## Model facts (avoid repeating the V3 mistake)

DeepSeek model split now:

```text
QUICK_THINK_LLM = deepseek-v4-flash
DEEP_THINK_LLM  = deepseek-v4-pro
```

Important: `deepseek-chat` is a legacy alias mapping to V4-Flash non-thinking
mode and is deprecated after 2026-07-24. Do not describe the project as using
DeepSeek V3. Say **DeepSeek V4**.

Quick should stay on Flash. Debate deep-think should use Pro.

---

## Known pitfalls and fixes

### 1. TradingAgents + DeepSeek provider

Do **not** configure TradingAgents as:

```python
llm_provider = "openai"
backend_url = "https://api.deepseek.com"
```

That triggers `langchain_openai`'s OpenAI Responses API path (`/v1/responses`),
which DeepSeek does not implement → HTTP 404.

Use:

```python
llm_provider = "deepseek"
deep_think_llm = "deepseek-v4-pro"
quick_think_llm = "deepseek-v4-flash"
```

TradingAgents' built-in DeepSeek client handles the OpenAI-compatible chat
completion endpoint correctly.

### 2. TradingAgents stream shape

`graph.propagator.get_graph_args()` returns `stream_mode="values"`.
Each chunk is a **full state snapshot**, not a `{node: delta}` update.
Translate by diffing successive snapshots.

The debate is not token-level streaming; it is milestone/agent-level streaming.
Show spinners per agent, then render the whole report when the state field fills.

### 3. sse-starlette formatting

When using `EventSourceResponse`, yield dictionaries:

```python
yield {"event": event, "data": json.dumps(data, ensure_ascii=False)}
```

Do not yield preformatted strings (`event: ...\ndata: ...\n\n`), or
sse-starlette will double-wrap them as `data: event: ...`.

### 4. PowerShell + gh CLI + Chinese text

PowerShell 5.1 defaults to GBK. If using `gh issue create` / `gh pr create`
with Chinese bodies:

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$body = "中文内容..."
$body | & "C:\Program Files\GitHub CLI\gh.exe" issue create --repo R --title T --body-file -
```

Do not use `--body "中文..."`. Do not write a `.ps1` file via the Write tool
and run it unless it is UTF-8 BOM; PowerShell 5.1 reads no-BOM scripts as GBK.

This is also recorded in memory: `stock-web-github-cli-utf8`.

### 5. Git credential helper pitfall

PortableGit on this machine had `credential.helperselector.selected=manager`
left over, but no Git Credential Manager binary. Push hung because the helper
selector tried to open an interactive prompt in a non-interactive shell.

Fix applied:

```powershell
git config --global --unset credential.helperselector.selected
git config --global credential.helper wincred
```

Then remote was switched to SSH, so HTTPS credentials should no longer matter.

### 6. yfinance NaN tail row

`yfinance.Ticker(...).history(period="3mo")` can return the current trading
day with `Close=NaN`. `market_data.py` drops rows where Close is NaN using
`if row["Close"] == row["Close"]`. Preserve that guard.

### 7. akshare local proxy issue

Local machine proxy caused eastmoney requests to fail. The issue to verify on
production VPS is tracked on GitHub:

```text
#2 [CN A股] 验证 akshare eastmoney 在国内 VPS 上能否访问
```

---

## GitHub issues created

Open issues currently used as work items:

- `#2` `[CN A股] 验证 akshare eastmoney 在国内 VPS 上能否访问` — `data-source`, `backend`, milestone Stage A
- `#3` `[ICP] 启动域名 + ICP 备案流程` — `deployment`, milestone Stage B
- `#4` `[Stage A] 把 demo 部署到国内 VPS 并验证三种模式` — `deployment`, milestone Stage A
- `#5` `[Stage B] 备案通过后,certbot + Lets-Encrypt 上 HTTPS` — `deployment`, milestone Stage B
- `#6` `[功能] 加第二个 quick 模式:serenity 产业链研究` — `enhancement`, `backend`, `frontend`
- `#7` `[质量] 加自动化测试套件 + CI` — `testing`, `backend`, `frontend`

Use GitHub Issues + Milestones as the GitHub equivalent of GitLab work items.
If the user asks for a board, create a GitHub Project and add these issues.

---

## README work-log policy

User asked: **每日工作更新在 README 上**.

Always update `README.md` `## 工作日志` when doing meaningful work on this
repo. Use Chinese. New entries go on top. Format:

```markdown
### YYYY-MM-DD — 一句话总结

交付内容:

- ...

阻塞项 / 遗留:

- ...
```

Then commit it, unless the user says they will commit manually.

---

## E: drive migration details

On 2026-06-17, `%USERPROFILE%\projects` was copied to `E:\code\projects` and
then replaced with a junction:

```text
%USERPROFILE%\projects -> E:\code\projects
```

A backup of the old C directory may exist at:

```text
%USERPROFILE%\projects.c-backup-20260617
```

Do not delete it automatically unless the user confirms E: works and they want
to reclaim C: space.

The reason GitHub repo is much smaller than local project dir:

- `frontend/node_modules` ~300 MB — reproducible via `npm install`
- `backend/.venv` ~264 MB — reproducible via `uv sync`
- `frontend/.next` ~137 MB — build cache
- `TradingAgents/.venv` ~258 MB — reproducible
- actual source/docs/lockfiles ~0.6 MB — what belongs in GitHub

User preference now: **default local code projects to git + GitHub push**.
This is also recorded in memory: `default-github-push-projects`.

---

## Quick commands

```powershell
# work from E: from now on
cd E:\code\projects\stock-web

# backend dev
cd backend
$env:DEEPSEEK_API_KEY = "sk-..."
uv run uvicorn app.main:app --port 8000 --reload

# frontend dev
cd ..\frontend
npm run dev

# git push (SSH)
cd E:\code\projects\stock-web
git push

# issue list
& "C:\Program Files\GitHub CLI\gh.exe" issue list --repo Yuhanpro/Multi-agent-stock-analysis-demo
```
