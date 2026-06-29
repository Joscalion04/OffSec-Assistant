# OffSec Assistant — Progress & Phases

> Master execution tracker for OffSec Assistant.
>
> This document mirrors the GitHub project structure and serves as the operational
> reference for project execution.
>
> GitHub remains the source of truth for:
>
> - Milestones
> - EPICs
> - Child Issues
> - Labels
> - Status
> - Assignments
> - Dependencies
>
> This file exists to provide strategic visibility, implementation order,
> release planning, and project governance.

---

# Project Governance

## GitHub Project Structure

Every release milestone follows the hierarchy:

```text
Milestone
└── EPIC
    ├── Child Issue
    ├── Child Issue
    ├── Child Issue
    └── Child Issue
```

Example:

```text
Milestone:
v1.1.0 — Core Stability & Hardening

└── [EPIC] Core Stability & Hardening

    ├── fix(scope): validate minimum scope.md structure
    ├── fix(runtime): implement graceful SIGINT handling
    ├── fix(dlp): add IPv6 tokenization support
    └── feat(config): implement scan profiles
```

---

## Issue Naming Convention

### EPIC

Format:

```text
[EPIC] <Milestone Name>
```

Examples:

```text
[EPIC] Core Stability & Hardening
[EPIC] DLP v2: Encryption & Vault
[EPIC] Governance & Forensic Auditing
```

---

### Child Issues

Format:

```text
<type>(<domain>): <description>
```

Examples:

```text
fix(scope): validate minimum scope.md structure

fix(runtime): implement graceful SIGINT cleanup

feat(dlp): add IPv6 tokenization support

feat(vault): integrate HashiCorp Vault authentication

refactor(shell): centralize error handling library

docs(manual): document scan profiles

test(dlp): add IPv6 tokenization coverage
```

---

## Required Labels

Every issue must contain:

### Domain Label

Examples:

```text
Core
Commands
Agents
DLP
Telemetry
Vault
Security
Docker
Reporting
Threat-Intelligence
CTF
Governance
Audit
Dashboard
DevSecOps
API
RBAC
Documentation
Testing
```

---

### Type Label

Exactly one:

```text
Feature
Bug
Security
Refactor
Documentation
Testing
CI/CD
```

---

### Priority Label

Exactly one:

```text
P0
P1
P2
P3
```

Meaning:

| Priority | Description |
|-----------|-------------|
| P0 | Release blocker |
| P1 | Critical functionality |
| P2 | Important improvement |
| P3 | Nice-to-have |

---

### Status Label

Exactly one:

```text
Status: Backlog
Status: Ready
Status: In Progress
Status: Review
Status: Blocked
Status: Done
```

---

## Release Management Rules

### Milestone Closure

A milestone can only be closed when:

- All EPICs are completed
- All child issues are closed
- Remaining work is explicitly moved to a future milestone
- CHANGELOG is updated

---

### Versioning

Semantic Versioning:

```text
MAJOR = Architectural changes

MINOR = Completed milestone

PATCH = Bug fixes and security updates
```

Examples:

```text
v1.0.0
v1.1.0
v1.2.0
v2.0.0
```

---

# Current Release Status

| Milestone | Version | Focus | Status |
|------------|----------|--------|---------|
| M1 | v1.1.0 | Core Stability & Hardening | In Review |
| M2 | v1.2.0 | DLP v2: Encryption & Vault | Planned |
| M3 | v1.3.0 | Execution Optimization | Planned |
| M4 | v1.4.0 | Governance & Forensic Auditing | Planned |
| M5 | v2.0.0 | CTF & Platform Integrations | Planned |
| M6 | v2.1.0 | Threat Intelligence | Planned |
| M7 | v2.2.0 | Multi-Engagement Dashboard | Backlog |
| M8 | v2.3.0 | DevSecOps Pipeline | Backlog |
| M9 | v2.4.0 | Contextual Payload Engine | Backlog |
| M10 | v3.0.0 | Enterprise & Public API | Vision |

---

# M1 — v1.1.0 · Core Stability & Hardening

## Objective

Consolidate the v1.0.0 foundation before introducing major capabilities.

The focus of this milestone is reliability, error handling,
scope enforcement, DLP robustness, operational safety,
and execution consistency.

---

## EPIC

```text
[EPIC] Core Stability & Hardening
```

### Child Issues

#### fix(scope): validate minimum scope.md structure

**Labels**

```text
Core
Bug
P1
Status: Done
```

The current scope gate only validates file existence.

Implement validation that guarantees at least one valid target
is declared before any active operation can execute.

**Acceptance Criteria**

- [x] Detect empty scope files
- [x] Detect comment-only files
- [x] Provide descriptive error messages
- [x] Update scope template documentation

---

#### fix(runtime): implement graceful SIGINT/SIGTERM cleanup

**Labels**

```text
Core
Bug
P1
Status: Done
```

Autonomous executions must terminate safely.

**Acceptance Criteria**

- [x] Handle SIGINT
- [x] Handle SIGTERM
- [x] Terminate child processes
- [x] Write interruption markers to logs
- [x] Prevent orphaned scans

---

#### fix(dlp): add IPv6 tokenization support

**Labels**

```text
DLP
Bug
P1
Status: Done
```

Current DLP only recognizes IPv4 addresses.

**Acceptance Criteria**

- [x] IPv6 support
- [x] Compressed IPv6 support
- [x] IPv6 CIDR support
- [x] Test coverage
- [x] Documentation updates

---

#### fix(commands): improve morning-brief empty-state handling

**Labels**

```text
Commands
Bug
P2
Status: Done
```

Handle clean installations gracefully.

**Acceptance Criteria**

- [x] Detect missing findings directory
- [x] Detect empty engagements
- [x] Display onboarding guidance

---

#### fix(reporting): validate incomplete CVSS data

**Labels**

```text
Reporting
Bug
P2
Status: Done
```

**Acceptance Criteria**

- [x] Detect incomplete CVSS fields
- [x] Display warnings
- [x] Draft mode support

---

#### fix(integrations): expose configurable Burp timeout

**Labels**

```text
Commands
Bug
P3
Status: Done
```

**Acceptance Criteria**

- [x] CLI timeout option
- [x] Environment variable support

---

#### refactor(shell): centralize runtime error handling

**Labels**

```text
Core
Refactor
P2
Status: Done
```

**Acceptance Criteria**

- [x] Shared lib.sh
- [x] Standardized exit codes
- [x] Common validation helpers

---

#### feat(config): implement scan profile system

**Labels**

```text
Commands
Feature
P2
Status: Done
```

**Acceptance Criteria**

- [x] Silent profile
- [x] Standard profile
- [x] Aggressive profile
- [x] YAML configuration
- [x] Documentation

---

#### feat(cli): implement host-side offsec CLI and install.sh

**Labels**

```text
Core
Docker
Feature
P2
Status: Done
```

Added as unplanned work during M1 execution.

**Acceptance Criteria**

- [x] offsec CLI v1.1.0 con comandos: start, down, restart, in, status, logs, build
- [x] install.sh bootstrap con detección de deps, PATH y .env
- [x] Docker daemon mode (tail -f /dev/null) — exit no mata el contenedor
- [x] SIGTERM handler en entrypoint para apagado limpio
- [x] restart: unless-stopped en docker-compose

---

# M2 — v1.2.0 · DLP v2: Encryption & Vault

## Objective

Protect customer data beyond tokenization.

Sensitive information must remain encrypted at rest and
credentials must be managed securely through centralized
secret management.

---

## EPIC

```text
[EPIC] DLP v2: Encryption & Vault
```

### Child Issues

#### feat(dlp): implement findings encryption at rest

**Labels**

```text
DLP
Feature
P1
Status: Backlog
```

Raw engagement data should never remain stored in plaintext.

**Acceptance Criteria**

- Age encryption support
- Per-engagement keys
- Automatic encryption workflow
- Secure backup procedures
- Manual lock/unlock commands

---

#### feat(vault): integrate HashiCorp Vault authentication

**Labels**

```text
Vault
Feature
P2
Status: Backlog
```

**Acceptance Criteria**

- AppRole support
- Vault credential retrieval
- Docker integration
- Graceful fallback

---

#### security(dlp): prevent accidental staging of dlp-map.json

**Labels**

```text
Security
Security
P1
Status: Backlog
```

**Acceptance Criteria**

- Pre-commit validation
- Git ignore protections
- Regression testing

---

#### feat(network-policy): restrict container egress to scope

**Labels**

```text
Docker
Feature
P2
Status: Backlog
```

**Acceptance Criteria**

- Scope-based egress generation
- IPTables enforcement
- Optional bypass mode
- Documentation

---

# M3 — v1.3.0 · Execution Optimization

## Objective

Reduce unnecessary execution time and improve operator productivity.

Enable caching, concurrency and offline capabilities.

---

## EPIC

```text
[EPIC] Execution Optimization
```

### Child Issues

#### feat(cache): implement reconnaissance cache engine

**Labels**

```text
Core
Feature
P1
Status: Backlog
```

**Acceptance Criteria**

- Scan TTL support
- Cache indexing
- Force refresh option
- Cached/live indicators

---

#### feat(runtime): implement multi-target parallel execution

**Labels**

```text
Core
Feature
P2
Status: Backlog
```

**Acceptance Criteria**

- Multi-target support
- Concurrency controls
- Parallel output management
- Sequential fallback mode

---

#### feat(cve): implement offline CVE database

**Labels**

```text
Threat-Intelligence
Feature
P2
Status: Backlog
```

**Acceptance Criteria**

- Local SQLite storage
- NVD synchronization
- Offline correlation
- Update command

---

#### feat(storage): archive completed engagements

**Labels**

```text
Core
Feature
P3
Status: Backlog
```

**Acceptance Criteria**

- Zstandard compression
- Archive workflow
- Manual archive commands

---

# M4 — v1.4.0 · Governance & Forensic Auditing

## Objective

Provide enterprise-grade governance,
traceability,
evidence integrity,
and non-repudiation.

---

## EPIC

```text
[EPIC] Governance & Forensic Auditing
```

### Child Issues

#### feat(audit): implement chain-of-custody validation

**Labels**

```text
Governance
Feature
P1
Status: Backlog
```

**Acceptance Criteria**

- SHA256 evidence tracking
- Verification command
- Report validation integration

---

#### feat(audit): implement structured audit trail

**Labels**

```text
Audit
Feature
P1
Status: Backlog
```

**Acceptance Criteria**

- JSON schema
- SIEM compatibility
- JSONL export
- Documentation

---

#### feat(governance): implement read-only review mode

**Labels**

```text
Governance
Feature
P2
Status: Backlog
```

**Acceptance Criteria**

- Reviewer mode
- Active operation restrictions
- Visual indicators

---

#### feat(reporting): implement report signing

**Labels**

```text
Reporting
Feature
P2
Status: Backlog
```

**Acceptance Criteria**

- GPG signing
- Verification workflow
- Documentation

---

#### feat(templates): implement template version management

**Labels**

```text
Documentation
Feature
P3
Status: Backlog
```

**Acceptance Criteria**

- Template versioning
- Migration warnings
- Upgrade tooling

---

# M5 — v2.0.0 · CTF & Platform Integrations

## Objective

Introduce first-class support for educational
and lab platforms.

Enable complete engagement lifecycle integration
with external training ecosystems.

---

## EPIC

```text
[EPIC] CTF & Platform Integrations
```

### Child Issues

#### feat(htb): implement Hack The Box integration

**Labels**

```text
CTF
Feature
P1
Status: Backlog
```

**Acceptance Criteria**

- HTB authentication
- Machine provisioning
- Scope synchronization
- Flag submission
- Auto shutdown

---

#### feat(thm): implement TryHackMe integration

**Labels**

```text
CTF
Feature
P2
Status: Backlog
```

**Acceptance Criteria**

- THM authentication
- Room initialization
- VM synchronization
- Task tracking

---

#### feat(ctf): implement engagement-aware CTF workflows

**Labels**

```text
CTF
Feature
P2
Status: Backlog
```

**Acceptance Criteria**

- Dedicated engagement type
- Flag tracking
- Progress visibility
- CTF report generation

---

#### feat(importers): implement platform metadata import

**Labels**

```text
CTF
Feature
P3
Status: Backlog
```

**Acceptance Criteria**

- YAML support
- JSON support
- Automatic context enrichment

---

# M6 — v2.1.0 · Threat Intelligence

## Objective

Correlate engagement findings with
external intelligence sources.

Provide contextual awareness around
observed infrastructure, indicators,
and adversary activity.

---

## EPIC

```text
[EPIC] Threat Intelligence
```

### Child Issues

#### feat(misp): implement IOC correlation via MISP

**Labels**

```text
Threat-Intelligence
Feature
P1
Status: Backlog
```

**Acceptance Criteria**

- PyMISP integration
- Automatic IOC enrichment
- Threat context generation
- Manual lookup support

---

#### feat(opencti): implement OpenCTI enrichment

**Labels**

```text
Threat-Intelligence
Feature
P2
Status: Backlog
```

**Acceptance Criteria**

- GraphQL client
- Observable enrichment
- STIX export support

---

#### feat(enrichment): implement public threat feed integrations

**Labels**

```text
Threat-Intelligence
Feature
P2
Status: Backlog
```

**Acceptance Criteria**

- AbuseIPDB integration
- Shodan integration
- VirusTotal integration
- DLP-safe processing

---

#### feat(correlation): implement threat actor correlation

**Labels**

```text
Threat-Intelligence
Feature
P3
Status: Backlog
```

**Acceptance Criteria**

- MITRE correlation
- Actor mapping
- Executive reporting integration

---
