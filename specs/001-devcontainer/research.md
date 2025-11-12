# Research: Dev Container Support

**Feature**: Dev Container Support (`1-devcontainer`)
**Date**: 2025-11-11
**Phase**: 0 - Technology Decisions

## Overview

This document captures research findings and technology decisions for implementing VS Code Dev Container support for Gratan development.

## 1. Dev Container Base Image Selection

### Decision: Use Official Ruby Image with Features

**Chosen**: `mcr.microsoft.com/devcontainers/ruby:2` (Microsoft's official Ruby dev container base)

**Rationale**:
- Pre-configured with common Ruby development tools
- Maintained by Microsoft Dev Containers team with security updates
- Includes git, bash, and standard Unix utilities by default
- Supports VS Code Dev Container features for extensibility
- Compatible with existing .ruby-version specifications via features

**Alternatives Considered**:
- **Official Docker Hub ruby:2.x**: Requires more manual tooling setup, lacks VS Code optimizations
- **Custom Dockerfile from scratch**: Increased maintenance burden, slower build times
- **Generic devcontainers/base:ubuntu**: Requires full Ruby installation, unnecessary complexity

**Implementation Notes**:
- Use `"image": "mcr.microsoft.com/devcontainers/ruby:2"` in devcontainer.json
- Add `ghcr.io/devcontainers/features/ruby:1` feature to match exact Ruby version from .ruby-version
- Leverage built-in feature catalog for additional tools (Docker-in-Docker)

## 2. MySQL Container Integration Strategy

### Decision: Docker Compose Feature with Dedicated Compose File

**Chosen**: Option B - Embedded docker-compose.yml in `.devcontainer/` using VS Code's Docker Compose feature

**Rationale**:
- Clean separation between dev container services and existing docker-compose.yml (if any)
- Dev container becomes self-contained and portable
- VS Code Dev Containers natively supports docker-compose integration
- Allows precise control over MySQL versions and ports without affecting other workflows
- Automatic container lifecycle management (start/stop with dev container)

**Alternatives Considered**:
- **Option A - Reuse existing docker-compose.yml**: Risk of conflicts with existing CI/test workflows, harder to maintain dev-specific configuration
- **Option C - Docker-in-Docker with manual docker-compose**: Requires Docker CLI in container, more complex setup, nested Docker overhead

**Implementation Notes**:
```json
{
  "dockerComposeFile": "docker-compose.yml",
  "service": "devcontainer",
  "workspaceFolder": "/workspace"
}
```

Create `.devcontainer/docker-compose.yml`:
```yaml
version: '3.8'
services:
  devcontainer:
    image: mcr.microsoft.com/devcontainers/ruby:2
    volumes:
      - ..:/workspace:cached
      - gems:/usr/local/bundle
    command: sleep infinity
    networks:
      - gratan-dev
  
  mysql56:
    image: mysql:5.6
    environment:
      MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
    ports:
      - "14406:3306"
    networks:
      - gratan-dev
    tmpfs:
      - /var/lib/mysql  # Ephemeral storage for clean state
  
  mysql57:
    image: mysql:5.7
    environment:
      MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
    ports:
      - "14407:3306"
    networks:
      - gratan-dev
    tmpfs:
      - /var/lib/mysql  # Ephemeral storage for clean state

networks:
  gratan-dev:

volumes:
  gems:
```

## 3. Persistent Volume Strategy

### Decision: Named Volume for Gems, Bind Mounts for Source

**Chosen**: 
- Named volume `gems` for `/usr/local/bundle` (gem installation directory)
- Bind mount for source code (workspace folder)
- Named volumes for bash history and VS Code server data (automatic)

**Rationale**:
- Named volumes provide better performance than bind mounts on macOS/Windows
- Gems are large and rarely changed, perfect for volume caching
- Source code must be bind-mounted for real-time editing
- VS Code handles shell history persistence automatically when using named volumes
- Rebuilding container preserves gems, avoiding 5+ minute bundle install

**Alternatives Considered**:
- **Bind mount for gems**: Slower on macOS/Windows due to file system translation overhead
- **No persistence**: Unacceptable 5+ minute reinstall on every rebuild
- **Custom cache volumes**: Unnecessary - standard bundler paths work well

**Implementation Notes**:
```json
{
  "mounts": [
    "source=gratan-gems,target=/usr/local/bundle,type=volume"
  ]
}
```

Git configuration persists automatically via VS Code's built-in credential helper.

## 4. VS Code Extension Recommendations

### Decision: Minimal Extension Set with Ruby Essentials

**Chosen Extensions**:
1. **Shopify.ruby-lsp** - Modern Ruby language server (faster than Solargraph)
2. **Shopify.ruby-extensions-pack** - Includes syntax highlighting, snippets
3. **castwide.solargraph** - Alternative LSP (in case Ruby LSP has issues)
4. **connorshea.vscode-ruby-test-adapter** - Test Explorer integration for RSpec

**Rationale**:
- Ruby LSP by Shopify is actively maintained and performant
- Provides IntelliSense, go-to-definition, formatting
- Test adapter enables running individual specs from UI
- Keep extension list minimal to avoid bloat and conflicts

**Alternatives Considered**:
- **rebornix.ruby**: Older, less maintained
- **Solargraph only**: Heavier, slower indexing, but more mature
- **Multiple competing extensions**: Causes conflicts and confusion

**Implementation Notes**:
```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "Shopify.ruby-lsp",
        "Shopify.ruby-extensions-pack",
        "connorshea.vscode-ruby-test-adapter"
      ],
      "settings": {
        "ruby.lsp.enabled": true,
        "ruby.format": "rubocop",
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "Shopify.ruby-lsp"
      }
    }
  }
}
```

## 5. Additional Decisions

### Environment Variables

Set in devcontainer.json:
```json
{
  "containerEnv": {
    "MYSQL_PORT": "3306",
    "TEST_DATABASE": "gratan_test"
  }
}
```

Tests connect to `mysql56:3306` and `mysql57:3306` via service hostnames. No need to use host ports inside container network.

### Post-Create Command

Run `bundle install` automatically after container creation:
```json
{
  "postCreateCommand": "bundle install"
}
```

### Features

Add Docker-in-Docker for `docker ps` inspection:
```json
{
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  }
}
```

## Summary of Technology Stack

| Component | Technology | Version/Image |
|-----------|-----------|---------------|
| Base Container | Microsoft Ruby Dev Container | `mcr.microsoft.com/devcontainers/ruby:2` |
| Ruby Version Management | devcontainers/features/ruby | Match .ruby-version |
| MySQL 5.6 | Official MySQL | `mysql:5.6` |
| MySQL 5.7 | Official MySQL | `mysql:5.7` |
| Docker Integration | Docker-in-Docker Feature | `ghcr.io/devcontainers/features/docker-in-docker:2` |
| Language Server | Ruby LSP (Shopify) | Latest via extensions |
| Test Runner | RSpec Test Adapter | Latest via extensions |
| Volume Strategy | Named volumes + bind mounts | Docker managed |

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| MySQL startup time delays tests | Add health checks and wait scripts in post-create |
| Port conflicts (14406/14407) | Document in quickstart, provide alternative port configuration |
| Slow build on Windows | Use named volumes, optimize layer caching |
| Ruby version mismatch | Feature-based version specification from .ruby-version |
| Docker resource limits | Document minimum requirements (4GB RAM, 2 CPU) |

## References

- [VS Code Dev Containers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container Features](https://containers.dev/features)
- [Ruby LSP Documentation](https://shopify.github.io/ruby-lsp/)
- [Docker Compose in Dev Containers](https://code.visualstudio.com/docs/devcontainers/docker-compose)

## Next Steps

Proceed to Phase 1: Create concrete devcontainer.json and docker-compose.yml based on these decisions.
