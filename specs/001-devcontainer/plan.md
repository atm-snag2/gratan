# Implementation Plan: Dev Container Support

**Branch**: `001-devcontainer` | **Date**: 2025-11-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-devcontainer/spec.md`

## Summary

Enable development environment setup through VS Code Dev Containers, providing automated Ruby and MySQL test environment configuration. Primary requirement: Reduce contributor onboarding from 30+ minutes to under 5 minutes while ensuring 100% test compatibility. Technical approach: Create `.devcontainer/` configuration with Docker Compose integration for MySQL 5.6/5.7 test instances, persistent gem volumes, and pre-configured VS Code extensions.

## Technical Context

**Language/Version**: Ruby 2.x+ (match existing .ruby-version or gemspec)
**Primary Dependencies**: Docker, Docker Compose, VS Code Dev Containers extension
**Storage**: MySQL 5.6/5.7 (ephemeral containers on ports 14406/14407)
**Testing**: RSpec 3.x, Docker Compose for MySQL integration tests
**Target Platform**: macOS, Linux, Windows with Docker Desktop
**Project Type**: Development environment configuration (non-runtime feature)
**Performance Goals**: Container build <5 minutes initial, <2 minutes incremental rebuild
**Constraints**: Must preserve existing Docker Compose compatibility, no changes to test suite required
**Scale/Scope**: Single developer environment, support for parallel MySQL container execution

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Initial Check (Pre-Phase 0)**: ✅ PASS

**Post-Phase 1 Re-evaluation**: ✅ PASS

- [x] **DSL-First Design**: N/A - Infrastructure feature, no DSL changes
- [x] **Idempotency & Dry-Run**: N/A - Development environment setup, not runtime operation
- [x] **TDD (NON-NEGOTIABLE)**: Validation approach defined - existing RSpec integration tests serve as acceptance tests for containerized environment. Manual verification steps documented in plan.
- [x] **Integration Testing**: Research confirms MySQL 5.6/5.7 containers will run identically to existing Docker Compose setup. All existing integration tests will pass unmodified.
- [x] **CLI & Library Interface**: N/A - Infrastructure change, existing CLI/library unchanged
- [x] **Backward Compatibility**: Confirmed non-breaking - dev container is purely optional addition. Traditional local development remains fully supported. No changes to runtime code.
- [x] **Observability & Auditing**: N/A - Development environment, not production operation

**Gate Status**: ✅ PASS - All applicable principles satisfied. Phase 1 design confirms technical approach aligns with constitution.

## Project Structure

### Documentation (this feature)

```text
specs/001-devcontainer/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # N/A for infrastructure feature
├── quickstart.md        # Phase 1 output
├── contracts/           # N/A for infrastructure feature
└── checklists/
    └── requirements.md  # Already created
```

### Source Code (repository root)

```text
.devcontainer/
├── devcontainer.json    # VS Code dev container configuration
├── docker-compose.yml   # MySQL test containers definition
└── Dockerfile           # Custom dev container image (if needed)

.vscode/
└── extensions.json      # Recommended extensions (optional)

# Existing structure unchanged
lib/gratan/              # No changes
spec/                    # No changes
docker-compose.yml       # Existing MySQL setup (reference for ports)
```

**Structure Decision**: Add `.devcontainer/` directory with VS Code Dev Containers configuration. Leverage existing `docker-compose.yml` MySQL configuration or create dev-container-specific compose file. No changes to lib/ or spec/ structure.

## Complexity Tracking

> No constitution violations - table not needed.

## Phase 0: Research & Technology Decisions

**Objective**: Resolve Docker configuration approach and VS Code Dev Container best practices for Ruby projects with MySQL dependencies.

### Research Tasks

1. **Dev Container Base Image Selection**
   - Evaluate official Ruby images vs. custom Dockerfile
   - Determine optimal base for gem caching and build speed
   - Research: Docker Hub ruby:2.x images, VS Code dev container feature catalog

2. **MySQL Container Integration Strategy**
   - Option A: Reuse existing docker-compose.yml via docker-compose feature
   - Option B: Embedded docker-compose.yml in .devcontainer/
   - Option C: Docker-in-Docker with service containers
   - Research: VS Code Dev Containers with Docker Compose, port forwarding patterns

3. **Persistent Volume Strategy**
   - Identify what should persist: gems, bash history, git config
   - Named volumes vs. bind mounts for performance
   - Research: Docker volume best practices for development

4. **VS Code Extension Recommendations**
   - Ruby language server options (Solargraph, Ruby LSP)
   - RSpec test runner extensions
   - Research: Ruby development extension ecosystem

**Output**: `research.md` with decisions documented

## Phase 1: Configuration Design

**Prerequisites**: Research phase complete

### Deliverables

1. **devcontainer.json Configuration**
   - Base image specification
   - Features: Docker-in-Docker or Docker Compose
   - Port forwarding: 14406, 14407 for MySQL
   - Volume mounts: source code, gem cache
   - Environment variables: MYSQL_PORT, TEST_DATABASE
   - VS Code extensions list
   - Post-create commands: bundle install

2. **Docker Compose Configuration** (if separate from existing)
   - MySQL 5.6 service (port 14406)
   - MySQL 5.7 service (port 14407)
   - Ephemeral volumes (no data persistence)
   - Health checks for container readiness

3. **Quickstart Documentation**
   - Prerequisites: Docker, VS Code, Dev Containers extension
   - Setup steps: clone, open in VS Code, reopen in container
   - Verification: run bundle install, bundle exec rspec
   - Troubleshooting: common port conflicts, Docker resource limits

**Output**: `quickstart.md` with step-by-step guide

## Phase 2: Implementation Validation

**Prerequisites**: Phase 1 design complete

### Validation Criteria

- [ ] Dev container builds successfully on macOS
- [ ] Dev container builds successfully on Linux
- [ ] Dev container builds successfully on Windows
- [ ] MySQL 5.6 accessible on port 14406
- [ ] MySQL 5.7 accessible on port 14407
- [ ] `bundle install` completes without errors
- [ ] `bundle exec rspec` passes 100% of existing tests
- [ ] Gems persist after container rebuild
- [ ] Shell history persists between sessions
- [ ] Documentation enables new contributor setup in <10 minutes

### Testing Approach

Since this is infrastructure/tooling, testing is manual verification:
1. Fresh clone on clean machine
2. Follow quickstart.md steps
3. Verify all acceptance scenarios from spec.md
4. Time the setup process
5. Validate test suite execution

**Note**: No automated tests for dev container configuration itself, but existing RSpec integration tests serve as validation that the containerized environment works correctly.

## Next Steps

After Phase 2 planning completes:
1. Execute `/speckit.tasks` to generate detailed task breakdown
2. Implement following TDD principles where applicable (container build validation)
3. Create PR with `.devcontainer/` configuration and updated documentation
4. Test across platforms (macOS, Linux, Windows) before merge

## Notes

- This feature enhances developer experience but does not modify runtime behavior
- Existing local development workflow remains fully supported
- No changes to Gratan's CLI, library, or DSL
- Success measured by onboarding time reduction and contributor feedback
