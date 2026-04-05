# Session Management

Multiple isolated browser sessions with state persistence and concurrent browsing.

## Named Sessions

```bash
agent-browser --session auth open https://app.example.com/login
agent-browser --session public open https://example.com

# Commands are isolated by session
agent-browser --session auth fill @e1 "user@example.com"
agent-browser --session public get text body
```

## Session Isolation Properties

Each session has independent: cookies, localStorage, sessionStorage, IndexedDB, cache, browsing history, open tabs.

## State Persistence

```bash
# Save
agent-browser state save /path/to/auth-state.json

# Restore
agent-browser state load /path/to/auth-state.json
agent-browser open https://app.example.com/dashboard
```

## Common Patterns

### Authenticated Session Reuse

```bash
STATE_FILE="/tmp/auth-state.json"
if [[ -f "$STATE_FILE" ]]; then
    agent-browser state load "$STATE_FILE"
    agent-browser open https://app.example.com/dashboard
else
    agent-browser open https://app.example.com/login
    # ... login flow ...
    agent-browser state save "$STATE_FILE"
fi
```

### Concurrent Sessions

```bash
agent-browser --session site1 open https://site1.com &
agent-browser --session site2 open https://site2.com &
wait
agent-browser --session site1 get text body > site1.txt
agent-browser --session site2 get text body > site2.txt
agent-browser --session site1 close
agent-browser --session site2 close
```

## Cleanup

```bash
agent-browser --session auth close    # Close specific session
agent-browser close --all             # Close all sessions
agent-browser session list            # List active sessions
```

## Best Practices

1. Name sessions semantically (e.g., `github-auth`, not `s1`)
2. Always close sessions when done
3. Never commit state files (they contain auth tokens)
4. Use timeouts for automated scripts: `timeout 60 agent-browser ...`
