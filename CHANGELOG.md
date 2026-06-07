# Changelog

All notable changes to OffSec Assistant are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

## [1.0.0] — 2026-06-07

### Added
- Initial release of OffSec Assistant
- Agent system: `decision-advisor`, `doc-writer`, `penetration-tester`
- Slash commands: `/new-engagement`, `/recon`, `/vuln-scan`, `/exploit`, `/think`,
  `/explain`, `/report`, `/status`, `/morning-brief`, `/session-close`,
  `/check-tools`, `/livefeed`, `/help`
- Autonomous mode (`-auto` flag) for `/recon`, `/vuln-scan`, and `/exploit`
- Live feed log system (`logs/livefeed/`) for autonomous execution monitoring
- Per-engagement git repository initialization
- Session logging to `logs/session_YYYY-MM-DD.log`
- Finding templates with CVSS 3.1 fields
- Scope-gate enforcement: no active scanning without a valid `scope.md`
- Report generation: executive summary + full technical report in Spanish
- Tools: `auto-runner.sh`, `logger.sh`, `run-recon.sh`, `run-vuln-scan.sh`
- Templates: `context.md`, `finding.md`, `scope.md`
- CLAUDE.md with full agent identity and workflow definition

---

[Unreleased]: https://github.com/Joscalion04/OffSec-Assistant/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Joscalion04/OffSec-Assistant/releases/tag/v1.0.0
