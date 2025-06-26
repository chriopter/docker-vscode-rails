# Docker VS Code Rails Development Environment

A containerized Ubuntu development environment with Ruby on Rails, VS Code, and essential development tools.

## Purpose

Provides a consistent, isolated Rails development environment accessible via SSH (for VS Code Remote) or VNC, eliminating local setup complexity.

## Features

- Ubuntu Desktop with full GUI environment
- Ruby and Rails pre-installed
- VS Code with Ruby extensions
- SSH access for VS Code Remote Development
- Web-based desktop via KasmVNC
- Persistent workspace and settings
- GitHub CLI included

## Quick Start

```bash
docker-compose up -d
```

## Access

- **SSH**: `ssh developer@localhost -p 2222` (password: developer)
- **Web Desktop**: https://localhost:6901 (password: developer)
- **Rails**: http://localhost:3000

## Example

See `docker-compose.yml` for the complete configuration.