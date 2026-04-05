# Snapshot and Refs

Compact element references that reduce context usage dramatically for AI agents.

## How Refs Work

Traditional approach:
```
Full DOM/HTML -> AI parses -> CSS selector -> Action (~3000-5000 tokens)
```

agent-browser approach:
```
Compact snapshot -> @refs assigned -> Direct interaction (~200-400 tokens)
```

## The Snapshot Command

```bash
agent-browser snapshot            # Full accessibility tree
agent-browser snapshot -i         # Interactive elements only (RECOMMENDED)
agent-browser snapshot -c         # Compact output
agent-browser snapshot -d 3       # Limit depth to 3
agent-browser snapshot -s "#main" # Scope to CSS selector
```

### Output Format

```
Page: Example Site - Home
URL: https://example.com

@e1 [header]
  @e2 [nav]
    @e3 [a] "Home"
    @e4 [a] "Products"
    @e5 [a] "About"
  @e6 [button] "Sign In"

@e7 [main]
  @e8 [h1] "Welcome"
  @e9 [form]
    @e10 [input type="email"] placeholder="Email"
    @e11 [input type="password"] placeholder="Password"
    @e12 [button type="submit"] "Log In"
```

## Using Refs

```bash
agent-browser click @e6              # Click the "Sign In" button
agent-browser fill @e10 "user@example.com"  # Fill email input
agent-browser fill @e11 "password123"       # Fill password
agent-browser click @e12                    # Submit the form
```

## Ref Lifecycle

**IMPORTANT**: Refs are invalidated when the page changes!

```bash
agent-browser snapshot -i       # @e1 [button] "Next"
agent-browser click @e1         # Triggers page change
agent-browser snapshot -i       # MUST re-snapshot! @e1 is now different
agent-browser click @e1         # Use new refs
```

## Best Practices

1. **Always snapshot before interacting** - refs don't exist until you snapshot
2. **Re-snapshot after navigation** - page changes invalidate all refs
3. **Re-snapshot after dynamic changes** - dropdowns, modals, AJAX loads
4. **Snapshot specific regions** for complex pages: `agent-browser snapshot @e5`

## Iframes

Snapshots automatically inline iframe content. Refs inside iframes carry frame context, so interactions work without manually switching frames.

```bash
agent-browser snapshot -i
# @e2 [Iframe] "payment-frame"
#   @e3 [input] "Card number"
#   @e4 [button] "Pay"

agent-browser fill @e3 "4111111111111111"  # Works directly
agent-browser click @e4
```

Only one level of iframe nesting is expanded. Cross-origin iframes that block accessibility tree access are silently skipped.

## Ref Notation

```
@e1 [tag type="value"] "text content" placeholder="hint"
|    |   |             |               |
|    |   |             |               +- Additional attributes
|    |   |             +- Visible text
|    |   +- Key attributes shown
|    +- HTML tag name
+- Unique ref ID
```

## Troubleshooting

- **"Ref not found"**: Page changed since last snapshot. Re-snapshot.
- **Element not visible**: Scroll down (`agent-browser scroll down 1000`) then re-snapshot.
- **Too many elements**: Scope the snapshot (`agent-browser snapshot -s "#main"`) or use `get text`.
