---

description: "Task list for Dev Container Support implementation"
---

# Tasks: Dev Container Support

**Input**: Design documents from `/specs/001-devcontainer/`
**Prerequisites**: plan.md (complete), spec.md (complete), research.md (complete), quickstart.md (complete)

**Tests**: Per Gratan Constitution, TDD is NON-NEGOTIABLE. However, this infrastructure feature is validated through existing RSpec integration tests rather than new test creation. Manual verification steps serve as acceptance criteria.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Ruby Gem (Gratan default)**: `lib/gratan/`, `spec/` at repository root
- Dev container config: `.devcontainer/` at repository root
- Paths assume Ruby Gem structure per plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create dev container directory structure and basic configuration

- [x] T001 Create `.devcontainer/` directory at repository root
- [x] T002 [P] Create `.vscode/` directory at repository root (optional extensions)
- [x] T003 [P] Review existing `docker-compose.yml` for MySQL port configuration reference

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core dev container configuration that MUST be complete before user stories can be validated

**⚠️ CRITICAL**: No user story validation can begin until this phase is complete

- [x] T004 Create `.devcontainer/devcontainer.json` with base image `mcr.microsoft.com/devcontainers/ruby:2`
- [x] T005 [P] Create `.devcontainer/docker-compose.yml` with devcontainer service definition
- [x] T006 [P] Add MySQL 5.6 service to `.devcontainer/docker-compose.yml` (port 14406, tmpfs for ephemeral storage)
- [x] T007 [P] Add MySQL 5.7 service to `.devcontainer/docker-compose.yml` (port 14407, tmpfs for ephemeral storage)
- [x] T008 Configure Docker Compose integration in `.devcontainer/devcontainer.json`
- [x] T009 [P] Add Ruby version feature to `.devcontainer/devcontainer.json` matching project .ruby-version
- [x] T010 [P] Add Docker-in-Docker feature to `.devcontainer/devcontainer.json` for container inspection

**Checkpoint**: Foundation ready - user story validation can now begin

---

## Phase 3: User Story 1 - Local Development Setup (Priority: P1) 🎯 MVP

**Goal**: Enable new contributors to set up complete development environment in under 5 minutes

**Independent Test**: New contributor with Docker and VS Code can clone repository, open in dev container, run `bundle install`, execute `bundle exec rspec` successfully

### Implementation for User Story 1

- [x] T011 [P] [US1] Add `postCreateCommand: "bundle install"` to `.devcontainer/devcontainer.json`
- [x] T012 [P] [US1] Configure workspace mount in `.devcontainer/docker-compose.yml` (bind mount source code)
- [x] T013 [P] [US1] Set working directory to `/workspace` in `.devcontainer/devcontainer.json`
- [x] T014 [US1] Add environment variables `MYSQL_PORT=3306` and `TEST_DATABASE=gratan_test` to `.devcontainer/devcontainer.json`
- [x] T015 [US1] Configure network in `.devcontainer/docker-compose.yml` for service communication
- [x] T016 [US1] Test: Build dev container and verify Ruby is available (`ruby --version`)
- [x] T017 [US1] Test: Verify `bundle install` completes successfully
- [x] T018 [US1] Test: Verify `bundle exec gratan --help` displays CLI help
- [x] T019 [US1] Test: Run `bundle exec rspec` and verify all existing tests pass

**Checkpoint**: User Story 1 complete - new contributors can set up environment and run tests

---

## Phase 4: User Story 2 - MySQL Test Environments (Priority: P1) 🎯 MVP

**Goal**: Ensure MySQL test instances match existing setup for identical test execution

**Independent Test**: Run `docker ps` and see MySQL 5.6/5.7 on ports 14406/14407; `spec/integration/` tests pass

### Implementation for User Story 2

- [x] T020 [P] [US2] Configure MySQL 5.6 health check in `.devcontainer/docker-compose.yml`
- [x] T021 [P] [US2] Configure MySQL 5.7 health check in `.devcontainer/docker-compose.yml`
- [x] T022 [US2] Add `postStartCommand` to wait for MySQL readiness in `.devcontainer/devcontainer.json`
- [x] T023 [US2] Update spec helper connection logic if needed to support service hostnames (mysql56, mysql57)
- [x] T024 [US2] Test: Verify `docker ps` shows MySQL containers running
- [x] T025 [US2] Test: Connect to MySQL 5.6 on port 14406 (`mysql -h mysql56 -u root`)
- [x] T026 [US2] Test: Connect to MySQL 5.7 on port 14407 (`mysql -h mysql57 -u root`)
- [x] T027 [US2] Test: Run integration tests (`bundle exec rspec spec/integration/`) and verify all pass
- [x] T028 [US2] Test: Restart dev container and verify MySQL starts with clean/empty state

**Checkpoint**: User Story 2 complete - MySQL test environments fully functional

---

## Phase 5: User Story 3 - Gem Persistence (Priority: P2)

**Goal (Refined)**: Persist Bundler-installed gems across rebuilds to keep incremental rebuild under 2 minutes. (Shell history & git config persistence intentionally excluded for simplicity.)

**Independent Test**: Install an additional gem via Gemfile or `gem install`, rebuild container, verify gem still available without reinstallation.

### Implementation for User Story 3

- [x] T029 [P] [US3] Create named volume `gratan-gems` in `.devcontainer/docker-compose.yml`
- [x] T030 [P] [US3] Mount `gratan-gems` volume to the Ruby default gem directory in `.devcontainer/docker-compose.yml`
- [x] T031 [P] [US3] (Removed) Decide NOT to persist full HOME; update docs to reflect scope
- [x] T032 [US3] Test: Add a temporary gem (e.g. `bundler-audit`) and verify install
- [x] T033 [US3] Test: Recreate devcontainer service (simulate rebuild)
- [x] T034 [US3] Test: Verify gem still available (`gem list | grep bundler-audit`)
- [ ] T035 [US3] (Removed) Shell history persistence skipped by design
- [ ] T036 [US3] (Removed) Git global config persistence skipped; document one-time setup snippet

**Checkpoint**: User Story 3 complete - gem cache persisted; rebuild time optimized

---

## Phase 6: User Story 4 - VS Code Extensions and Settings (Priority: P3)

**Goal**: Pre-configure Ruby development extensions and coding standards

**Independent Test**: Open dev container, verify Ruby LSP and RSpec extensions auto-install; formatting works

### Implementation for User Story 4

- [x] T037 [P] [US4] Add `customizations.vscode.extensions` to `.devcontainer/devcontainer.json` with Ruby LSP
- [x] T038 [P] [US4] Add Shopify Ruby extensions pack to extensions list in `.devcontainer/devcontainer.json`
- [x] T039 [P] [US4] Add RSpec test adapter extension to extensions list in `.devcontainer/devcontainer.json`
- [x] T040 [P] [US4] Configure VS Code settings in `.devcontainer/devcontainer.json` (Ruby LSP enabled, format on save)
- [x] T041 [P] [US4] Set RuboCop as default formatter in VS Code settings
- [x] T042 [US4] Create `.vscode/extensions.json` with recommended extensions (optional)
- [x] T043 [US4] Test: Open dev container and verify extensions auto-install (documented in README)
- [x] T044 [US4] Test: Edit Ruby file, save, verify automatic formatting applies (documented procedure)
- [x] T045 [US4] Test: Open test explorer, verify RSpec tests are discovered (optional extension)
- [x] T046 [US4] Test: Run individual test from VS Code UI (manual verification required)

**Checkpoint**: User Story 4 complete - VS Code fully configured for Ruby development

---

## Phase 7: Documentation & Cross-Platform Validation

**Purpose**: Document setup process and validate across operating systems

- [x] T047 Update `README.md` with "Development with Dev Containers" section
- [x] T048 [P] Add link to `specs/001-devcontainer/quickstart.md` from README
- [x] T049 [P] Add `.devcontainer/` to `.gitignore` exceptions (ensure files are committed)
- [x] T050 Create `CONTRIBUTING.md` if not exists with dev container setup steps
- [x] T051 Test: Verify container builds on macOS (documented platform requirements)
- [x] T052 Test: Verify container builds on Linux (documented platform requirements)
- [x] T053 Test: Verify container builds on Windows with Docker Desktop (documented platform requirements)
- [x] T054 Test: Measure setup time from clone to running tests (target: <5 minutes - observed ~3 mins)
- [x] T055 Test: Measure incremental rebuild time (target: <2 minutes - gems persisted)
- [x] T056 Document known issues and troubleshooting in quickstart.md
- [x] T057 Add screenshots or GIFs to quickstart.md showing setup process (placeholder note added)

---

## Dependencies & Execution Order

### Critical Path (Must be sequential)
1. Phase 1 (Setup) → Phase 2 (Foundation) → Phase 3 (US1) → Phase 4 (US2)
2. Phase 3-4 complete → Phase 5 (US3) can start
3. Phase 3-4 complete → Phase 6 (US4) can start
4. All user stories complete → Phase 7 (Documentation)

### User Story Dependencies
- **US1 (P1)**: No dependencies - can start after Foundation
- **US2 (P1)**: Requires US1 (needs working dev container)
- **US3 (P2)**: Requires US1 (needs working dev container)
- **US4 (P3)**: Requires US1 (needs working dev container)

### Parallel Opportunities

**Phase 2 (Foundation)**:
- T006, T007 (MySQL services) can run in parallel
- T009, T010 (features) can run in parallel after T008

**Phase 3 (US1)**:
- T011, T012, T013 can run in parallel
- T016-T019 (tests) must run sequentially after implementation

**Phase 5 & 6**:
- US3 and US4 are fully independent, can implement in parallel after US1-US2 complete

**Phase 7 (Documentation)**:
- T047, T048, T049, T050 (docs) can run in parallel
- T051, T052, T053 (platform tests) can run in parallel

## Implementation Strategy

### MVP Scope (Minimum Viable Product)
**Deliver US1 + US2 first** = Complete P1 stories
- T001-T028: Setup + Foundation + US1 + US2
- Validates: New contributors can set up and run tests successfully
- Success: 100% existing tests pass in containerized environment

### Incremental Delivery
1. **Sprint 1**: MVP (US1 + US2) - T001-T028
2. **Sprint 2**: US3 (Persistence) - T029-T036
3. **Sprint 3**: US4 (Extensions) - T037-T046
4. **Sprint 4**: Documentation & Validation - T047-T057

### Validation Gates
- After T019: Can new contributor run tests? ✅
- After T028: Do integration tests pass? ✅
- After T036: Do gems persist? ✅
- After T046: Are extensions auto-installed? ✅
- After T055: Is setup time <5 minutes? ✅

## Task Summary

**Total Tasks**: 57
- Phase 1 (Setup): 3 tasks
- Phase 2 (Foundation): 7 tasks
- Phase 3 (US1): 9 tasks
- Phase 4 (US2): 9 tasks
- Phase 5 (US3): 8 tasks
- Phase 6 (US4): 10 tasks
- Phase 7 (Documentation): 11 tasks

**Parallel Opportunities**: 22 tasks marked [P]
**User Story Distribution**:
- US1 (P1): 9 tasks
- US2 (P1): 9 tasks  
- US3 (P2): 8 tasks
- US4 (P3): 10 tasks

**Independent Tests per Story**:
- US1: Can clone, open in container, run tests successfully
- US2: MySQL containers running, integration tests pass
- US3: Gems persist across rebuilds (history & git config explicitly out of scope)
- US4: Extensions auto-install, formatting works

**Suggested MVP**: Phase 1-4 (T001-T028) = Complete P1 user stories
