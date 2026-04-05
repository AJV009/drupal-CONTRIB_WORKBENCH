# Profiling

Capture Chrome DevTools performance profiles during browser automation.

## Basic Profiling

```bash
agent-browser profiler start
# ... perform actions ...
agent-browser profiler stop ./trace.json
```

## Custom Categories

```bash
agent-browser profiler start --categories "devtools.timeline,v8.execute,blink.user_timing"
```

Default categories: `devtools.timeline`, `v8.execute`, `blink`, `blink.user_timing`, `latencyInfo`, `renderer.scheduler`, `toplevel`.

## Viewing Profiles

- Chrome DevTools: Performance panel > Load profile
- Perfetto UI: https://ui.perfetto.dev/
- Trace Viewer: `chrome://tracing`

## Limitations

- Chromium-only (Chrome, Edge)
- 5M event cap while profiling
- 30s timeout on stop command
