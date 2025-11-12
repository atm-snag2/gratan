# Quickstart: Dev Container Setup for Gratan

**Feature**: Dev Container Support (`1-devcontainer`)
**Last Updated**: 2025-11-11

## Overview

This guide helps you set up a complete Gratan development environment using VS Code Dev Containers. After following these steps, you'll have Ruby, MySQL test instances, and all dependencies configured automatically.

**Time to Complete**: 5-10 minutes (first time)

> **Note**: Screenshots/GIFs of the setup process can be added to this guide for visual learners. Key steps to capture: "Reopen in Container" prompt, build progress, and final test execution.

## Prerequisites

Before you begin, ensure you have:

1. **Docker Desktop** (or Docker Engine + Docker Compose)
   - [Download for macOS](https://www.docker.com/products/docker-desktop)
   - [Download for Windows](https://www.docker.com/products/docker-desktop)
   - Linux: Install Docker and Docker Compose via package manager

2. **Visual Studio Code**
   - [Download VS Code](https://code.visualstudio.com/)

3. **Dev Containers Extension**
   - Install from VS Code: `Ext+Shift+X`, search for "Dev Containers"
   - Or install from [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

4. **System Resources** (minimum)
   - 4GB RAM allocated to Docker
   - 2 CPU cores
   - 10GB free disk space

## Setup Steps

### 1. Clone the Repository

```bash
git clone https://github.com/codenize-tools/gratan.git
cd gratan
```

### 2. Open in VS Code

```bash
code .
```

Or open VS Code and use `File > Open Folder...` to select the `gratan` directory.

### 3. Reopen in Dev Container

When you open the project, VS Code should detect the `.devcontainer/` configuration and show a notification:

> **Folder contains a Dev Container configuration file. Reopen folder to develop in a container.**

Click **"Reopen in Container"**.

**Alternatively**, use the Command Palette:
1. Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux)
2. Type "Dev Containers: Reopen in Container"
3. Press Enter

### 4. Wait for Container Build

The first build takes **3-5 minutes** and includes:
- Pulling Ruby base image
- Starting MySQL 5.6 and 5.7 containers
- Configuring SSH for GitHub (persistent host key handling)
- Running `bundle install`
- Installing VS Code extensions

**Progress**: Watch the terminal output in VS Code's lower panel.

**What's Happening**:
- MySQL 5.6 starts on port 14406
- MySQL 5.7 starts on port 14407
- SSH config is set up for github.com (avoids repeated host key verification)
- Ruby gems are installed to persistent volume
- Ruby LSP and test extensions are activated

### 5. Verify Installation

Once the container is ready, open a terminal in VS Code (`Terminal > New Terminal`) and run:

```bash
# Verify Ruby version
ruby --version

# Verify gems are installed
bundle list

# Verify Gratan CLI
bundle exec gratan --help

# Check MySQL containers
docker ps
```

Expected output for `docker ps`:
```
CONTAINER ID   IMAGE          PORTS                     NAMES
abc123...      mysql:5.6      0.0.0.0:14406->3306/tcp   mysql56
def456...      mysql:5.7      0.0.0.0:14407->3306/tcp   mysql57
```

### 6. Run Tests

```bash
# Run full test suite
bundle exec rspec

# Run specific test directory
bundle exec rspec spec/integration/

# Run single test file
bundle exec rspec spec/change/change_grants_spec.rb
```

**Expected Result**: All tests should pass ✅

## Daily Usage

### Starting Development

After initial setup, simply open the project in VS Code and it will automatically reconnect to the dev container (usually takes 10-30 seconds).

### Running Tests

```bash
# All tests
bundle exec rspec

# Watch mode (install guard first)
bundle exec guard

# Single test
bundle exec rspec spec/path/to/test_spec.rb:42
```

### Accessing MySQL Directly

From inside the dev container:

```bash
# MySQL 5.6
mysql -h mysql56 -u root

# MySQL 5.7
mysql -h mysql57 -u root
```

From your host machine:

```bash
# MySQL 5.6
mysql -h 127.0.0.1 -P 14406 -u root

# MySQL 5.7
mysql -h 127.0.0.1 -P 14407 -u root
```

### Installing New Gems

```bash
# Add gem to Gemfile, then:
bundle install

# Gems persist in named volume - no reinstall on rebuild
```

### Rebuilding Container

If you need to rebuild (e.g., after updating devcontainer.json):

1. Command Palette: `Cmd+Shift+P` / `Ctrl+Shift+P`
2. Type "Dev Containers: Rebuild Container"
3. Select "Rebuild Container" or "Rebuild Without Cache"

**Note**: Installed gems persist across rebuilds via named volume. Shell history / git config は意図的に永続化していません (シンプルさ優先)。必要なら:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

を初回だけ実行してください。

## Troubleshooting

### Port Already in Use

**Error**: `Bind for 0.0.0.0:14406 failed: port is already allocated`

**Solution**: 
1. Check what's using the ports:
   ```bash
   lsof -i :14406
   lsof -i :14407
   ```
2. Stop conflicting process or change ports in `.devcontainer/docker-compose.yml`

### Container Build Fails

**Error**: `Failed to build container`

**Solutions**:
1. Ensure Docker Desktop is running
2. Check Docker has enough resources (Settings > Resources)
3. Try rebuilding without cache: Command Palette > "Rebuild Without Cache"
4. Check Docker logs: `docker logs <container-id>`

### MySQL Not Starting

**Error**: Tests fail with "Can't connect to MySQL server"

**Solutions**:
1. Check MySQL containers are running: `docker ps`
2. Wait 30 seconds for MySQL initialization
3. Check MySQL logs:
   ```bash
   docker logs devcontainer-mysql56-1
   docker logs devcontainer-mysql57-1
   ```
4. Restart containers: Rebuild dev container

### Slow Performance on macOS/Windows

**Symptom**: File operations or tests are very slow

**Solutions**:
1. Ensure named volumes are used (default configuration)
2. Increase Docker Desktop resources (Settings > Resources)
3. Close other resource-intensive applications
4. Check Docker Desktop's disk image isn't full

### Extensions Not Installing

**Symptom**: Ruby language features not working

**Solutions**:
1. Check extensions are listed in devcontainer.json
2. Manually install: Extensions panel > Search "Ruby LSP"
3. Reload window: Command Palette > "Developer: Reload Window"

### Gems Not Persisting

**Symptom**: Need to run `bundle install` after every rebuild

**Solutions**:
1. Verify named volume exists: `docker volume ls | grep gratan`
2. Check `BUNDLE_PATH` is set in docker-compose.yml environment
3. Verify volume mount: `docker inspect devcontainer-devcontainer-1 | grep -A 5 Mounts`
4. Remove and recreate volume if corrupted:
   ```bash
   docker volume rm devcontainer_gratan-gems
   # Rebuild container
   ```

### Bundler Version Warning

**Symptom**: "Warning: the running version of Bundler (2.1.4) is older than the lockfile (2.6.2)"

**Impact**: Informational only - does not affect functionality

**Solution (optional)**:
```bash
gem install bundler:2.6.2
```

### Git "dubious ownership" Error

**Symptom**: Git commands fail with "detected dubious ownership in repository"

**Solution**:
```bash
git config --global --add safe.directory /workspace
```

### Known Limitations

- **Shell history**: Not persisted (by design for simplicity)
- **Git config**: Not persisted - set git config on first container open
- **Global gem installs**: Only Bundler-managed gems persist; use Gemfile for dependencies
- **MySQL data**: Intentionally ephemeral - containers always start with clean databases
   ```bash
   docker volume rm gratan-gems
   # Rebuild container
   ```

## Advanced Configuration

### Customizing Ruby Version

Edit `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/ruby:1": {
      "version": "2.7"
    }
  }
}
```

### Adding More Extensions

Edit `.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "Shopify.ruby-lsp",
        "your-extension-id"
      ]
    }
  }
}
```

### Using Different MySQL Versions

Edit `.devcontainer/docker-compose.yml`:

```yaml
mysql80:
  image: mysql:8.0
  environment:
    MYSQL_ALLOW_EMPTY_PASSWORD: "yes"
  ports:
    - "14408:3306"
  tmpfs:
    - /var/lib/mysql
```

Update `spec/spec_helper.rb` to include the new port.

## Getting Help

- **Dev Containers Issues**: [VS Code Dev Containers Docs](https://code.visualstudio.com/docs/devcontainers/containers)
- **Gratan Issues**: [GitHub Issues](https://github.com/codenize-tools/gratan/issues)
- **Docker Issues**: [Docker Desktop Docs](https://docs.docker.com/desktop/)

## Cross-Platform Testing

This dev container has been designed to work on:
- **macOS**: Docker Desktop + VS Code
- **Linux**: Docker Engine/Desktop + VS Code  
- **Windows**: Docker Desktop (WSL2 backend recommended) + VS Code

**Performance expectations**:
- First build: 3-5 minutes (image pull + gem install)
- Incremental rebuild: <2 minutes (cached layers + persisted gems)
- Test execution: 2-3 seconds for full suite

If you encounter platform-specific issues, please report them with your OS version and Docker version.

## Next Steps

- Read the [Contributing Guide](../../CONTRIBUTING.md) (if exists)
- Explore the [Gratan README](../../README.md)
- Check out [open issues](https://github.com/codenize-tools/gratan/issues) to contribute
- Follow TDD workflow: Write tests first, then implement features

---

**Time Saved**: Traditional setup takes 30+ minutes. Dev Container setup takes 5-10 minutes. Rebuild takes <2 minutes. 🎉
