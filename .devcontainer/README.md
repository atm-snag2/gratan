# Gratan Dev Container

This directory contains the VS Code Dev Container configuration for Gratan development.

## Quick Reference

### First Time Setup

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop)
2. Install [VS Code Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
3. Open this repository in VS Code
4. Click "Reopen in Container" when prompted
5. Wait for build to complete
6. Run `bundle exec rspec` to verify setup

### Container Services

- **devcontainer**: Ruby development environment
  - Base image: `mcr.microsoft.com/devcontainers/ruby:2`
  - Workspace: `/workspace`
  - Gems cached in named volume `gratan-gems`

- **mysql56**: MySQL 5.6 test instance
  - Port: `14406` (host) → `3306` (container)
  - Hostname: `mysql56` (within container network)
  - Storage: tmpfs (ephemeral - clean state on restart)

- **mysql57**: MySQL 5.7 test instance
  - Port: `14407` (host) → `3306` (container)
  - Hostname: `mysql57` (within container network)
  - Storage: tmpfs (ephemeral - clean state on restart)

### Running Tests

```bash
# Run all tests (MySQL 5.6)
bundle exec rspec

# Run with MySQL 5.7
MYSQL57=1 bundle exec rspec

# Run specific test
bundle exec rspec spec/change/change_grants_spec.rb
```

### Verifying MySQL Containers

```bash
# Check containers are running
docker ps

# Connect to MySQL 5.6
mysql -h mysql56 -u root

# Connect to MySQL 5.7
mysql -h mysql57 -u root
```

## Configuration Files

- **devcontainer.json**: VS Code dev container configuration
  - Features: Docker-in-Docker for container inspection
  - Extensions: Ruby LSP, Shopify Ruby extensions pack (auto-installed on container open)
  - Settings: Format on save, Ruby LSP enabled as default formatter
  - Post-create: SSH host key configuration + automatic `bundle install`
  - Scripts: `.devcontainer/scripts/ensure_ssh_config.sh` for GitHub SSH persistence

- **docker-compose.yml**: Container services definition
  - Networks: `gratan-dev` bridge network
  - Volumes: `gratan-gems` for Bundler gem persistence (via BUNDLE_PATH)
  - Health checks: Automatic MySQL readiness detection

## VS Code Extensions (Auto-Installed)

When you open this project in the dev container, the following extensions are automatically installed:

- **Shopify.ruby-lsp**: Modern Ruby language server for IntelliSense, go-to-definition, and diagnostics
- **Shopify.ruby-extensions-pack**: Ruby syntax highlighting and snippets

### Verifying Extensions Work

1. **Formatting on save**: Edit any `.rb` file, make a change, and save (Cmd/Ctrl+S). Ruby LSP will format the file automatically.
2. **IntelliSense**: Type a Ruby keyword or method name - you should see autocomplete suggestions.
3. **Go to definition**: Cmd/Ctrl+Click on a method name to jump to its definition.
4. **Test Explorer** (optional): Install "Ruby Test Explorer" extension manually if you want UI-based test running.

## Troubleshooting

### Container won't start

1. Ensure Docker Desktop is running
2. Check Docker has sufficient resources (4GB+ RAM recommended)
3. Rebuild container: Command Palette → "Dev Containers: Rebuild Container"

### Tests fail to connect to MySQL

1. Verify MySQL containers are running: `docker ps`
2. Check health status: `docker ps --format '{{.Names}}: {{.Status}}'`
3. Wait for health checks to pass (up to 30 seconds after start)

### Gems not installing

1. Check network connectivity
2. Clear gem cache: Remove `gratan-gems` volume and rebuild
3. Run manually: `bundle install --verbose`

### Slow build times

- **First build**: ~5 minutes (downloading base images)
- **Incremental rebuild**: <2 minutes (cached layers)
- **Tip**: Use "Rebuild Container" instead of "Rebuild Without Cache" unless necessary

## Advanced Configuration

### Custom Ruby Version

Edit `devcontainer.json` to specify exact Ruby version:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/ruby:1": {
      "version": "2.7"
    }
  }
}
```

### Port Conflicts

If ports 14406 or 14407 are already in use:

1. Edit `docker-compose.yml`
2. Change port mappings (e.g., `"14408:3306"`)
3. Update test configuration in `spec/spec_helper.rb`

### Persistent Test Databases

By default, MySQL uses tmpfs (ephemeral storage). To persist data:

1. Edit `docker-compose.yml`
2. Remove `tmpfs:` sections from mysql56/mysql57
3. Add volume mounts instead:
   ```yaml
   volumes:
     - mysql56-data:/var/lib/mysql
   ```

4. Define volumes at top level:
   ```yaml
   volumes:
     mysql56-data:
     mysql57-data:
   ```

## More Information

- [Full Quickstart Guide](../specs/001-devcontainer/quickstart.md)
- [VS Code Dev Containers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
