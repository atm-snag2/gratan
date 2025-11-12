# Feature Specification: Dev Container Support

**Feature Branch**: `001-devcontainer`  
**Created**: 2025-11-11  
**Status**: Draft  
**Input**: User description: "devcontainer に対応したい"

## Clarifications

### Session 2025-11-11

- Q: Should the MySQL test databases preserve data between dev container restarts, or should they always start fresh? → A: Always start with clean/empty databases - ensures test isolation and repeatability

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Local Development Setup (Priority: P1)

Contributors want to set up a complete development environment for Gratan without manually installing Ruby, MySQL, and other dependencies. They should be able to open the project in VS Code with the Dev Containers extension and have everything ready to start coding.

**Why this priority**: Reduces onboarding friction from hours to minutes. Critical for attracting new contributors and ensuring consistent development environments across team members.

**Independent Test**: A new contributor with Docker and VS Code installed can clone the repository, open it in a dev container, run `bundle install`, and execute the RSpec test suite successfully without any manual dependency installation.

**Acceptance Scenarios**:

1. **Given** a fresh clone of the Gratan repository, **When** a developer opens it in VS Code with Dev Containers extension, **Then** the container builds successfully and opens with Ruby and all dependencies available
2. **Given** the dev container is running, **When** the developer runs `bundle exec rspec`, **Then** all tests execute against the containerized MySQL instances
3. **Given** the dev container is running, **When** the developer runs `gratan --help`, **Then** the CLI displays help information correctly

---

### User Story 2 - MySQL Test Environments (Priority: P1)

Developers need access to MySQL 5.6 and 5.7 test instances that match the existing Docker Compose setup, running on ports 14406 and 14407, to ensure integration tests work identically in the dev container as in CI.

**Why this priority**: Integration tests are NON-NEGOTIABLE per constitution. Without MySQL instances, developers cannot follow TDD principles or verify their changes.

**Independent Test**: Developer can run `docker ps` inside the dev container and see MySQL containers running on ports 14406 and 14407. Tests in `spec/integration/` pass successfully.

**Acceptance Scenarios**:

1. **Given** the dev container is running, **When** MySQL test containers start, **Then** MySQL 5.6 is accessible on port 14406 and MySQL 5.7 on port 14407 with empty databases
2. **Given** MySQL containers are running, **When** developer runs integration tests, **Then** tests can connect to both MySQL versions and execute grant operations
3. **Given** a developer stops and restarts the dev container, **When** the container initializes, **Then** MySQL containers restart automatically with clean/empty state (no persisted data from previous session)

---

### User Story 3 - Persistent Development State (Priority: P2)

Developers want their installed gems, command history, and development configurations to persist across container rebuilds so they don't have to reinstall dependencies every time.

**Why this priority**: Improves developer experience and productivity. While not blocking initial setup, frequent reinstalls waste time and frustrate contributors.

**Independent Test**: Developer installs a gem, rebuilds the container, and the gem is still available without reinstallation. Shell history is preserved between sessions.

**Acceptance Scenarios**:

1. **Given** the dev container with installed gems, **When** the container is rebuilt, **Then** gems remain installed in the persisted volume
2. **Given** the developer has executed commands, **When** they reopen the container, **Then** shell history is preserved
3. **Given** custom git configuration, **When** the container restarts, **Then** git settings persist

---

### User Story 4 - VS Code Extensions and Settings (Priority: P3)

Developers benefit from pre-configured VS Code extensions for Ruby development (linting, formatting, debugging) and settings that match the project's coding standards.

**Why this priority**: Enhances developer experience but not required for basic functionality. Can be added incrementally after core container works.

**Independent Test**: When opening the dev container, VS Code automatically installs Ruby language support, RSpec extensions, and applies consistent formatting settings.

**Acceptance Scenarios**:

1. **Given** the dev container opens, **When** VS Code initializes, **Then** Ruby language server and RSpec extensions are automatically installed
2. **Given** the developer edits Ruby code, **When** they save a file, **Then** automatic formatting applies according to RuboCop rules
3. **Given** the developer runs tests, **When** they use VS Code's test explorer, **Then** RSpec tests are discovered and can be run individually

---

### Edge Cases

- What happens when Docker is not installed or running when trying to open the dev container?
- How does the system handle port conflicts if ports 14406 or 14407 are already in use?
- What happens if the MySQL containers fail to start due to insufficient memory or resources?
- How does the dev container work on different host operating systems (macOS, Linux, Windows)?
- What happens when switching between branches that might have different devcontainer.json configurations?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Dev container MUST include Ruby runtime matching the version specified in .ruby-version or gemspec
- **FR-002**: Dev container MUST provide access to MySQL 5.6 on port 14406 and MySQL 5.7 on port 14407 for integration testing
- **FR-003**: Dev container MUST install all Ruby dependencies from Gemfile automatically during container build
- **FR-004**: Dev container MUST mount the project source code so changes are immediately reflected without rebuild
- **FR-005**: Dev container MUST preserve installed gems across container rebuilds using named volumes
- **FR-006**: Dev container configuration MUST be compatible with VS Code Dev Containers extension
- **FR-007**: Dev container MUST provide git, bash, and standard Unix utilities for development workflows
- **FR-008**: MySQL test containers MUST initialize with clean/empty state on every startup and NOT persist data between dev container sessions to ensure test isolation and repeatability
- **FR-009**: Dev container MUST support running the full RSpec test suite including integration tests
- **FR-010**: Dev container MUST include Docker CLI to interact with the MySQL test containers
- **FR-011**: Configuration files MUST be stored in `.devcontainer/` directory following VS Code conventions
- **FR-012**: Dev container MUST set appropriate environment variables (MYSQL_PORT, TEST_DATABASE) for test execution

### Key Entities

- **Dev Container Configuration**: Defines the development environment including base image, features, extensions, and port forwarding
- **MySQL Test Containers**: Separate containers for MySQL 5.6 and 5.7 that provide isolated test databases
- **Ruby Environment**: Complete Ruby installation with gems and dependencies ready for development
- **Persistent Volumes**: Named volumes for gems, bash history, and other stateful data that should survive rebuilds

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: New contributors can complete environment setup in under 5 minutes (vs. 30+ minutes manual setup)
- **SC-002**: 100% of existing RSpec tests pass in the dev container environment without modification
- **SC-003**: Container builds successfully on macOS, Linux, and Windows with Docker Desktop
- **SC-004**: Developers can edit code and see test results without manual compilation or rebuild steps
- **SC-005**: Container rebuild time is under 2 minutes for incremental changes (cached layers)
- **SC-006**: Documentation enables a developer unfamiliar with dev containers to get started in under 10 minutes

## Assumptions

- Developers have Docker Desktop (or equivalent) installed and running
- Developers use VS Code with the Dev Containers extension (or compatible editor)
- Existing Docker Compose configuration for MySQL can be adapted or reused for dev container setup
- Project will maintain compatibility with both dev container and traditional local development approaches
- MySQL test databases will NOT persist data between sessions - always start fresh for test isolation
- Network connectivity allows pulling Docker base images and Ruby gems

## Out of Scope

- CI/CD pipeline changes or GitHub Actions integration
- Production deployment configurations
- Support for editors other than VS Code (though configuration should not prevent manual docker usage)
- Automated migration of existing local development environments to dev containers
- Performance optimization beyond standard Docker best practices
- Custom MySQL configurations beyond what's needed for integration tests
