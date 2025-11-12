# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Update values below for each feature. Use Gratan defaults or mark
  NEEDS CLARIFICATION.
-->

**Language/Version**: Ruby 2.x+ (check .ruby-version if present)
**Primary Dependencies**: mysql2, term-ansicolor, deep_merge, hashie
**Storage**: MySQL 5.6/5.7/8.0 (tested via Docker Compose)
**Testing**: RSpec 3.x, Docker Compose for integration tests
**Target Platform**: Linux/macOS servers, CLI and library usage
**Project Type**: Ruby Gem (single project structure)
**Performance Goals**: Sub-second dry-run for <1000 grants, efficient bulk operations
**Constraints**: MySQL-specific (no PostgreSQL/other RDBMS), DSL must remain backward
compatible
**Scale/Scope**: Hundreds of users, thousands of grants per database cluster

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [ ] **DSL-First Design**: Feature expressible through Ruby DSL? Templates/includes
  supported?
- [ ] **Idempotency & Dry-Run**: Operations idempotent? Dry-run mode available?
- [ ] **TDD (NON-NEGOTIABLE)**: Tests written before implementation? Red-Green-Refactor
  cycle planned?
- [ ] **Integration Testing**: Real MySQL test scenarios identified? Version
  compatibility checked?
- [ ] **CLI & Library Interface**: Both CLI and programmatic API supported?
- [ ] **Backward Compatibility**: Breaking changes justified? Deprecation warnings
  planned?
- [ ] **Observability & Auditing**: Logging of state changes? Deterministic export
  format?

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths. The delivered plan must not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Ruby Gem (DEFAULT for Gratan)
lib/
├── gratan/
│   ├── dsl/
│   ├── ext/
│   ├── identifier/
│   └── [feature modules]
└── gratan.rb

spec/
├── integration/
│   ├── user_management/
│   ├── grant_management/
│   ├── export/
│   └── filtering/
├── change/
├── create/
├── drop/
├── export/
└── misc/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
