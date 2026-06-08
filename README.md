# OffSec Assistant

> **Offensive Security AI Agent** — Agente de IA para seguridad ofensiva construido sobre Claude Code.
> Pensado para pentesters que quieren un colega con criterio, no solo un ejecutor de comandos.

[![License](https://img.shields.io/badge/license-Ethical%20Use%201.0-red)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Docker-lightgrey)]()
[![Claude Code](https://img.shields.io/badge/powered%20by-Claude%20Code-orange)](https://claude.ai/code)

**[Manual de usuario completo](MANUAL.md)** — instalacion paso a paso, flujo de engagement, DLP y referencia de comandos.

---

## Que es OffSec Assistant

OffSec Assistant es un agente de inteligencia artificial para seguridad ofensiva que corre
dentro de [Claude Code](https://claude.ai/code). No es un script que lanza herramientas en
secuencia: es un sistema de agentes especializados que acompana al operador en cada fase de
un engagement, razona junto a el cuando esta trabado, documenta hallazgos automaticamente y
genera reportes profesionales.

### El problema que resuelve

Un pentester experimentado pasa una fraccion importante de su tiempo en tareas mecanicas:
organizar carpetas, documentar hallazgos, correlacionar CVEs, escribir reportes.
OffSec Assistant automatiza esa capa operativa para que el operador se concentre en el
razonamiento ofensivo, la parte que realmente importa.

### Principios de diseno

- **Seguridad por defecto**: Nunca ejecuta herramientas activas sin `scope.md`. Nunca lanza
  exploits sin confirmacion explicita del operador.
- **Transparente**: Cada decision del agente se explica antes de ejecutarse. Sin cajas negras.
- **Auditable**: Cada comando se loguea en `logs/session_YYYY-MM-DD.log`. Cada engagement
  tiene su propio repositorio git con commits por fase.
- **Operador primero**: El agente propone, el operador decide. Siempre.

---

## Caracteristicas

### Gestion de engagements
- Inicializacion automatica de estructura de carpetas y git por engagement
- `context.md` como cerebro vivo del engagement (estado, hallazgos, vectores pendientes)
- Morning brief diario con estado de todos los engagements activos
- Cierre de sesion con commit automatico y resumen

### Fases de pentesting
| Fase | Comando | Herramientas |
|------|---------|-------------|
| Reconocimiento | `/recon <target>` | nmap, WHOIS, dig, subfinder, theHarvester, WhatWeb |
| Analisis de vulnerabilidades | `/vuln-scan <target>` | nmap NSE, Nikto, Nuclei, searchsploit |
| Explotacion | `/exploit <target>` | Metasploit, sqlmap — siempre con confirmacion |

### Modo autonomo (-auto)
Ejecuta la fase completa sin interrupciones con live feed en tiempo real.
El agente toma decisiones basadas en resultados intermedios y actualiza `context.md` al terminar.

### Sistema de agentes
| Agente | Rol |
|--------|-----|
| `decision-advisor` | Razona problemas ofensivos, da una recomendacion concreta |
| `doc-writer` | Pre-llena findings con CVSS 3.1 al detectar output relevante |
| `penetration-tester` | Agente principal de ejecucion de fases |

### Documentacion y reportes
- Findings estructurados con CVSS 3.1, CVE, CWE, reproduccion y remediacion
- Reporte final: Executive Summary + seccion tecnica completa en espanol

### Contenedor Docker
Imagen autocontenida basada en Kali Linux con todo el stack de pentesting incluido.
No depende de herramientas del host. Soporta OpenVPN y WireGuard de forma nativa.
Ver [Instalacion con Docker](#instalacion-con-docker) o el [Manual de usuario](MANUAL.md#2-instalacion-y-configuracion).

### Control DLP (Data Loss Prevention)
Sistema de tokenizacion que protege los datos del cliente/target antes de que lleguen
al agente de IA y por ende a la API de Anthropic.

- **IPs reales** (`192.168.1.50`) se reemplazan por tokens (`TGT-001`) antes de cada log
- **Hostnames y FQDNs** se tokenizan como `HST-001`, `HST-002`, etc.
- **Nombres de organizacion** (de WHOIS, certificados) se tokenizan como `ORG-001`
- **Credenciales** (passwords, hashes, tokens) se redactan completamente: `[CREDENTIAL-REDACTED]`
- El mapa token-valor real vive en `findings/<engagement>/dlp-map.json`, es local y gitignored
- Los scripts de scanning usan valores reales para ejecutar herramientas pero logs sanitizados
  para el agente: la herramienta ve la IP, el agente ve el token

---

## Requisitos

### Modo nativo

- Linux (Arch/Manjaro recomendado; compatible con cualquier distro con bash)
- [Claude Code](https://claude.ai/code) instalado y autenticado
- Herramientas de pentesting (ver tabla completa en el [manual](MANUAL.md#21-modo-nativo))

Instalacion rapida en Arch/Manjaro:
```bash
sudo pacman -S nmap masscan nikto sqlmap whatweb gobuster netcat socat git python curl wget jq whois bind
yay -S amass subfinder theHarvester nuclei ffuf
```

### Modo Docker

- Docker >= 24.0 y Docker Compose >= 2.20
- API key de Anthropic (`ANTHROPIC_API_KEY`)
- Sin dependencias adicionales — todo el stack esta en la imagen

---

## Instalacion rapida

### Modo nativo

```bash
git clone https://github.com/Joscalion04/OffSec-Assistant.git
cd OffSec-Assistant
claude
```

### Modo Docker

```bash
git clone https://github.com/Joscalion04/OffSec-Assistant.git
cd OffSec-Assistant

# Configurar API key
cp .env.example .env
# Editar .env: ANTHROPIC_API_KEY=sk-ant-...

# Construir y ejecutar
docker compose build
docker compose run --rm assistant
```

Para instrucciones detalladas de cada modo (Docker con VPN, con Metasploit, persistencia
de datos, troubleshooting) ver el **[Manual de usuario](MANUAL.md)**.

---

## Flujo de trabajo estandar

```bash
# Inicio del dia
/morning-brief

# Crear engagement
/new-engagement acme-corp-2026

# Completar scope.md con los targets autorizados (obligatorio)
# Luego inicializar proteccion DLP
python3 tools/sanitizer.py findings/2026-06-08_acme-corp-2026 --init

# Fases de pentesting
/recon 192.168.10.50 -auto
/vuln-scan 192.168.10.50
/exploit 192.168.10.50

# Fin del dia
/session-close acme-corp-2026
/report acme-corp-2026
```

El [Manual de usuario](MANUAL.md#4-flujo-de-engagement-completo) cubre cada paso
con ejemplos, modos interactivo y autonomo, y consideraciones DLP.

---

## Comandos de referencia rapida

| Comando | Descripcion |
|---------|-------------|
| `/new-engagement <nombre>` | Inicializa estructura completa del engagement |
| `/morning-brief` | Briefing diario de todos los engagements activos |
| `/status [engagement]` | Estado actual: fases, hallazgos, proximo paso |
| `/session-close [engagement]` | Cierra sesion, commit git, resumen |
| `/recon <target> [-auto]` | Reconocimiento pasivo y activo |
| `/vuln-scan <target> [-auto]` | Analisis de vulnerabilidades |
| `/exploit <target> [-auto]` | Vectores de explotacion (confirmacion obligatoria) |
| `/think <situacion>` | Razonamiento guiado cuando estas trabado |
| `/explain <CVE o tecnica>` | Explicacion tecnica contextualizada |
| `/report <engagement>` | Reporte ejecutivo y tecnico completo |
| `/check-tools` | Verifica herramientas instaladas |
| `/help [comando]` | Ayuda general o detallada |

Para descripcion completa de cada comando con ejemplos ver [Manual — Referencia de comandos](MANUAL.md#8-referencia-de-comandos).

---

## Estructura del proyecto

```
OffSec-Assistant/
|-- .claude/
|   |-- agents/
|   |   |-- decision-advisor.md
|   |   |-- doc-writer.md
|   |   `-- penetration-tester.md
|   `-- commands/
|       `-- [check-tools, explain, exploit, help, livefeed,
|            morning-brief, new-engagement, recon, report,
|            session-close, status, think, vuln-scan].md
|-- docker/
|   |-- entrypoint.sh
|   `-- vpn/              <- configs VPN (gitignored)
|-- findings/             <- [gitignored] engagements activos
|   `-- YYYY-MM-DD_<nombre>/
|       |-- scope.md      <- targets autorizados (editar primero)
|       |-- context.md    <- estado vivo del engagement
|       |-- dlp-map.json  <- mapa DLP local (gitignored)
|       |-- recon/
|       |-- vulns/
|       |-- exploitation/
|       |-- post-exploitation/
|       |-- evidence/
|       `-- notes/
|-- logs/                 <- [gitignored] sesion y livefeed
|-- reports/              <- [gitignored] reportes generados
|-- templates/            <- scope, context, finding
|-- tools/
|   |-- auto-runner.sh    <- motor de ejecucion autonoma + DLP
|   |-- logger.sh
|   |-- run-recon.sh      <- fase de reconocimiento con DLP integrado
|   |-- run-vuln-scan.sh  <- fase de vuln-scan con DLP integrado
|   `-- sanitizer.py      <- motor DLP: tokenizacion de datos sensibles
|-- .dockerignore
|-- .env.example
|-- CHANGELOG.md
|-- CLAUDE.md             <- identidad, comportamiento y reglas DLP del agente
|-- CONTRIBUTING.md
|-- docker-compose.full.yml
|-- docker-compose.yml
|-- Dockerfile            <- multi-stage: lite y full
|-- MANUAL.md             <- guia de usuario completa
|-- README.md
|-- SECURITY.md
`-- scope.md
```

---

## Funcionalidades pendientes

### Optimizacion

- Cache de reconocimiento para evitar re-escaneos identicos entre sesiones
- Procesamiento paralelo de multiples targets con control de concurrencia
- Base de datos local de CVEs para correlacion offline sin conectividad externa
- Compresion automatica de evidencias de engagements cerrados
- Perfiles de escaneo configurables (silencioso, estandar, agresivo)

### Gobernanza

- Cadena de custodia de evidencias con hash SHA-256 automatico al momento de captura
- Audit trail estructurado en JSON compatible con SIEMs
- Modo revision read-only para auditorias internas sin ejecucion
- Control de versiones de templates con migracion automatica de engagements activos
- Firma digital de reportes finales para garantizar integridad ante el cliente

### Seguridad operativa

- Pipeline CI con Trivy: escaneo de imagen Docker en cada push, bloqueo en CVEs criticos
- Firmado de imagen con cosign/sigstore para verificacion de origen
- Integracion con HashiCorp Vault para rotacion de API key y credenciales VPN
- Cifrado at-rest del directorio `findings/` con age/gpg, descifrado solo en runtime
- Network policy para restringir egress del contenedor a IPs del scope declarado
- Perfiles AppArmor/Seccomp especificos para el contenedor

### Seguridad ofensiva

- Modulo Active Directory: BloodHound/SharpHound, attack paths automaticos
- Parsing automatico de linpeas/winpeas con findings preformateados
- Integracion con Burp Suite API para web testing desde el agente
- Mapeo automatico de tecnicas a MITRE ATT&CK en cada hallazgo documentado
- Integracion con plataformas CTF: HackTheBox API, TryHackMe
- Modulo de threat intelligence con MISP u OpenCTI
- Soporte multi-engagement simultaneo con dashboard unificado
- Generacion de payloads contextuales adaptados al entorno detectado

---

## Contribuir

Lee [CONTRIBUTING.md](CONTRIBUTING.md) para el proceso completo.

Este proyecto sigue [Conventional Commits](https://www.conventionalcommits.org/).
Tipos principales: `feat`, `fix`, `docs`, `chore`, `refactor`, `agent`, `template`,
`recon`, `vuln`, `exploit`, `report`, `docker`.

**Criterios de rechazo automatico de PRs:**
- Debilita o elimina el gate de scope
- Elimina la confirmacion obligatoria en `/exploit`
- Modifica la LICENSE para reducir restricciones de uso etico

---

## Aviso legal y uso etico

**Este software esta disenado exclusivamente para seguridad ofensiva autorizada.**

Solo esta permitido usarlo contra sistemas para los cuales el usuario tenga
**autorizacion escrita explicita** del propietario. El uso no autorizado es ilegal
y viola los terminos de la [Licencia](LICENSE).

Casos de uso legitimos: engagements con contrato, CTF, laboratorios propios,
bug bounty dentro del scope declarado por el programa.

---

## Licencia

OffSec Assistant Ethical Use License 1.0 — ver [LICENSE](LICENSE).

- Uso no comercial: permitido libremente
- Uso comercial: requiere autorizacion escrita previa del autor
- Uso etico: obligatorio — uso contra sistemas no autorizados viola la licencia

Contacto: joscalion04@gmail.com

---

## Autor

**Joseph Leon** — [@Joscalion04](https://github.com/Joscalion04)

---

*OffSec Assistant es una herramienta para profesionales de seguridad responsables.*
*Usala bien.*
