---
name: claude-ark-coding-plan
description: Configure, repair, or verify Claude Code on Windows to use Volcengine Ark / Fangzhou Coding Plan instead of Claude's built-in login flow. Use when the user mentions Claude Code with 方舟, 火山方舟, Ark Coding Plan, third-party coding plan, ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_MODEL, glm-5.1, ark-code-latest, or asks which Claude Code login option to choose for 方舟. Includes safe API-token handling, model switching, environment-variable setup, and smoke testing with `claude -p`.
---

# Claude Ark Coding Plan

Use this skill to connect Claude Code to Volcengine Ark / Fangzhou Coding Plan on Windows.

## Key Rule

Do not use Claude Code's interactive login menu for Ark / Fangzhou.

If Claude Code shows:

1. Claude account with subscription
2. Anthropic Console account
3. 3rd-party platform: Amazon Bedrock, Microsoft Foundry, or Vertex AI

tell the user to press `Ctrl+C`. Ark / Fangzhou is configured with environment variables, not with these menu options.

## Configuration

Set these user environment variables:

```powershell
ANTHROPIC_BASE_URL=https://ark.cn-beijing.volces.com/api/coding
ANTHROPIC_AUTH_TOKEN=<user's Ark API key>
ANTHROPIC_MODEL=glm-5.1
CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

Use `glm-5.1` when the user asks for GLM 5.1. Use `ark-code-latest` when the user wants Ark's default coding model or has not chosen a model.

Never ask the user to paste the API key into chat. Open a local PowerShell prompt that reads it with `Read-Host -AsSecureString`, or instruct the user to run the command locally.

## Preferred Workflow

1. Check CLI availability and version:

```powershell
claude --version
```

2. Configure non-secret variables:

```powershell
[Environment]::SetEnvironmentVariable('ANTHROPIC_BASE_URL','https://ark.cn-beijing.volces.com/api/coding','User')
[Environment]::SetEnvironmentVariable('ANTHROPIC_MODEL','glm-5.1','User')
[Environment]::SetEnvironmentVariable('CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC','1','User')
```

3. Capture the API key locally without echoing it. Prefer running the bundled script:

```powershell
powershell -ExecutionPolicy Bypass -File "<skill-dir>\scripts\configure-claude-ark.ps1" -Model glm-5.1
```

4. Verify variables without printing the token:

```powershell
$names='ANTHROPIC_BASE_URL','ANTHROPIC_MODEL','CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC','ANTHROPIC_AUTH_TOKEN'
foreach($n in $names){
  $v=[Environment]::GetEnvironmentVariable($n,'User')
  if($n -eq 'ANTHROPIC_AUTH_TOKEN'){
    if([string]::IsNullOrWhiteSpace($v)){"$n=<missing>"}else{"$n=<set, length $($v.Length)>"}
  } else {
    "$n=$v"
  }
}
```

5. Smoke test through Claude Code. In the current shell, load user variables into process variables first:

```powershell
$env:ANTHROPIC_BASE_URL=[Environment]::GetEnvironmentVariable('ANTHROPIC_BASE_URL','User')
$env:ANTHROPIC_MODEL=[Environment]::GetEnvironmentVariable('ANTHROPIC_MODEL','User')
$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=[Environment]::GetEnvironmentVariable('CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC','User')
$env:ANTHROPIC_AUTH_TOKEN=[Environment]::GetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN','User')
claude -p "Reply with exactly: ark-ok"
```

Expected output:

```text
ark-ok
```

If testing GLM 5.1 specifically, use:

```powershell
claude -p "Reply with exactly: glm-ok"
```

## Changing Models

To make a model the default for new terminals:

```powershell
[Environment]::SetEnvironmentVariable('ANTHROPIC_MODEL','glm-5.1','User')
```

For a one-off command:

```powershell
claude --model glm-5.1 -p "Reply with exactly: glm-ok"
```

Inside an interactive Claude Code session, the user can also try:

```text
/model glm-5.1
```

## Troubleshooting

- If `claude auth status` says logged out, that is not necessarily a failure for Ark. Verify with `claude -p` after setting `ANTHROPIC_AUTH_TOKEN` and `ANTHROPIC_BASE_URL`.
- If Claude Code opens the login-method selector, the current terminal probably cannot see the environment variables. Close all terminals, open a new PowerShell, and retry.
- If `ANTHROPIC_AUTH_TOKEN=<missing>`, rerun the local key prompt. The user may have closed the window before pressing Enter.
- If the model fails, switch to `ark-code-latest` and test again. Some model names depend on the user's Ark entitlement.
- Do not print, log, or summarize the API key. Only report whether it is set and its length.

## References

Load `references/ark-claude-code.md` when you need the full command sequence, user-facing instructions, or verification checklist.
