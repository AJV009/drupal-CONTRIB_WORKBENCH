# Authentication Patterns

Login flows, session persistence, OAuth, 2FA, and authenticated browsing.

## Import Auth from Your Browser

The fastest way to authenticate: reuse cookies from a Chrome session you are already logged into.

```bash
# 1. Start Chrome with remote debugging
google-chrome --remote-debugging-port=9222

# 2. Log in normally, then grab the auth state
agent-browser --auto-connect state save ./my-auth.json

# 3. Reuse in automation
agent-browser --state ./my-auth.json open https://app.example.com/dashboard
```

> State files contain session tokens in plaintext. Add to `.gitignore` and set `AGENT_BROWSER_ENCRYPTION_KEY` for encryption at rest.

## Persistent Profiles

```bash
# First run: login once
agent-browser --profile ~/.myapp-profile open https://app.example.com/login

# All subsequent runs: already authenticated
agent-browser --profile ~/.myapp-profile open https://app.example.com/dashboard
```

## Session Persistence

```bash
# Auto-saves state on close, auto-restores on next launch
agent-browser --session-name twitter open https://twitter.com
agent-browser close  # state saved to ~/.agent-browser/sessions/

# Next time: state is automatically restored
agent-browser --session-name twitter open https://twitter.com
```

## Basic Login Flow

```bash
agent-browser open https://app.example.com/login
agent-browser wait --load networkidle
agent-browser snapshot -i
# @e1 [input type="email"], @e2 [input type="password"], @e3 [button] "Sign In"

agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser get url  # Should be dashboard, not login
```

## Saving / Restoring Authentication State

```bash
# After logging in:
agent-browser state save ./auth-state.json

# In a future session:
agent-browser state load ./auth-state.json
agent-browser open https://app.example.com/dashboard
```

## OAuth / SSO Flows

```bash
agent-browser open https://app.example.com/auth/google
agent-browser wait --url "**/accounts.google.com**"
agent-browser snapshot -i
agent-browser fill @e1 "user@gmail.com"
agent-browser click @e2
agent-browser wait 2000
agent-browser snapshot -i
agent-browser fill @e3 "password"
agent-browser click @e4
agent-browser wait --url "**/app.example.com**"
agent-browser state save ./oauth-state.json
```

## Two-Factor Authentication

```bash
agent-browser open https://app.example.com/login --headed  # Show browser
agent-browser snapshot -i
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
# Wait for user to complete 2FA manually
echo "Complete 2FA in the browser window..."
agent-browser wait --url "**/dashboard" --timeout 120000
agent-browser state save ./2fa-state.json
```

## HTTP Basic Auth

```bash
agent-browser set credentials username password
agent-browser open https://protected.example.com/api
```

## Cookie-Based Auth

```bash
agent-browser cookies set session_token "abc123xyz"
agent-browser open https://app.example.com/dashboard
```

## Token Refresh Handling

```bash
STATE_FILE="./auth-state.json"
if [[ -f "$STATE_FILE" ]]; then
    agent-browser state load "$STATE_FILE"
    agent-browser open https://app.example.com/dashboard
    URL=$(agent-browser get url)
    if [[ "$URL" == *"/login"* ]]; then
        echo "Session expired, re-authenticating..."
        # Perform fresh login...
        agent-browser state save "$STATE_FILE"
    fi
fi
```

## Security Best Practices

1. Never commit state files (they contain session tokens)
2. Use environment variables for credentials
3. Clean up after automation: `agent-browser cookies clear`
4. Use short-lived sessions for CI/CD
