param(
  [string]$Model = "glm-5.1",
  [string]$BaseUrl = "https://ark.cn-beijing.volces.com/api/coding",
  [switch]$SkipTokenPrompt
)

$ErrorActionPreference = "Stop"

[Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $BaseUrl, "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", $Model, "User")
[Environment]::SetEnvironmentVariable("CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC", "1", "User")

if (-not $SkipTokenPrompt) {
  Write-Host "Paste your Volcengine Ark / Fangzhou Coding Plan API Key." -ForegroundColor Cyan
  Write-Host "Input is hidden and will be saved as the Windows User environment variable ANTHROPIC_AUTH_TOKEN." -ForegroundColor DarkGray

  $secure = Read-Host "API Key" -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }

  $token = $token.Trim()
  if ([string]::IsNullOrWhiteSpace($token)) {
    throw "Empty API Key; ANTHROPIC_AUTH_TOKEN was not saved."
  }

  [Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $token, "User")
  Write-Host ("Saved token length: " + $token.Length) -ForegroundColor Green
}

Write-Host "Configured Claude Code for Ark Coding Plan." -ForegroundColor Green
Write-Host ("ANTHROPIC_BASE_URL=" + $BaseUrl)
Write-Host ("ANTHROPIC_MODEL=" + $Model)
Write-Host "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"

