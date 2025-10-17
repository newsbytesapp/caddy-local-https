# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release
- CLI tool for managing local HTTPS domains
- Automated installation script with Docker setup
- Support for Linux (Ubuntu, Debian, Fedora, CentOS, RHEL, Arch, Manjaro)
- Support for macOS with Docker Desktop
- Apache and nginx web server detection
- Automatic CA certificate installation
- Domain management commands (link, unlink, links)
- Service management commands (start, stop, restart, status)
- Certificate trust command
- Comprehensive documentation
- Contributing guidelines
- Code of conduct

### Features
- `caddy start` - Start Caddy HTTPS proxy
- `caddy stop` - Stop Caddy proxy
- `caddy restart` - Restart Caddy proxy
- `caddy status` - Show container status
- `caddy link <domain> [port]` - Add domain with optional port
- `caddy unlink <domain>` - Remove domain
- `caddy links` - List all configured domains
- `caddy trust` - Install CA certificate
- `caddy logs` - View Caddy logs

## [1.0.0] - 2025-01-XX

### Added
- First stable release

[Unreleased]: https://github.com/yourusername/caddy-local-https/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/caddy-local-https/releases/tag/v1.0.0
