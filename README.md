# OffSec Assistant

> **Offensive Security AI Agent** — Agente de IA para seguridad ofensiva construido sobre Claude Code.
> Pensado para pentesters que quieren un colega con criterio, no solo un ejecutor de comandos.

[![License](https://img.shields.io/badge/license-Ethical%20Use%201.0-red)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Arch%2FManjaro-lightgrey)]()
[![Claude Code](https://img.shields.io/badge/powered%20by-Claude%20Code-orange)](https://claude.ai/code)

---

## ¿Qué es OffSec Assistant?

OffSec Assistant es un agente de inteligencia artificial para seguridad ofensiva que se ejecuta
dentro de [Claude Code](https://claude.ai/code). No es un simple script que lanza herramientas
en secuencia: es un sistema de agentes especializados que acompaña al operador en cada fase de
un engagement de pentesting, razona junto a él cuando está trabado, documenta hallazgos
automáticamente y genera reportes profesionales.

### El problema que resuelve

Un pentester experimentado pasa una fracción importante de su tiempo en tareas mecánicas:
organizar carpetas, documentar hallazgos, correlacionar CVEs, escribir reportes.
OffSec Assistant automatiza esa capa operativa para que el operador se concentre en el
razonamiento ofensivo — la parte que realmente importa.

### Principios de diseño

- **Seguridad por defecto**: Nunca ejecuta herramientas activas sin `scope.md`. Nunca lanza
  exploits sin confirmación explícita del operador.
- **Transparente**: Cada decisión del agente se explica antes de ejecutarse. Sin cajas negras.
- **Auditable**: Cada comando Bash se loguea en `logs/session_YYYY-MM-DD.log`. Cada engagement
  tiene su propio repositorio git con commits por fase.
- **Operador primero**: El agente propone, el operador decide. Siempre.

---

## Características

### Gestión de engagements
- Inicialización automática de estructura de carpetas y git por engagement
- `context.md` como cerebro vivo del engagement (estado, hallazgos, vectores pendientes)
- Morning brief diario con estado de todos los engagements activos
- Cierre de sesión con commit automático y resumen de sesión

### Fases de pentesting
| Fase | Comando | Herramientas |
|------|---------|-------------|
| Reconocimiento | `/recon <target>` | nmap, WHOIS, dig, subfinder, theHarvester, WhatWeb |
| Análisis de vulnerabilidades | `/vuln-scan <target>` | nmap NSE, Nikto, Nuclei, searchsploit |
| Explotación | `/exploit <target>` | Metasploit, sqlmap — siempre con confirmación |

### Modo autónomo (`-auto`)
Disponible en `/recon`, `/vuln-scan` y `/exploit`. El agente ejecuta la fase completa,
toma decisiones basadas en resultados intermedios y escribe un live feed en tiempo real:

```bash
tail -f ~/Documents/OffSec/OffSec-Assistant/logs/livefeed/<archivo>.log
```

### Sistema de agentes
| Agente | Rol |
|--------|-----|
| `decision-advisor` | Razona problemas ofensivos en voz alta, da UNA recomendación concreta |
| `doc-writer` | Pre-llena findings con CVSS 3.1 automáticamente al detectar output relevante |
| `penetration-tester` | Agente principal de ejecución de fases |

### Documentación y reportes
- Findings en formato estructurado con CVSS 3.1, CVE, CWE, pasos de reproducción y remediación
- Reporte final: Executive Summary (no técnico) + sección técnica completa en español
- Generación con `/report <engagement>`

---

## Requisitos

### Sistema
- Linux (Arch/Manjaro recomendado; compatible con cualquier distro con bash)
- [Claude Code](https://claude.ai/code) instalado y autenticado

### Herramientas de seguridad

Verificar estado con `/check-tools`:

| Categoría | Herramientas |
|-----------|-------------|
| Reconocimiento | `nmap`, `masscan`, `amass`, `subfinder`, `theHarvester` |
| Web | `ffuf`, `nikto`, `sqlmap`, `nuclei`, `whatweb`, `gobuster` |
| Explotación | `metasploit`, `searchsploit` |
| Post-explotación | `netcat`, `socat`, `linpeas`, `winpeas` |
| Utilidades | `git`, `python3`, `curl`, `wget`, `jq`, `whois`, `dig` |

Instalación en Arch/Manjaro:
```bash
sudo pacman -S nmap masscan nikto sqlmap whatweb gobuster netcat socat git python curl wget jq whois bind
yay -S amass subfinder theHarvester nuclei ffuf
```

---

## Instalación

```bash
git clone https://github.com/Joscalion04/OffSec-Assistant.git
cd OffSec-Assistant
claude   # Abrir en Claude Code
```

No hay dependencias de instalación adicionales. Todo el sistema se basa en instrucciones
para Claude Code (`CLAUDE.md`, `.claude/commands/`, `.claude/agents/`).

---

## Inicio rápido

```bash
# 1. Verificar herramientas disponibles
/check-tools

# 2. Crear un nuevo engagement
/new-engagement acme-corp-2026

# 3. Editar scope.md con los targets autorizados
# (obligatorio antes de cualquier acción activa)

# 4. Reconocimiento
/recon 192.168.1.50

# 5. Análisis de vulnerabilidades
/vuln-scan 192.168.1.50

# 6. Explotación (requiere confirmación explícita)
/exploit 192.168.1.50

# 7. Cerrar sesión
/session-close acme-corp-2026

# 8. Generar reporte final
/report acme-corp-2026
```

---

## Comandos de referencia

### Gestión de engagements
| Comando | Descripción |
|---------|-------------|
| `/new-engagement <nombre>` | Inicializa estructura completa del engagement |
| `/status [engagement]` | Estado actual: fases, hallazgos, próximo paso |
| `/morning-brief` | Resumen de todos los engagements activos |
| `/session-close [engagement]` | Cierra sesión, commit git, genera resumen |

### Fases de pentesting
| Comando | Descripción |
|---------|-------------|
| `/recon <target> [-auto]` | Reconocimiento pasivo y activo |
| `/vuln-scan <target> [-auto]` | Análisis de vulnerabilidades |
| `/exploit <target> [-auto]` | Propuesta de explotación (siempre pide confirmación) |

### Asistencia inteligente
| Comando | Descripción |
|---------|-------------|
| `/think <situación>` | Razonamiento guiado cuando estás trabado |
| `/explain <CVE o técnica>` | Explicación técnica contextualizada |
| `/livefeed` | Cómo seguir ejecución autónoma en otra terminal |

### Reportes y utilidades
| Comando | Descripción |
|---------|-------------|
| `/report <engagement>` | Genera reporte ejecutivo + técnico completo |
| `/check-tools` | Verifica herramientas instaladas |
| `/help [comando]` | Ayuda general o detallada de un comando |

### Flag `-auto`
Disponible en `/recon`, `/vuln-scan`, `/exploit`. Ejecuta la fase de forma autónoma.
`/exploit -auto` siempre solicita confirmación antes de ejecutar, sin excepción.

---

## Estructura del proyecto

```
OffSec-Assistant/
├── .claude/
│   ├── agents/
│   │   ├── decision-advisor.md     # Agente de razonamiento ofensivo
│   │   ├── doc-writer.md           # Agente de documentación automática
│   │   └── penetration-tester.md  # Agente principal de pentesting
│   └── commands/                   # Slash commands del sistema
│       ├── check-tools.md
│       ├── explain.md
│       ├── exploit.md
│       ├── help.md
│       ├── livefeed.md
│       ├── morning-brief.md
│       ├── new-engagement.md
│       ├── recon.md
│       ├── report.md
│       ├── session-close.md
│       ├── status.md
│       ├── think.md
│       └── vuln-scan.md
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── pull_request_template.md
├── findings/                        # [gitignored] Engagements activos
│   └── YYYY-MM-DD_<nombre>/
│       ├── scope.md                 # Targets autorizados — EDITAR PRIMERO
│       ├── context.md               # Cerebro vivo del engagement
│       ├── finding_template.md
│       ├── recon/
│       ├── vulns/
│       ├── exploitation/
│       ├── post-exploitation/
│       ├── evidence/
│       └── notes/
├── logs/                            # [gitignored] Logs de sesión y live feed
├── reports/                         # [gitignored] Reportes generados
├── templates/
│   ├── context.md                   # Plantilla de contexto de engagement
│   ├── finding.md                   # Plantilla de hallazgo (CVSS 3.1)
│   └── scope.md                     # Plantilla de scope
├── tools/
│   ├── auto-runner.sh               # Orquestador de ejecución autónoma
│   ├── logger.sh                    # Sistema de logging de sesión
│   ├── run-recon.sh                 # Runner de fase de reconocimiento
│   └── run-vuln-scan.sh             # Runner de fase de vuln-scan
├── wordlists/                       # Wordlists custom (sistema usa /usr/share/wordlists/)
├── CHANGELOG.md
├── CLAUDE.md                        # Identidad y comportamiento del agente
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── SECURITY.md
└── scope.md                         # Scope global (referencias generales)
```

---

## Contribuir

Las contribuciones son bienvenidas. Lee [CONTRIBUTING.md](CONTRIBUTING.md) para el
proceso completo. Resumen:

1. Fork del repositorio
2. Crear rama desde `develop`: `git checkout -b feat/mi-nueva-funcionalidad`
3. Commits con formato Conventional Commits (ver abajo)
4. PR apuntando a `develop` con la plantilla completa
5. Code review y merge por el mantenedor

### Formato de commits

Este proyecto sigue [Conventional Commits](https://www.conventionalcommits.org/):

```
<tipo>(<scope>): <descripción en presente, minúsculas>
```

**Tipos principales:**

| Tipo | Uso |
|------|-----|
| `feat` | Nueva funcionalidad o comando |
| `fix` | Corrección de bug |
| `docs` | Solo documentación |
| `chore` | Mantenimiento y tareas de infraestructura |
| `refactor` | Reestructuración sin cambio de comportamiento |
| `agent` | Cambios en agentes del sistema |
| `template` | Cambios en plantillas |
| `recon` | Cambios en fase de reconocimiento |
| `vuln` | Cambios en fase de vuln-scan |
| `exploit` | Cambios en fase de explotación |
| `report` | Cambios en sistema de reportes |

**Ejemplos:**
```bash
feat(commands): agregar flag --format json en /report
fix(agents): corregir doc-writer que no generaba campo CVSS correctamente
docs(readme): agregar sección de instalación en Debian/Ubuntu
agent(decision-advisor): mejorar razonamiento para casos de AD enumeration
template(finding): agregar campo EPSS score
```

**Breaking changes** se documentan en el footer del commit:
```
feat(commands): cambiar estructura de scope.md

BREAKING CHANGE: el campo `targets` ahora requiere sub-campo `authorization_date`.
```

---

## Control de versiones

Este proyecto sigue [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

| Incremento | Cuándo |
|-----------|--------|
| `MAJOR` | Cambios incompatibles con versiones anteriores (estructura de archivos, contratos de agentes) |
| `MINOR` | Nuevas funcionalidades retrocompatibles (nuevos comandos, nuevos agentes) |
| `PATCH` | Correcciones de bugs y mejoras menores retrocompatibles |

Los releases se documentan en [CHANGELOG.md](CHANGELOG.md) siguiendo
[Keep a Changelog](https://keepachangelog.com/).

### Estrategia de ramas

```
main ──────────────────────────────────── (releases estables, etiquetados)
         ↑ merge release
develop ──────────────────────────────── (integración continua)
    ↑ merge PRs
feature/* / fix/* / docs/* / chore/*     (ramas de trabajo)
```

---

## Flujo de trabajo de PRs

1. El PR se abre contra `develop` usando la plantilla en `.github/pull_request_template.md`
2. El autor completa el checklist de la plantilla
3. Code review por al menos un mantenedor en ≤ 5 días hábiles
4. Feedback incorporado por el autor
5. Merge por el mantenedor (squash si hay commits de WIP; merge commit si son commits limpios)
6. Los cambios en `develop` se agrupan en un release y se fusionan a `main` con tag de versión

**Criterios de rechazo automático:**
- El PR debilita o elimina el gate de scope
- El PR elimina la confirmación obligatoria en `/exploit`
- El PR modifica la LICENSE para reducir las restricciones de uso ético
- El PR no tiene descripción del cambio

---

## Aviso legal y uso ético

**Este software está diseñado exclusivamente para seguridad ofensiva autorizada.**

Solo está permitido usar OffSec Assistant contra sistemas, redes o aplicaciones para
los cuales el usuario tenga **autorización escrita explícita** del propietario del sistema.
Cualquier uso no autorizado es ilegal y viola los términos de la [Licencia](LICENSE).

El uso de esta herramienta para actividades ilegales, no autorizadas, o con fines de
daño es responsabilidad exclusiva del usuario. Los autores no asumen ninguna responsabilidad
por mal uso.

Casos de uso legítimos: engagements de pentesting con contrato, CTF, laboratorios propios,
bug bounty dentro del scope declarado por el programa.

---

## Licencia

OffSec Assistant Ethical Use License 1.0 — ver [LICENSE](LICENSE).

Open source con restricciones:
- Uso no comercial permitido libremente
- Uso comercial requiere autorización escrita previa del autor
- Uso ético obligatorio — uso contra sistemas no autorizados viola la licencia

Contacto para uso comercial o preguntas sobre la licencia: joscalion04@gmail.com

---

## Autor

**Joseph Leon** — [@Joscalion04](https://github.com/Joscalion04)

---

*OffSec Assistant es una herramienta para profesionales de seguridad responsables.*
*Úsala bien.*
