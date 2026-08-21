---
name: web-ui-polish
description: |
  UI/UX polish skill for stock-web and similar public demo websites. Use when
  improving visual hierarchy, responsive layout, bilingual copy, onboarding,
  loading/empty/error states, result-card readability, markdown rendering,
  or investor-demo trust/clarity. Especially suited for
  E:\code\projects\stock-web frontend files (Next.js + Tailwind + SSE UI).
---

# web-ui-polish

Use this skill as a focused UI/UX reviewer and implementer for public-facing
AI demos, especially `stock-web`.

Primary repo:

```text
E:\code\projects\stock-web
```

Compatibility path:

```text
%USERPROFILE%\projects\stock-web -> E:\code\projects\stock-web
```

---

## Core principles

1. **结论先行** — 用户来这里不是为了读长报告,而是想快速知道:
   - 这个股票现在该怎么看?
   - agent 们为什么分歧?
   - 最终结论是什么?
   - 风险/触发条件是什么?
2. **逐层展开** — 顶层必须短,二级能扫,三级才是完整 markdown。
3. **让等待有反馈** — Quick 是 token 级流式; Debate 是 agent 级流式。
   Debate 必须清楚显示哪个 agent 正在跑、哪个已经完成、当前阶段是什么。
4. **中文优先也要保留英文技术名词** — stock-web README 和 UI 已中文化,
   但保留关键英文如 Snapshot / Buffett Quick / Serenity / TradingAgents / SSE。
5. **移动端不能崩** — 朋友很可能用手机打开 `http://<SERVER_IP>:18080`。
6. **研究 demo 而非荐股** — 投资免责声明必须可见,不要把文案写成交易建议。
7. **成本/耗时透明** — LLM 运行时间和估算成本要让用户有心理预期。

---

## Files to inspect first

Frontend:

```text
frontend/app/page.tsx
frontend/app/globals.css
frontend/components/stock-input.tsx
frontend/components/snapshot-card.tsx
frontend/components/quick-result.tsx
frontend/components/debate-stream.tsx
frontend/components/language-switcher.tsx
frontend/lib/i18n.tsx
frontend/lib/sse.ts
frontend/tailwind.config.js
```

Backend only when UI behavior depends on events:

```text
backend/app/routes/quick.py
backend/app/routes/debate.py
backend/app/services/skill_runner.py
backend/app/services/tradingagents_runner.py
```

Docs to preserve:

```text
README.md        # 中文,每日工作日志要更新
docs/PLAN.md
docs/SKILL.md
```

---

## Current UI structure (stock-web)

Top-level page:

- hero eyebrow + headline + lead
- language switcher (EN / 中文)
- mode selector:
  - Snapshot
  - Buffett Quick
  - Serenity Scan
  - Multi-Agent Debate
- stock input (US / CN + ticker + Analyze)
- snapshot chart / fundamentals card
- mode result area:
  - `QuickResult` for Buffett + Serenity
  - `DebateStream` for TradingAgents
- footer disclaimer

Important: `QuickResult` handles token SSE; `DebateStream` handles
agent/milestone SSE.

---

## Review checklist

### 1. Information architecture

- [ ] Is the selected mode visually obvious?
- [ ] Does each mode explain cost/latency clearly?
- [ ] Does the first screen explain what the app does in 5 seconds?
- [ ] Are Snapshot / Quick / Serenity / Debate differentiated enough?
- [ ] Is the final decision obvious without opening collapsed details?

### 2. Loading states

- [ ] Snapshot loading state is visible and not confused with LLM loading
- [ ] Quick has first-token waiting state
- [ ] Debate shows per-agent spinner and current phase pill
- [ ] Long debate has enough feedback every 20-60 seconds
- [ ] Abort/re-run behavior does not leave stale stream UI

### 3. Error states

- [ ] HTTP 429 rate-limit message is human-readable
- [ ] HTTP 500 backend errors do not look like frontend bugs
- [ ] LLM upstream errors show a red box and next action
- [ ] Data-source failures mention whether fallback was tried
- [ ] User can retry without page reload

### 4. Result readability

- [ ] Long markdown has good spacing and tables don't overflow
- [ ] Debate agent reports are collapsed by default
- [ ] Debate turns have short previews and clear speaker labels
- [ ] Final hero verdict is large and color-coded
- [ ] Key facts (Price Target / Stop Loss / Time Horizon / Position) appear as pills
- [ ] Chinese text line-height feels readable

### 5. Responsive layout

- [ ] 360px mobile width works
- [ ] mode selector becomes 1 column or 2 columns sensibly
- [ ] chart width/height works on mobile
- [ ] final hero card doesn't overflow
- [ ] tables/markdown code blocks scroll horizontally when necessary

### 6. Trust and compliance

- [ ] Footer disclaimer visible
- [ ] No wording like “买入这个股票” as app-level recommendation
- [ ] AI outputs are framed as research demo
- [ ] User cost/rate-limit hints are visible enough

---

## Implementation style

- Keep Tailwind classes local and simple. Don't add another UI library unless
  clearly necessary.
- Prefer small components only when it reduces complexity. `debate-stream.tsx`
  is big but cohesive; split only if editing becomes painful.
- Preserve `output: "export"` in `next.config.js` — production is static nginx.
- Do not break `NEXT_PUBLIC_API_BASE` build-time behavior.
- Do not replace `fetch + ReadableStream` SSE parser with `EventSource`.
  `EventSource` cannot POST.
- Avoid adding heavy dependencies; `recharts` and `react-markdown` are already
  the main frontend weight.

---

## Good improvement ideas

High value:

1. **Mode comparison strip** — small chips showing latency/cost:
   - Snapshot: free / 1s
   - Buffett: ~$0.003-0.01 / 30-60s
   - Serenity: ~$0.003-0.01 / 50-80s
   - Debate: ~$0.25 / 3-6min
2. **Progress timeline for Debate** — fixed skeleton of expected stages:
   Analyst → Bull/Bear → Trader → Risk → Final, with completion ticks.
3. **Better final card** — confidence level, action label, target/stop/time
   horizon always visible.
4. **Copy improvements** — public demo should say “研究演示,非投资建议” clearly.
5. **Mobile polish** — mode cards and chart spacing.

Lower priority:

- Theme toggle (not needed; deep blue is intentional)
- User accounts/history (not in scope)
- Full table virtualization (overkill)

---

## Verification steps after UI changes

Local:

```powershell
cd E:\code\projects\stock-web\frontend
npm run build
```

If touching backend event fields:

```powershell
cd E:\code\projects\stock-web\backend
uv run uvicorn app.main:app --port 8000
```

Public smoke (only if server is running):

```powershell
Invoke-WebRequest http://<SERVER_IP>:18080/ -UseBasicParsing
Invoke-RestMethod "http://<SERVER_IP>:18080/api/snapshot?ticker=AAPL&market=US"
Invoke-RestMethod "http://<SERVER_IP>:18080/api/snapshot?ticker=600519&market=CN"
```

Avoid running Quick/Debate unless user agrees to spend DeepSeek budget.
Quick is cheap; Debate costs ~0.25 USD and consumes rate-limit quota.

---

## Work-log requirement

Whenever meaningful UI changes are made, update `README.md` under
`## 工作日志` in Chinese, newest entry on top. Include:

- what shipped
- screenshots/URL if relevant
- what was verified
- what remains open

Then commit and push to GitHub unless user says not to.
