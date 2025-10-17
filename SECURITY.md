# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these steps:

### Do NOT

- Open a public GitHub issue
- Disclose the vulnerability publicly before it has been addressed

### Do

1. **Email** the maintainers directly (create a private security advisory on GitHub)
2. **Include** as much information as possible:
   - Type of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment** within 48 hours
- **Assessment** of the vulnerability within 7 days
- **Fix timeline** communicated once assessed
- **Credit** in the release notes (if you wish)

## Security Considerations

### This Tool is for Local Development Only

- **Never expose** ports 80 or 443 from the Caddy container to the public internet
- **Never use** in production environments
- The CA certificates are self-signed and only valid locally

### Best Practices

1. **Keep Docker updated** to the latest version
2. **Review** the Caddyfile before adding sensitive domains
3. **Don't commit** certificate files to version control
4. **Limit access** to the project directory
5. **Use strong passwords** for any web services behind the proxy

## Known Limitations

- Self-signed certificates are not suitable for production
- Local CA must be manually imported to browsers
- `host.docker.internal` is a development convenience, not a production pattern

## Disclosure Policy

- Security vulnerabilities will be disclosed after a fix is available
- CVE numbers will be requested for serious vulnerabilities
- Users will be notified via GitHub Security Advisories

Thank you for helping keep Caddy Local HTTPS secure!
