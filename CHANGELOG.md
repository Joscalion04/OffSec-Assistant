# Changelog

All notable changes to OffSec Assistant are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0](https://github.com/Joscalion04/OffSec-Assistant/compare/v1.0.0...v1.1.0) (2026-06-26)


### Features

* **config:** implement scan profile system ([cca2dd4](https://github.com/Joscalion04/OffSec-Assistant/commit/cca2dd432a7cada32801e474050b1dfc1b9aaf30))
* **m1-p1:** DLP IPv6, scope validation gate, SIGINT/SIGTERM cleanup ([5fe7b8a](https://github.com/Joscalion04/OffSec-Assistant/commit/5fe7b8a804e3c3ac31994256d38750ea357b3dca))
* **m1-p2:** lib.sh, scan profiles, Burp timeout, morning-brief, CVSS validation ([cca2dd4](https://github.com/Joscalion04/OffSec-Assistant/commit/cca2dd432a7cada32801e474050b1dfc1b9aaf30))


### Bug Fixes

* **commands:** improve morning-brief empty-state handling ([cca2dd4](https://github.com/Joscalion04/OffSec-Assistant/commit/cca2dd432a7cada32801e474050b1dfc1b9aaf30))
* **dlp:** add IPv6 tokenization support (RFC 5952) ([5fe7b8a](https://github.com/Joscalion04/OffSec-Assistant/commit/5fe7b8a804e3c3ac31994256d38750ea357b3dca))
* **integrations:** expose configurable Burp timeout ([cca2dd4](https://github.com/Joscalion04/OffSec-Assistant/commit/cca2dd432a7cada32801e474050b1dfc1b9aaf30))
* **reporting:** validate incomplete CVSS data in report command ([cca2dd4](https://github.com/Joscalion04/OffSec-Assistant/commit/cca2dd432a7cada32801e474050b1dfc1b9aaf30))
* **runtime:** implement graceful SIGINT/SIGTERM cleanup ([5fe7b8a](https://github.com/Joscalion04/OffSec-Assistant/commit/5fe7b8a804e3c3ac31994256d38750ea357b3dca))
* **scope:** validate minimum scope.md structure ([5fe7b8a](https://github.com/Joscalion04/OffSec-Assistant/commit/5fe7b8a804e3c3ac31994256d38750ea357b3dca))

## 1.0.0 (2026-06-26)


### Features

* ISSUES Roadmap ([48f1425](https://github.com/Joscalion04/OffSec-Assistant/commit/48f1425e4bbbf287a0a7b16994fbffade99add25))
* modulos de seguridad ofensiva — AD, privesc parser, Burp API, MITRE ([b429c64](https://github.com/Joscalion04/OffSec-Assistant/commit/b429c64c94b4e36a86f3e952848fd02f38b0808c))
* PROGRESS.md ([5b749bf](https://github.com/Joscalion04/OffSec-Assistant/commit/5b749bff23c4a49bda5ad95d20b4a8569fc733a4))


### Bug Fixes

* **docker:** agregar libssl-dev/libffi-dev y separar netexec en capa propia ([31979ea](https://github.com/Joscalion04/OffSec-Assistant/commit/31979ea0fc3ec21c9893c60be4b19f62dc23a260))
* **docker:** mover enum4linux-ng a apt — no existe en PyPI ([72fa915](https://github.com/Joscalion04/OffSec-Assistant/commit/72fa915c79016a4da79dd7122360535bf32675ce))
* **docker:** mover netexec a apt — no existe en PyPI ([c0987bd](https://github.com/Joscalion04/OffSec-Assistant/commit/c0987bd83fa726543ac610a49d4ebb317ffe69fd))
* **docker:** sacar resolvconf — conflicta con openresolv en Kali rolling ([15b24bf](https://github.com/Joscalion04/OffSec-Assistant/commit/15b24bf2b1b7593a01b908fb475390fc54942f3f))
* **docker:** usar --prefer-binary para evitar compilación de cryptography/Rust ([94a3dd0](https://github.com/Joscalion04/OffSec-Assistant/commit/94a3dd0d47e4b4d938eb303e7d0b2731a242ea3a))
* **docker:** usar venv para instalar Python tools — corrige PEP 668 en Kali bookworm ([be22dc4](https://github.com/Joscalion04/OffSec-Assistant/commit/be22dc4bd2b94152f7b8d9305fd21e9c09317544))

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
