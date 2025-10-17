# Caddy Local HTTPS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu%20|%20Debian%20|%20Fedora%20|%20Arch-orange.svg)](https://www.linux.org/)
[![macOS](https://img.shields.io/badge/macOS-10.15+-lightgrey.svg)](https://www.apple.com/macos/)

> Automatic HTTPS for local `.test` domains using Caddy in Docker. Works with both Apache and nginx on Linux and macOS.

## Features

- ✨ **Automatic HTTPS** - Self-signed certificates via Caddy's local CA
- 🚀 **Easy CLI** - Simple commands like `caddy link myapp.test`
- 🔒 **Secure** - Proper certificate management and browser trust
- 🐳 **Docker-based** - Isolated, consistent environment
- 🌐 **Multi-platform** - Linux and macOS support
- ⚡ **Fast setup** - Get running in under 2 minutes
- 🔧 **Flexible** - Works with Apache, nginx, or any port
- 📦 **Zero config** - Automatic detection and setup

## Quick Installation

The easiest way to get started is with the installation script:

```bash
# Clone or download this repository
git clone https://github.com/newsbytesapp/caddy-local-https.git
cd caddy-local-https

# Run the installer
./install.sh
```

The installer will:
- Detect your OS (Linux or macOS)
- Check for Docker and offer to install it if missing
- Detect your web server (Apache or nginx)
- Start Caddy container
- Optionally install the `caddy` CLI globally

After installation, follow the on-screen instructions to trust certificates and add domains.

## System Requirements

**Supported Operating Systems:**
- Linux (Ubuntu, Debian, Fedora, CentOS, RHEL, Arch, Manjaro)
- macOS (with Docker Desktop)

**Supported Web Servers:**
- Apache (port 80)
- nginx (port 80)

**Requirements:**
- Docker 20.10+ (installer can help install this)
- Docker Compose V2 or V1
- A web server running on port 80
- Port 443 available for Caddy

## Quick Start

The easiest way to manage this HTTPS proxy is with the included `caddy` CLI tool:

```bash
# Start the HTTPS proxy
./caddy start

# Add a new site (Apache on port 80)
./caddy link myproject.test

# Add a Node.js app on custom port
./caddy link nodeapp.test 3000

# Trust the CA certificate (required for browsers)
sudo ./caddy trust

# View all configured sites
./caddy links

# View status
./caddy status

# Remove a site
./caddy unlink myproject.test
```

For all available commands, run: `./caddy help`

## Making `caddy` a Global Command

To use `caddy` from anywhere (instead of `./caddy` from the project directory), create a symlink in your PATH:

```bash
# Navigate to the project directory
cd caddy-local-https

# Create symlink in /usr/local/bin (recommended)
sudo ln -s "$(pwd)/caddy" /usr/local/bin/caddy

# Or add to ~/.local/bin (no sudo required, but ensure it's in your PATH)
mkdir -p ~/.local/bin
ln -s "$(pwd)/caddy" ~/.local/bin/caddy
```

Now you can run `caddy` from anywhere:

```bash
# From any directory
caddy start
caddy link myapp.test
caddy status
```

**To uninstall:**

```bash
# Remove the symlink
sudo rm /usr/local/bin/caddy
# or
rm ~/.local/bin/caddy
```

**Note:** The script will still operate on the original project directory regardless of where you run it from.

## Manual Setup (Alternative)

If you prefer not to use the CLI tool, you can set up manually:

### 1. Configure `/etc/hosts`

Add your local domains to `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Add these lines:

```
127.0.0.1  newsbytesapp.test
127.0.0.1  newsai-dashboard.test
```

Save and exit (Ctrl+X, Y, Enter).

### 2. Start Caddy

```bash
docker-compose up -d
```

### 3. Trust the Local CA Certificate

Caddy automatically generates a local Certificate Authority (CA). You need to trust it:

#### Get the root CA certificate:

```bash
docker exec caddy-local-https cat /data/caddy/pki/authorities/local/root.crt > caddy-root.crt
```

#### Install the certificate:

**On Linux (Ubuntu/Debian):**

```bash
sudo cp caddy-root.crt /usr/local/share/ca-certificates/caddy-root.crt
sudo update-ca-certificates
```

**On Arch/Manjaro:**

```bash
sudo trust anchor --store caddy-root.crt
```

**For browsers (Chrome/Chromium):**

- Go to: `chrome://settings/certificates`
- Click "Authorities" tab
- Click "Import" and select `caddy-root.crt`
- Check "Trust this certificate for identifying websites"

**For Firefox:**

- Go to: `about:preferences#privacy`
- Scroll to "Certificates" → Click "View Certificates"
- Click "Authorities" tab → "Import"
- Select `caddy-root.crt`
- Check "Trust this CA to identify websites"

### 4. Verify the Setup

Open your browser and visit:

- `https://newsbytesapp.test`
- `https://newsai-dashboard.test`

You should see your local sites with a valid HTTPS certificate!

## Architecture

```
Browser (HTTP) → Apache/nginx (port 80) → Your local sites
Browser (HTTPS) → Caddy (port 443) → host.docker.internal → Apache/nginx (port 80) → Your local sites
```

**Note:** Your web server (Apache or nginx) handles HTTP traffic on port 80. Caddy only handles HTTPS on port 443 and proxies requests to your web server via `host.docker.internal`.

## Adding New Domains

### Method 1: Using the CLI (Recommended)

The easiest way to add domains is with the `caddy` CLI:

```bash
# Add Apache site (port 80)
./caddy link myapp.test

# Add Node.js app (custom port)
./caddy link nodeapp.test 3000

# Add React dev server
./caddy link frontend.test 5173
```

This automatically:
- Adds the domain to Caddyfile with proper configuration
- Updates `/etc/hosts` (requires sudo)
- Restarts Caddy to apply changes

### Method 2: Edit Caddyfile Manually

1. Edit `Caddyfile` and add a new block:

```caddyfile
myapp.test {
	reverse_proxy host.docker.internal:8080 {
		header_up Host {host}
		header_up X-Real-IP {remote}
		header_up X-Forwarded-For {remote}
		header_up X-Forwarded-Proto {scheme}
	}
}
```

2. Add domain to `/etc/hosts`:

```bash
echo "127.0.0.1  myapp.test" | sudo tee -a /etc/hosts
```

3. Reload Caddy:

```bash
docker-compose restart caddy
```

### Method 3: Use Wildcard (Dynamic, no restart needed)

The wildcard `*.test` rule allows you to add new domains on-the-fly, but you need to specify the port in the URL:

1. Add domain to `/etc/hosts`:

```bash
echo "127.0.0.1  api.myapp.test" | sudo tee -a /etc/hosts
```

2. Access with port in URL: `https://api.myapp.test:3000`

**Note:** This method requires including the port in the URL, which may not be ideal for all use cases.

## Troubleshooting

### Issue: "This site can't provide a secure connection"

**Solution:** Make sure you've trusted the Caddy root certificate (see step 3 above).

### Issue: "ERR_CONNECTION_REFUSED"

**Causes:**
1. Backend service not running on host
2. Wrong port mapping
3. Firewall blocking connection

**Check backend is running:**

```bash
# Check what's listening on port 80
sudo netstat -tlnp | grep :80

# Or using ss
sudo ss -tlnp | grep :80
```

### Issue: "404 - Domain not configured"

**Causes:**
1. Domain not in `/etc/hosts`
2. DNS cache needs clearing

**Solution:**

```bash
# Clear DNS cache (Linux)
sudo systemd-resolve --flush-caches

# Or restart systemd-resolved
sudo systemctl restart systemd-resolved
```

### Issue: Cannot access host services from Docker

**On Linux:** Verify `host.docker.internal` is working:

```bash
docker exec caddy-local-https ping -c 2 host.docker.internal
```

If it fails, the `extra_hosts` configuration might not be working. Check Docker version (19.03+ required).

### View Caddy Logs

```bash
docker-compose logs -f caddy
```

## Configuration Details

### Why `local_certs`?

The `local_certs` directive tells Caddy to use its internal CA instead of Let's Encrypt. Perfect for local development.

### Why `host.docker.internal`?

Docker containers are isolated. To reach services on your host machine, we use:
- **macOS/Windows:** `host.docker.internal` (built-in)
- **Linux:** Manual mapping via `extra_hosts: - "host.docker.internal:host-gateway"` (requires Docker 20.10+)

### Headers Explained

```caddyfile
header_up Host {host}              # Preserves the original hostname
header_up X-Real-IP {remote}       # Client's real IP
header_up X-Forwarded-For {remote} # Standard proxy header
header_up X-Forwarded-Proto {scheme} # https or http
```

These headers ensure your backend applications know:
- What domain was requested
- The client's real IP address
- That the original request was HTTPS

## Commands Reference

### CLI Commands (Recommended)

```bash
# Start the proxy
./caddy start

# Stop the proxy
./caddy stop

# Restart the proxy
./caddy restart

# View status
./caddy status

# View logs (follow mode)
./caddy logs

# List all configured domains
./caddy links

# Add a domain
./caddy link myapp.test [port]

# Remove a domain
./caddy unlink myapp.test

# Trust CA certificate
sudo ./caddy trust

# Show help
./caddy help
```

### Docker Compose Commands (Manual)

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart Caddy (after config changes)
docker-compose restart caddy

# View logs
docker-compose logs -f caddy

# Reload Caddyfile without restart (if admin API is enabled)
docker exec caddy-local-https caddy reload --config /etc/caddy/Caddyfile

# Check Caddy version
docker exec caddy-local-https caddy version

# Remove everything (including volumes)
docker-compose down -v
```

## Security Notes

- This setup is for **local development only**
- The Caddy CA is not trusted by default; you must manually trust it
- Never expose ports 80/443 from this container to the public internet
- The generated certificates are self-signed and only valid locally

## File Structure

```
.
├── docker-compose.yml   # Docker service definition
├── Caddyfile           # Caddy configuration
├── caddy               # CLI management tool
├── install.sh          # Installation script
├── README.md           # This file
└── CLAUDE.md           # Project guidance for Claude Code
```

## Performance Tips

- Caddy automatically handles HTTP/2 and HTTP/3
- Built-in automatic HTTPS with zero configuration
- Minimal resource usage (~10-20MB RAM)
- Instant certificate generation on first request

## Alternative: Using Custom Ports

If you want to avoid wildcard limitations, create explicit entries:

```caddyfile
api.myapp.test {
	reverse_proxy host.docker.internal:3000
}

frontend.myapp.test {
	reverse_proxy host.docker.internal:5173
}
```

Then add to `/etc/hosts` and restart Caddy.

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Quick Links

- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)
- [Changelog](CHANGELOG.md)
- [Issue Templates](.github/ISSUE_TEMPLATE/)

## Support

- 📖 [Documentation](README.md)
- 🐛 [Report a Bug](https://github.com/newsbytesapp/caddy-local-https/issues/new?template=bug_report.md)
- 💡 [Request a Feature](https://github.com/newsbytesapp/caddy-local-https/issues/new?template=feature_request.md)
- 💬 [Discussions](https://github.com/newsbytesapp/caddy-local-https/discussions)

## License

[MIT License](LICENSE) - Feel free to use and modify as needed.

Copyright (c) 2025 Caddy Local HTTPS Contributors

## Acknowledgments

- Built with [Caddy Server](https://caddyserver.com/)
- Inspired by Laravel Valet's simplicity
- Thanks to all [contributors](https://github.com/newsbytesapp/caddy-local-https/graphs/contributors)

---

**⭐ If you find this project useful, please consider giving it a star on GitHub!**
