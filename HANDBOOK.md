# OffSec Assistant — Project Handbook

> Strategic reference and governance handbook for the OffSec Assistant project.
>
> GitHub is the operational source of truth for execution tracking.
>
> This handbook defines project governance, release planning, issue management,
> milestone structure, and long-term platform direction.
>
> Day-to-day execution must be managed through GitHub Milestones, EPICs,
> Child Issues, Labels, Projects, and Pull Requests.

---

# Project Governance Model

OffSec Assistant follows a GitHub-native project management model.

Planning and execution are managed through:

- GitHub Milestones
- EPIC Issues
- Child Issues
- Labels
- GitHub Projects
- Pull Requests

This handbook serves as the authoritative strategic reference.

GitHub serves as the authoritative operational reference.

---

# Project Documentation Structure

## HANDBOOK.md

Strategic project reference.

Defines:

- Governance model
- Release roadmap
- Milestone objectives
- Issue conventions
- Planning standards

---

## CHANGELOG.md

Release history.

Tracks:

- Released features
- Fixes
- Security improvements
- Breaking changes

Versioning follows Semantic Versioning.

---

## CONTRIBUTING.md

Contributor onboarding and development standards.

Defines:

- Branching strategy
- Pull request workflow
- Commit conventions
- Coding standards
- Review process

---

## GitHub Milestones

Represent versioned release objectives.

Examples:

- v1.1.0 — Core Stability & Hardening
- v1.2.0 — DLP v2: Encryption & Vault
- v2.1.0 — Threat Intelligence

---

## GitHub EPICs

Represent major functional domains within a milestone.

Examples:

- [EPIC] Core Stability & Hardening
- [EPIC] Governance & Forensic Audit
- [EPIC] Threat Intelligence
- [EPIC] DevSecOps Pipeline

---

## GitHub Child Issues

Represent executable work items.

All implementation work must occur through Child Issues.

---

# GitHub Label Taxonomy

Every issue must contain:

- One Type label
- One Priority label
- One Domain label

Additional labels are optional.

---

## Type Labels

| Label | Description |
|---------|---------|
| Feature | New capability or functionality |
| Bug | Defect or unintended behavior |
| Vulnerability | Security weakness requiring remediation |
| Refactor | Internal restructuring without behavior change |
| Documentation | Documentation work |
| Testing | Validation and test coverage |
| CI/CD | Build, release and automation work |
| Conflict | Architectural or dependency blocker |

---

## Priority Labels

| Label | Description |
|---------|---------|
| P0 | Critical release blocker |
| P1 | High priority |
| P2 | Medium priority |
| P3 | Low priority |

---

## Domain Labels

| Label | Description |
|---------|---------|
| Core | Core framework and architecture |
| Agents | Agent definitions and orchestration |
| Commands | Slash commands |
| DLP | Data Loss Prevention subsystem |
| Reporting | Report generation |
| Recon | Reconnaissance workflows |
| Vulnerability Management | Vulnerability discovery workflows |
| Exploitation | Exploitation workflows |
| Threat Intelligence | IOC enrichment and intelligence integrations |
| Integrations | Third-party platforms and APIs |
| DevSecOps | CI/CD and platform security |
| Documentation | Documentation assets |

---

# Issue Hierarchy

The project follows a hierarchical planning structure.

Milestone
└── EPIC
    └── Child Issues

Example:

v2.1.0 — Threat Intelligence
└── [EPIC] Threat Intelligence
    ├── feat(ti): implement MISP IOC correlation
    ├── feat(ti): implement OpenCTI enrichment
    └── feat(ti): implement AbuseIPDB enrichment

---

# EPIC Convention

EPIC titles must follow:

[EPIC] <Milestone Domain>

Examples:

[EPIC] Core Stability & Hardening

[EPIC] DLP v2: Encryption & Vault

[EPIC] Threat Intelligence

[EPIC] Enterprise Platform & Public API

---

# Child Issue Convention

GitHub issue numbering is the authoritative identifier.

Manual numbering is prohibited.

Child issues must follow Conventional Commit naming patterns.

---

## Feature Issues

Format:

feat(<domain>): <description>

Examples:

feat(commands): add configurable scan profiles

feat(dlp): implement age encryption for findings

feat(ti): implement MISP IOC correlation

feat(api): implement engagement CRUD endpoints

---

## Bug Issues

Format:

fix(<domain>): <description>

Examples:

fix(commands): validate scope.md minimum structure

fix(core): handle SIGINT and SIGTERM gracefully

fix(reporting): prevent empty CVSS table generation

---

## Vulnerability Issues

Format:

vuln(<domain>): <description>

Examples:

vuln(dlp): prevent accidental staging of dlp-map.json

vuln(core): remove Docker socket exposure

vuln(integrations): prevent API key disclosure in logs

---

## Refactor Issues

Format:

refactor(<domain>): <description>

Examples:

refactor(core): standardize shell error handling

refactor(commands): centralize command validation

---

## Documentation Issues

Format:

docs(<domain>): <description>

Examples:

docs(reporting): document audit trail schema

docs(core): update architecture documentation

---

## Testing Issues

Format:

test(<domain>): <description>

Examples:

test(dlp): add IPv6 tokenization coverage

test(core): add integration tests for autonomous execution

---

## CI/CD Issues

Format:

ci(<domain>): <description>

Examples:

ci(devsecops): implement Trivy image scanning

ci(devsecops): implement semantic release workflow

---

# Bug Management

Bugs are operational issues.

They may exist independently from milestones unless they directly impact milestone delivery.

Required labels:

Type:
- Bug

Priority:
- P0
- P1
- P2
- P3

Domain:
- Applicable subsystem

Example:

fix(commands): morning-brief fails when findings directory is empty

---

# Vulnerability Management

Security weaknesses are tracked independently from features.

Required labels:

Type:
- Vulnerability

Priority:
- P0
- P1
- P2
- P3

Domain:
- Applicable subsystem

Example:

vuln(core): prevent secret leakage in logs

---

# Conflict Management

Conflicts represent blockers that prevent project progress.

Examples:

- Architectural disagreements
- Breaking changes
- Dependency incompatibilities
- External API changes
- Licensing concerns

Naming convention:

conflict(<domain>): <description>

Examples:

conflict(core): DLP encryption architecture decision

conflict(integrations): HTB API compatibility issue

conflict(devsecops): container hardening strategy

---

# Release Roadmap

| Milestone | Version | Status |
|------------|------------|------------|
| Core Stability & Hardening | v1.1.0 | Planned |
| DLP v2: Encryption & Vault | v1.2.0 | Planned |
| Execution Optimization | v1.3.0 | Planned |
| Governance & Forensic Audit | v1.4.0 | Planned |
| CTF Platform Module | v2.0.0 | Planned |
| Threat Intelligence | v2.1.0 | Planned |
| Multi-Engagement Dashboard | v2.2.0 | Planned |
| DevSecOps Pipeline | v2.3.0 | Planned |
| Context-Aware Payload Engine | v2.4.0 | Planned |
| Enterprise Platform & Public API | v3.0.0 | Vision |

---

# Milestone Template

Every milestone section must follow this structure.

## Milestone — vX.Y.Z · Name

GitHub Milestone:

vX.Y.Z - Name

EPIC:

[EPIC] Name

Objective:

Describe the strategic goal of the release.

Child Issues:

- feat(...)
- fix(...)
- vuln(...)
- refactor(...)
- docs(...)
- test(...)

---

# Definition of Done

A Child Issue is complete when:

- Implementation completed
- Tests completed
- Documentation updated
- Pull Request merged
- GitHub Issue closed

---

# Milestone Closure Rules

A milestone can only be closed when:

- All child issues are closed

OR

- Deferred issues have been reassigned to another milestone

No milestone may be closed while active work remains open.

---

# Versioning Policy

This project follows Semantic Versioning.

MAJOR

Breaking architectural changes.

MINOR

New milestone completed.

PATCH

Bug fixes, security fixes, documentation updates, or maintenance work.

---

# Relationship With CHANGELOG

Every merged issue that produces an observable change must generate an entry under:

[Unreleased]

inside CHANGELOG.md before merge.

---

Last Updated: 2026-06-13
Current Baseline Release: v1.0.0
