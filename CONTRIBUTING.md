# Contributing to Caddy Local HTTPS

Thank you for considering contributing to Caddy Local HTTPS!

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. Include:
- Clear and descriptive title
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Docker version, web server)
- Logs from `caddy logs` or `docker logs caddy-local-https`

### Suggesting Enhancements

- Use a clear title
- Provide detailed description
- Explain why it would be useful
- Include usage examples

### Pull Requests

1. Fork the repository and create your branch from `main`
2. Test your code thoroughly
3. Follow existing code style
4. Write clear commit messages
5. Update documentation as needed
6. Submit a pull request

## Development Setup

```bash
git clone https://github.com/yourusername/caddy-local-https.git
cd caddy-local-https
./install.sh
./caddy help
```

## Code Style

- Follow Google Shell Style Guide
- Use 4 spaces for indentation
- Add comments for complex logic
- Use descriptive variable names

## Testing

```bash
./caddy start
./caddy link test.local
./caddy links
./caddy unlink test.local
./caddy stop
```

## Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood
- Limit first line to 72 characters
- Reference issues after first line

Thank you for contributing! 🎉
