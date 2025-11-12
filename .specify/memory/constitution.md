# Gratan Constitution

<!--
Sync Impact Report:
- Version: INITIAL → 1.0.0 (Initial constitution establishment)
- New constitution created with 7 core principles
- Sections added: Core Principles, Testing Standards, Quality Gates, Governance
- Templates Status:
  ✅ plan-template.md - updated with Constitution Check gates and Ruby Gem structure
  ✅ spec-template.md - reviewed, already aligned with constitution principles
  ✅ tasks-template.md - updated with TDD requirements and Ruby/RSpec conventions
- No deferred placeholders - all values derived from repository context
- Follow-up: None required
-->

## Core Principles

### I. DSL-First Design
Gratan is a declarative configuration management tool. Every permission management
feature MUST be expressible through the Ruby DSL. The DSL is the primary interface;
implementation details remain hidden. DSL syntax MUST be:
- Human-readable and self-documenting
- Composable (templates, includes, inheritance)
- Validatable before application
- Version-controllable

**Rationale**: Configuration as code enables audit trails, peer review, and repeatable
deployments. DSL clarity reduces operational errors in production database security.

### II. Idempotency & Dry-Run (NON-NEGOTIABLE)
All operations MUST be idempotent. Running the same Grantfile multiple times produces
the same database state. Dry-run mode MUST be available for all state-changing
operations to preview changes without modification.

**Rationale**: Database permission changes are high-risk operations. Idempotency
enables safe retries; dry-run prevents accidental privilege escalation or data exposure.

### III. Test-Driven Development (NON-NEGOTIABLE)
TDD is mandatory for all features. Tests MUST be written before implementation. The
Red-Green-Refactor cycle is strictly enforced:
1. Write failing test(s)
2. Implement minimal code to pass
3. Refactor with tests passing
4. No production code without corresponding tests

**Rationale**: Gratan manages critical database security. Untested code poses
unacceptable risk. TDD ensures specification clarity before implementation.

### IV. Integration Testing with Real Database
Unit tests alone are insufficient. Integration tests MUST use real MySQL instances
(via Docker Compose) to verify:
- Grant application and revocation
- Permission state export accuracy
- User creation and expiration
- Template expansion correctness
- Multi-host and wildcard patterns
- Version compatibility (MySQL 5.6, 5.7, 8.0+)

**Rationale**: MySQL permission semantics vary by version. Mock testing cannot catch
subtle grant behavior differences. Real database tests prevent production failures.

### V. CLI & Library Interface
Gratan operates both as a standalone CLI tool and as an embeddable library. New
features MUST support both modes:
- **CLI**: Human-friendly output, colorized diffs, dry-run flags, environment variable
  configuration
- **Library**: Programmatic API with `Gratan::Client`, structured result objects,
  error exceptions

**Rationale**: CLI serves operators; library API enables integration with automation
systems, deployment pipelines, and custom tooling.

### VI. Backward Compatibility & Versioning
Breaking changes require MAJOR version bump. MINOR versions add features while
maintaining compatibility. PATCH versions fix bugs without behavioral changes.
Deprecations MUST:
- Warn for at least one MINOR version
- Document migration path in CHANGELOG
- Provide automatic upgrade assistance where feasible

**Rationale**: Gratan manages security-critical infrastructure. Surprise breakage
in permission management creates operational incidents.

### VII. Observability & Auditing
All state-changing operations MUST log:
- User/host affected
- Permissions granted/revoked
- Timestamp and operator identity
- Dry-run vs. applied status

Export operations MUST produce deterministic, diffable output. Debug mode (`--debug`
flag) MUST show raw SQL executed.

**Rationale**: Security audits require traceability. Deterministic exports enable
Git-based change tracking. Debug visibility aids troubleshooting.

## Testing Standards

### Required Test Coverage
- **Unit tests**: DSL parsing, validation, internal logic
- **Integration tests**: Full workflows (export → modify DSL → apply) against real MySQL
- **Regression tests**: Known issues from production incidents
- **Version compatibility tests**: Matrix testing across MySQL 5.6, 5.7, 8.0+

### Test Organization
- `spec/integration/` - Database-dependent workflows
- `spec/change/` - Grant modification scenarios
- `spec/create/` - User creation scenarios
- `spec/drop/` - User deletion/expiration scenarios
- `spec/export/` - Export accuracy and format scenarios
- `spec/misc/` - Miscellaneous functionality tests

### Test Data
- Docker Compose MUST provide isolated MySQL instances (ports 14406, 14407)
- Tests MUST clean state before execution (`clean_grants` helper)
- Test databases MUST use predictable naming (`gratan_test`)

## Quality Gates

### Pre-Commit
- RSpec suite passes (all tests green)
- No Ruby syntax errors
- Gemspec dependencies resolved

### Pre-Release
- Integration tests pass on all supported MySQL versions
- CHANGELOG updated with user-facing changes
- Version number bumped according to semver
- Travis CI build passes
- Manual smoke test: export → apply → verify on real MySQL

## Governance

This constitution supersedes all other development practices. All code reviews,
feature designs, and architectural decisions MUST comply with these principles.

**Amendment Process**:
1. Propose change via pull request to `.specify/memory/constitution.md`
2. Document rationale and impact analysis
3. Update version number and amendment date
4. Verify template consistency (plan, spec, tasks templates)
5. Obtain approval from project maintainers
6. Update dependent documentation (`README.md`, prompt files)

**Compliance Review**:
- Constitution violations MUST be justified in complexity tracking (see
  `plan-template.md`)
- Simplicity and YAGNI principles apply: complexity requires documented necessity
- Reviewers MUST verify TDD adherence: check test commit timestamps vs. implementation

**Runtime Guidance**:
Development agents and human contributors MUST consult
`.github/prompts/speckit.*.prompt.md` files for workflow-specific guidance aligned
with this constitution.

**Version**: 1.0.0 | **Ratified**: 2025-11-11 | **Last Amended**: 2025-11-11
