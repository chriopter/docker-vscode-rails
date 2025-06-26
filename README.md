# Docker VS Code Rails Development Environment

A containerized Ubuntu development environment with Ruby on Rails, VS Code, and essential development tools.

## Purpose

Provides a consistent, isolated Rails development environment accessible via SSH (for VS Code Remote) or VNC, eliminating local setup complexity.

## Features

- Ubuntu 24.04 with Ruby 3.4.4 and Rails
- VS Code with Ruby extensions pre-installed
- SSH access for VS Code Remote Development
- VNC access with dynamic resolution support
- noVNC web-based access
- Persistent workspace and settings
- GitHub CLI included

## Quick Start

```bash
docker-compose up -d
```

## Access

- **SSH**: `ssh developer@localhost -p 2222` (password: developer)
- **VNC**: `vnc://localhost:5901`
- **Web VNC**: http://localhost:6080
- **Rails**: http://localhost:3000

## Example

See `docker-compose.yml` for the complete configuration.