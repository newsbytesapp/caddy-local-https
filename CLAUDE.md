# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a local HTTPS reverse proxy using Caddy in Docker. It provides automatic HTTPS for local `.test` domains on Linux systems where Apache is already running on port 80. Caddy handles only HTTPS (port 443) and proxies requests to Apache on the host machine via `host.docker.internal`.

## Architecture

```
Browser → Caddy (port 443, HTTPS) → host.docker.internal → Apache (port 80) → Backend Services
```

**Critical Design Decisions:**
- **No port 80 mapping**: Apache owns port 80 on the host. Caddy only binds to port 443.
- **Linux-specific `host.docker.internal`**: Requires `extra_hosts: - "host.docker.internal:host-gateway"` in docker-compose.yml (Docker 20.10+)
- **Local CA certificates**: Uses Caddy's `local_certs` directive to generate self-signed certificates

## Core Files

- **`Caddyfile`**: Reverse proxy configuration with domain-to-backend mappings
- **`docker-compose.yml`**: Single Caddy container with host gateway mapping for Linux
- **`caddy`**: CLI tool for managing domains and certificates
- **`install.sh`**: Installation script with Docker setup and web server detection
- **`README.md`**: Setup instructions and troubleshooting

## Common Commands (CLI Tool)

The `caddy` CLI tool simplifies HTTPS management for local development:

```bash
# Start/stop/restart services
./caddy start
./caddy stop
./caddy restart
./caddy status

# Domain management
./caddy link myapp.test          # Add Apache site (port 80)
./caddy link api.test 3000       # Add custom port
./caddy unlink myapp.test        # Remove domain
./caddy links                    # List all domains

# Certificate management
sudo ./caddy trust               # Install CA certificate

# View logs
./caddy logs
```

## Common Commands (Docker Compose)

```bash
# Start/restart services
docker-compose up -d
docker-compose restart caddy

# View logs
docker-compose logs -f caddy

# Extract CA certificate for browser trust
docker exec caddy-local-https cat /data/caddy/pki/authorities/local/root.crt > caddy-root.crt

# Test connectivity (bypass certificate validation)
curl -k -I https://newsai-dashboard.test

# Check what's listening on ports
ss -tlnp | grep -E ':(80|443)'

# Verify host.docker.internal connectivity
docker exec caddy-local-https ping -c 2 host.docker.internal

# Full teardown including volumes
docker-compose down -v
```

## Caddyfile Structure

The Caddyfile uses **specificity-based routing** - more specific rules must come before wildcards:

1. **Specific domains** (e.g., `newsbytesapp.test`, `newsai-dashboard.test`)
2. **Subdomain wildcards** (e.g., `*.newsbytesapp.test`)
3. **Catch-all wildcard** (`*.test`)
4. **Default fallback** (`:80, :443` for 404)

When adding new domains, insert them ABOVE the `*.test` wildcard to avoid being caught by it first.

## Adding New Domains

### Using the CLI Tool (Recommended):

```bash
# Apache site (port 80)
./caddy link mysite.test

# Custom port (e.g., Node.js on 3000)
./caddy link api.test 3000
```

This automatically:
- Adds the domain to Caddyfile (inserted before `*.test` wildcard)
- Updates `/etc/hosts`
- Restarts Caddy
- Installs CA certificate if needed

### Manual Method:

1. Add specific entry in `Caddyfile` before the `*.test` wildcard:
   ```caddyfile
   mysite.test {
       reverse_proxy host.docker.internal:80 {
           header_up Host {host}
           header_up X-Real-IP {remote}
           header_up X-Forwarded-For {remote}
           header_up X-Forwarded-Proto {scheme}
       }
   }
   ```

2. Add to `/etc/hosts`:
   ```bash
   echo "127.0.0.1  mysite.test" | sudo tee -a /etc/hosts
   ```

3. Restart Caddy:
   ```bash
   docker-compose restart caddy
   ```

## Headers Configuration

The `header_up` directives are **essential** for backend applications to:
- Know the original requested hostname (`Host`)
- Get the client's real IP (`X-Real-IP`, `X-Forwarded-For`)
- Detect HTTPS requests (`X-Forwarded-Proto`)

Caddy automatically handles `X-Forwarded-For` and `X-Forwarded-Proto`, so these headers can be removed to avoid warnings in logs.

## Certificate Trust Process

Caddy auto-generates a local CA on first run. Browsers won't trust it until manually imported:

1. Extract: `docker exec caddy-local-https cat /data/caddy/pki/authorities/local/root.crt > caddy-root.crt`
2. Ubuntu/Debian: `sudo cp caddy-root.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates`
3. Import to browser certificate authorities

## Troubleshooting

### "OpenSSL/3.0.13: error:0A000438:SSL routines::tlsv1 alert internal error"
- **Cause**: Certificate not trusted by system/browser, or domain has no Caddyfile entry
- **Solution**: Check if domain is configured in Caddyfile, check certificate installation

### HTTP 500 from backend
- **Not a Caddy issue** - Caddy is correctly proxying the error from Apache/backend
- Check Apache logs and virtual host configuration

### "404 - Domain not configured"
- Domain matches the catch-all rule instead of a specific entry
- Add explicit entry in Caddyfile before `*.test` wildcard

### Container can't reach host services
- Verify `host.docker.internal` works: `docker exec caddy-local-https ping -c 2 host.docker.internal`
- Check `extra_hosts` is set correctly in docker-compose.yml
- Ensure Docker version is 20.10+

### Changes to Caddyfile not taking effect
- Always restart Caddy after editing: `docker-compose restart caddy`
- Check logs for configuration errors: `docker logs caddy-local-https`

## Port Conflict Prevention

**Never map port 80 in docker-compose.yml** - Apache owns this port on the host. Only port 443 should be mapped. If you see "address already in use" on port 443, check if another process is using it with `ss -tlnp | grep :443`.
