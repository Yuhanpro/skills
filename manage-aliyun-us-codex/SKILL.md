---
name: manage-aliyun-us-codex
description: Connect to, inspect, operate, and troubleshoot the user's configured Codex CLI deployment on an Aliyun US ECS server. Use when the user mentions aliyun-us, the US server, remote Codex, SSH access, Codex deployment or version, ChatGPT/OpenAI login status, starting Codex on the server, or repairing this specific server setup.
---

# Manage Aliyun US Codex

Operate the existing Codex CLI installation on the user's Aliyun US server through its SSH alias. Verify live state before reporting that deployment or authentication is working.

## Connection profile

- SSH alias: `aliyun-us`
- Host: `<SERVER_IP>`
- User: `root`
- Local key path: `%USERPROFILE%\Downloads\aliyun-us.pem`
- SSH config path: `%USERPROFILE%\.ssh\config`

Prefer the alias instead of repeating the IP, user, and key:

```powershell
ssh aliyun-us
```

Never print, copy, edit, or expose the private-key contents. Refer only to its path. Do not store OpenAI tokens or `auth.json` in this skill.

## Check current status

Run non-interactive checks before making claims:

```powershell
ssh -o BatchMode=yes -o ConnectTimeout=8 aliyun-us "codex --version"
ssh -o BatchMode=yes -o ConnectTimeout=8 aliyun-us "codex login status"
```

Interpret success only when both commands exit successfully. The last verified state on 2026-07-22 was:

- `codex-cli 0.145.0`
- `Logged in using ChatGPT`

Treat these as historical reference, not guaranteed current state.

## Start Codex

For an interactive session, tell the user to run:

```powershell
ssh aliyun-us
```

Then on the server:

```bash
codex
```

Use `exit` to leave the server. To start Codex directly with a terminal allocated, use:

```powershell
ssh -t aliyun-us codex
```

## Repair connection

If `ssh aliyun-us` does not resolve, inspect the existing SSH config without overwriting unrelated hosts. Ensure it contains:

```sshconfig
Host aliyun-us
    HostName <SERVER_IP>
    User root
    IdentityFile %USERPROFILE%\Downloads\aliyun-us.pem
    IdentitiesOnly yes
```

If authentication fails, confirm that the key file exists and retry with `IdentitiesOnly=yes`. Do not try passwords or expose key material unless the user explicitly changes the authentication method.

## Repair Codex or authentication

Start with read-only diagnostics:

```powershell
ssh aliyun-us "command -v codex"
ssh aliyun-us "codex --version"
ssh aliyun-us "codex login status"
```

If Codex is missing or needs updating, obtain the current official installation instructions through the `openai-docs` skill before changing the server. Ask for approval before installing or updating packages.

For a headless ChatGPT login, run this interactively on the server and have the user complete the displayed browser/device flow:

```bash
codex login --device-auth
```

Then verify with `codex login status`. Do not copy a local `~/.codex/auth.json` to the server.

## Safety

- Treat this as a live server that also hosts a public website.
- Run diagnostics before changes and keep changes scoped to Codex.
- Do not alter Nginx, ports, firewall rules, the deployed website, or unrelated services unless the user explicitly requests it.
- Ask for approval before remote installs, upgrades, configuration edits, restarts, or other state-changing commands.
- Report the command result that supports any claim that Codex is installed, authenticated, or working.
