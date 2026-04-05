# Proxy Support

Proxy configuration for geo-testing, rate limiting avoidance, and corporate environments.

## Basic Configuration

```bash
# Via CLI flag
agent-browser --proxy "http://proxy.example.com:8080" open https://example.com

# Via environment variable
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
agent-browser open https://example.com
```

## Authenticated Proxy

```bash
export HTTP_PROXY="http://username:password@proxy.example.com:8080"
```

## SOCKS Proxy

```bash
export ALL_PROXY="socks5://proxy.example.com:1080"
```

## Proxy Bypass

```bash
agent-browser --proxy-bypass "localhost,*.internal.com" open https://example.com
# Or: export NO_PROXY="localhost,127.0.0.1,.internal.company.com"
```

## Verification

```bash
agent-browser open https://httpbin.org/ip
agent-browser get text body  # Should show proxy's IP
```

## Troubleshooting

- **Connection failed**: Test with `curl -x <proxy> https://httpbin.org/ip` first
- **SSL errors**: Use `--ignore-https-errors` for testing only
- **Slow performance**: Set `NO_PROXY` for CDN domains to bypass proxy
