# Ark / Fangzhou Claude Code Reference

## What To Tell The User

For Volcengine Ark / Fangzhou Coding Plan, do not choose any item in Claude Code's login menu. Press `Ctrl+C` and configure environment variables instead.

The login menu's third-party option is only for Amazon Bedrock, Microsoft Foundry, or Vertex AI.

## Windows Setup Commands

Non-secret variables:

```powershell
[Environment]::SetEnvironmentVariable('ANTHROPIC_BASE_URL','https://ark.cn-beijing.volces.com/api/coding','User')
[Environment]::SetEnvironmentVariable('ANTHROPIC_MODEL','glm-5.1','User')
[Environment]::SetEnvironmentVariable('CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC','1','User')
```

Token prompt:

```powershell
$secure = Read-Host 'API Key' -AsSecureString
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try { $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
[Environment]::SetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN', $token.Trim(), 'User')
```

Current-process reload for immediate testing:

```powershell
$env:ANTHROPIC_BASE_URL=[Environment]::GetEnvironmentVariable('ANTHROPIC_BASE_URL','User')
$env:ANTHROPIC_MODEL=[Environment]::GetEnvironmentVariable('ANTHROPIC_MODEL','User')
$env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=[Environment]::GetEnvironmentVariable('CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC','User')
$env:ANTHROPIC_AUTH_TOKEN=[Environment]::GetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN','User')
```

Smoke tests:

```powershell
claude -p "Reply with exactly: ark-ok"
claude -p "Reply with exactly: glm-ok"
```

## Known Working Values From This Setup

- Base URL: `https://ark.cn-beijing.volces.com/api/coding`
- Default model used first: `ark-code-latest`
- GLM 5.1 model: `glm-5.1`
- Successful smoke-test outputs: `ark-ok`, `glm-ok`, `skills-ok`

## Safety

Never display `ANTHROPIC_AUTH_TOKEN`. It is acceptable to report `<set, length N>` or `<missing>`.
