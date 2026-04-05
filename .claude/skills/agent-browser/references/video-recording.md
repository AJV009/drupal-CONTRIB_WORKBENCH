# Video Recording

Capture browser automation as video for debugging, documentation, or verification.

## Basic Recording

```bash
agent-browser record start ./demo.webm
# ... perform actions ...
agent-browser record stop
```

## Commands

```bash
agent-browser record start ./output.webm     # Start recording
agent-browser record stop                    # Stop current recording
agent-browser record restart ./take2.webm    # Stop current + start new
```

## Use Cases

### Debugging Failed Automation

```bash
agent-browser record start ./debug-$(date +%Y%m%d-%H%M%S).webm
agent-browser open https://app.example.com
agent-browser snapshot -i
agent-browser click @e1 || {
    echo "Click failed - check recording"
    agent-browser record stop
    exit 1
}
agent-browser record stop
```

### CI/CD Test Evidence

```bash
agent-browser record start "./recordings/$TEST_NAME-$(date +%s).webm"
# ... run test ...
agent-browser record stop
```

## Best Practices

1. Add pauses (`agent-browser wait 500`) for human viewing clarity
2. Use descriptive filenames with date/context
3. Cleanup in error cases with `trap`
4. Combine with screenshots for key frames

## Output Format

- WebM (VP8/VP9 codec)
- Compatible with all modern browsers and video players
