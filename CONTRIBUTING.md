# Contributing to Gratan

Thank you for your interest in contributing to Gratan! This guide will help you get started with development.

## Development Setup

### Option 1: Dev Container (Recommended)

The fastest way to get started is using VS Code Dev Containers:

1. **Prerequisites**:
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - [Visual Studio Code](https://code.visualstudio.com/)
   - [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

2. **Setup**:
   ```bash
   git clone https://github.com/codenize-tools/gratan.git
   cd gratan
   code .
   ```

3. **Open in Container**:
   - Click "Reopen in Container" when prompted
   - Or use Command Palette: `Dev Containers: Reopen in Container`

4. **Verify Setup**:
   ```bash
   ruby --version
   bundle exec rspec
   ```

The dev container automatically provides:
- Ruby environment with all dependencies
- MySQL 5.6 and 5.7 test instances
- Pre-configured VS Code extensions
- Persistent gem cache

For more details, see the [Dev Container Quickstart Guide](specs/001-devcontainer/quickstart.md).

### Option 2: Local Development

If you prefer local development:

1. **Install Ruby** (version specified in `gratan.gemspec`)

2. **Install Dependencies**:
   ```bash
   bundle install
   ```

3. **Start MySQL Test Instances**:
   ```bash
   docker compose -f .devcontainer/docker-compose.yml up -d mysql56 mysql57
   ```
   This starts MySQL 5.6 on port 14406 and MySQL 5.7 on port 14407.

4. **Run Tests**:
   ```bash
   # Test with MySQL 5.6
   bundle exec rspec
   
   # Test with MySQL 5.7
   MYSQL57=1 bundle exec rspec
   ```

## Running Tests

### Full Test Suite

```bash
# Run all tests (MySQL 5.6)
bundle exec rspec

# Run all tests (MySQL 5.7)
MYSQL57=1 bundle exec rspec

# Run with Rake
bundle exec rake
```

### Specific Tests

```bash
# Run specific test file
bundle exec rspec spec/change/change_grants_spec.rb

# Run specific test case
bundle exec rspec spec/change/change_grants_spec.rb:10
```

### Integration Tests

```bash
# Run integration tests only
bundle exec rspec spec/integration/
```

## Code Style

Gratan follows standard Ruby conventions:

- 2 spaces for indentation
- No trailing whitespace
- Prefer single quotes for strings unless interpolation is needed
- Keep lines under 100 characters when possible

## Making Changes

1. **Create a Feature Branch**:
   ```bash
   git checkout -b my-feature-branch
   ```

2. **Make Your Changes**:
   - Write tests first (TDD approach)
   - Implement your changes
   - Ensure all tests pass
   - Update documentation if needed

3. **Commit Your Changes**:
   ```bash
   git add .
   git commit -m "Brief description of changes"
   ```

4. **Push and Create Pull Request**:
   ```bash
   git push origin my-feature-branch
   ```
   Then create a pull request on GitHub.

## Project Structure

```
gratan/
├── lib/
│   └── gratan/         # Core library code
├── spec/               # Test files
│   ├── change/         # Permission change tests
│   ├── create/         # User creation tests
│   ├── drop/           # User deletion tests
│   ├── export/         # Export functionality tests
│   └── integration/    # Integration tests
├── bin/                # Executable scripts
└── .devcontainer/      # Dev container configuration
```

## Testing Philosophy

- **Integration Tests**: Gratan relies heavily on integration tests with real MySQL instances
- **TDD**: Write tests before implementing features
- **MySQL Compatibility**: Test against both MySQL 5.6 and 5.7
- **Idempotency**: Operations should be safe to run multiple times

## Debugging

### In Dev Container

VS Code debugging is pre-configured:

1. Set breakpoints in code
2. Run test with debugger from Test Explorer
3. Or use `binding.pry` (install pry gem first)

### Local Development

```bash
# Run tests with verbose output
bundle exec rspec --format documentation

# Add debugging statements
require 'pp'
pp variable_to_inspect
```

## Submitting Pull Requests

### Before Submitting

- [ ] All tests pass (`bundle exec rspec`)
- [ ] Tests pass with MySQL 5.7 (`MYSQL57=1 bundle exec rspec`)
- [ ] Code follows project conventions
- [ ] Documentation is updated if needed
- [ ] Commit messages are clear and descriptive

### Pull Request Guidelines

- Provide a clear description of the changes
- Reference any related issues
- Include examples if adding new DSL features
- Explain any breaking changes

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/codenize-tools/gratan/issues)
- **Documentation**: See [README.md](README.md)
- **Dev Container Setup**: See [quickstart guide](specs/001-devcontainer/quickstart.md)

## License

By contributing to Gratan, you agree that your contributions will be licensed under the MIT License.
