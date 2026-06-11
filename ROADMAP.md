# ROADMAP — OffSec Assistant

> Documento maestro de planificación. Modela el estado del proyecto usando la convención
> GitHub: **Milestone → Issue → Sub-issues**, con sistema de labels para clasificar cada
> unidad de trabajo. Los milestones representan funcionalidades completas y versionadas.
> Los issues sin milestone son trabajo transversal (bugs, seguridad, tests, docs).

---

## Sistema de Labels

Los labels determinan la naturaleza de cada issue, independientemente del milestone al que
pertenezcan. Todo issue debe tener exactamente **un label de tipo** y **una prioridad**.
Puede tener labels adicionales de contexto.

### Labels de tipo

| Label | Color | Descripción |
|-------|-------|-------------|
| `bug` | `#d73a4a` | Algo no funciona como se espera |
| `security-fix` | `#b60205` | Vulnerabilidad o hardening de seguridad |
| `enhancement` | `#a2eeef` | Nueva funcionalidad o mejora de existente |
| `refactor` | `#e4e669` | Reestructuración interna sin cambio de comportamiento |
| `documentation` | `#0075ca` | Mejoras o adiciones de documentación |
| `testing` | `#7057ff` | Cobertura de tests y QA |
| `ci/cd` | `#f9d0c4` | Pipeline, automatización y release |
| `dependencies` | `#cfd3d7` | Actualización o gestión de dependencias |

### Labels de prioridad

| Label | Color | Criterio |
|-------|-------|----------|
| `priority: critical` | `#b60205` | Bloquea el uso del sistema o expone datos sensibles |
| `priority: high` | `#e4e669` | Impacta funcionalidad core, debe entrar en el próximo ciclo |
| `priority: medium` | `#0075ca` | Mejora importante pero no urgente |
| `priority: low` | `#cfd3d7` | Nice-to-have, entra cuando haya capacidad |

### Labels de contexto (opcionales, combinables)

| Label | Descripción |
|-------|-------------|
| `good-first-issue` | Accesible para contribuidores nuevos |
| `help-wanted` | Se agradece ayuda externa |
| `breaking-change` | Introduce cambios incompatibles con versiones anteriores |
| `blocked` | Esperando resolución de otro issue o dependencia externa |
| `needs-design` | Requiere decisión de diseño antes de implementar |

---

## Milestones

```
M1  v1.1.0 — Core Stability & Hardening         [Inmediato]
M2  v1.2.0 — DLP v2: Cifrado at-rest & Vault    [Corto plazo]
M3  v1.3.0 — Optimización de Ejecución          [Corto plazo]
M4  v1.4.0 — Gobernanza & Auditoría Forense     [Mediano plazo]
M5  v2.0.0 — Módulo CTF & Plataformas           [Mediano plazo]
M6  v2.1.0 — Threat Intelligence                [Mediano plazo]
M7  v2.2.0 — Multi-Engagement Dashboard         [Largo plazo]
M8  v2.3.0 — DevSecOps Pipeline                 [Largo plazo]
M9  v2.4.0 — Payload Engine Contextual          [Largo plazo]
M10 v3.0.0 — Enterprise & API Pública           [Visión]
```

---

## M1 — Core Stability & Hardening `v1.1.0`

> Consolida la base de v1.0.0. Fija edge cases conocidos, mejora el manejo de errores
> y garantiza que los flujos críticos (scope gate, DLP, logging) sean robustos antes de
> agregar funcionalidades nuevas.

**Criterio de cierre:** todos los flujos del MANUAL.md ejecutan sin errores en sistema
limpio con y sin herramientas opcionales instaladas.

---

### #1 — `bug` `priority: high`
**scope.md gate no valida estructura mínima del archivo**

El gate actual solo verifica que el archivo exista, pero no que tenga al menos un
target declarado. Un scope.md vacío o con solo comentarios pasa el check.

- [ ] **#1a** — Implementar parser mínimo que detecte al menos una línea de target válida
- [ ] **#1b** — Agregar mensaje de error descriptivo que guíe al operador a editar el archivo
- [ ] **#1c** — Documentar formato esperado de scope.md en el archivo template

---

### #2 — `bug` `priority: high`
**auto-runner.sh no maneja señales SIGTERM/SIGINT limpiamente**

Al interrumpir con Ctrl+C durante un escaneo autónomo, el proceso hijo puede quedar
corriendo en segundo plano. Los archivos de log quedan incompletos sin marcador de fin.

- [ ] **#2a** — Agregar trap SIGTERM/SIGINT en auto-runner.sh con cleanup de procesos hijos
- [ ] **#2b** — Escribir marcador `[INTERRUPTED]` en el log antes de salir
- [ ] **#2c** — Agregar trap equivalente en run-recon.sh y run-vuln-scan.sh

---

### #3 — `bug` `priority: medium`
**sanitizer.py no tokeniza direcciones IPv6**

El motor DLP solo reconoce IPs en notación IPv4. Una dirección IPv6 del target
pasaría al agente sin tokenizar.

- [ ] **#3a** — Agregar regex para IPv6 full (`2001:db8::1`) y comprimido (`::1`)
- [ ] **#3b** — Agregar soporte para CIDR IPv6 (`2001:db8::/32`)
- [ ] **#3c** — Agregar casos de prueba en test suite (ver #T1)
- [ ] **#3d** — Actualizar documentación DLP en CLAUDE.md

---

### #4 — `bug` `priority: medium`
**/morning-brief falla silenciosamente si findings/ está vacío o no existe**

El comando asume que el directorio existe y tiene al menos un engagement. En una
instalación nueva produce un error no descriptivo.

- [ ] **#4a** — Agregar verificación de directorio con mensaje de bienvenida para estado inicial
- [ ] **#4b** — Sugerir `/new-engagement` cuando no hay engagements activos

---

### #5 — `bug` `priority: medium`
**/report genera tabla CVSS con celdas vacías cuando el finding no está completo**

Si un finding_*.md tiene campos CVSS sin rellenar (score, vector), el reporte final
incluye filas con guiones vacíos sin advertir al operador.

- [ ] **#5a** — Detectar campos CVSS incompletos y advertir antes de generar el reporte
- [ ] **#5b** — Ofrecer modo `--draft` que genere el reporte marcando los campos pendientes

---

### #6 — `bug` `priority: low`
**burp-api.py no expone timeout configurable desde CLI**

El timeout está hardcodeado a 15 segundos en `_request()`. Para scans largos o
Burp ejecutando en red con latencia, la conexión se corta prematuramente.

- [ ] **#6a** — Agregar flag `--timeout` en argparse con default de 15s
- [ ] **#6b** — Leer también de variable de entorno `BURP_TIMEOUT`

---

### #7 — `refactor` `priority: medium`
**Unificar manejo de errores en todos los scripts run-*.sh**

Cada script tiene su propio patrón de manejo de errores. Algunas funciones usan
`set -e`, otras comprueban `$?` manualmente. Hace difícil mantenerlos en sintonía.

- [ ] **#7a** — Extraer función `die()` y `check_tool()` comunes a un script `lib.sh`
- [ ] **#7b** — Hacer source de `lib.sh` en todos los run-*.sh y auto-runner.sh
- [ ] **#7c** — Estandarizar códigos de salida: 0 éxito, 1 error de usuario, 2 error de tool

---

### #8 — `enhancement` `priority: medium`
**Perfiles de escaneo configurables (silencioso / estándar / agresivo)**

Actualmente los flags de nmap y nuclei están hardcodeados en run-recon.sh.
Distintos contextos de engagement requieren distintos niveles de intrusión.

- [ ] **#8a** — Definir tres perfiles en un archivo `config/scan-profiles.yaml`
- [ ] **#8b** — Leer el perfil activo desde `context.md` o flag `--profile`
- [ ] **#8c** — Aplicar perfil en run-recon.sh, run-vuln-scan.sh y run-ad-enum.sh
- [ ] **#8d** — Documentar perfiles en MANUAL.md con tabla de diferencias

---

## M2 — DLP v2: Cifrado at-rest & Vault `v1.2.0`

> Eleva la protección de los datos del cliente más allá de la tokenización. Los hallazgos
> crudos en disco quedan cifrados. Las credenciales del operador (API keys, VPN) rotan
> automáticamente a través de HashiCorp Vault.

**Criterio de cierre:** un directorio `findings/` clonado sin la clave correcta es
ilegible. Las API keys no aparecen en texto plano en ningún archivo del proyecto.

---

### #9 — `enhancement` `priority: high`
**Cifrado at-rest de findings/ con age**

Los archivos raw de nmap, nikto, credenciales etc. viven en disco sin cifrar. Si la
máquina del operador se ve comprometida, los datos del cliente quedan expuestos.

- [ ] **#9a** — Integrar `age` como dependencia para cifrado simétrico de archivos
- [ ] **#9b** — Generar clave por engagement al correr `/new-engagement`, guardarla fuera de `findings/`
- [ ] **#9c** — Modificar auto-runner.sh para cifrar archivos raw inmediatamente tras escritura
- [ ] **#9d** — Modificar sanitizer.py para descifrar antes de tokenizar (en memoria, no en disco)
- [ ] **#9e** — Agregar comando `/findings-lock` y `/findings-unlock` para gestión manual
- [ ] **#9f** — Documentar procedimiento de backup seguro de clave en MANUAL.md

---

### #10 — `enhancement` `priority: medium`
**Integración con HashiCorp Vault para gestión de credenciales**

`ANTHROPIC_API_KEY`, claves VPN y potencialmente credenciales capturadas en el
engagement hoy viven en `.env` o en disco. Vault centraliza y audita el acceso.

- [ ] **#10a** — Agregar soporte para leer `ANTHROPIC_API_KEY` desde Vault via AppRole
- [ ] **#10b** — Documentar configuración de Vault local con Docker en MANUAL.md
- [ ] **#10c** — Hacer que el Dockerfile acepte `VAULT_ADDR` + `VAULT_TOKEN` como alternativa a `.env`
- [ ] **#10d** — Agregar fallback graceful a `.env` si Vault no está disponible

---

### #11 — `security-fix` `priority: high`
**Garantizar que dlp-map.json nunca sea staged en git accidentalmente**

El `.gitignore` actual cubre `findings/` pero un `git add .` desde el root podría
incluir archivos si el gitignore tiene un path mal construido.

- [ ] **#11a** — Agregar pre-commit hook que rechace staging de `dlp-map.json`
- [ ] **#11b** — Agregar `dlp-map.json` explícitamente al `.gitignore` del root y del engagement
- [ ] **#11c** — Agregar test de regresión que valide el hook (ver #T3)

---

### #12 — `enhancement` `priority: medium`
**Network policy: restringir egress del contenedor al scope declarado**

El contenedor Docker actualmente tiene acceso irrestricto a Internet. Toda conexión
saliente debería limitarse a las IPs declaradas en scope.md más servicios esenciales.

- [ ] **#12a** — Script que parsee scope.md y genere reglas `iptables` de egress
- [ ] **#12b** — Integrar generación de reglas en `docker/entrypoint.sh`
- [ ] **#12c** — Agregar modo `--no-network-policy` para laboratorios que lo requieran
- [ ] **#12d** — Documentar política de red en MANUAL.md sección Docker

---

## M3 — Optimización de Ejecución `v1.3.0`

> Hace el asistente más eficiente en engagements reales: evita re-escaneos redundantes,
> permite atacar múltiples targets en paralelo y funciona sin conectividad externa.

**Criterio de cierre:** `/recon` sobre un target ya escaneado en la misma sesión devuelve
el cache en <2s. Dos targets en paralelo terminan en ≤ tiempo del más lento + 10%.

---

### #13 — `enhancement` `priority: high`
**Cache de reconocimiento entre sesiones**

Cada invocación de `/recon` sobre el mismo target lanza los mismos escaneos desde cero,
incluso si hay resultados válidos del mismo día. Desperdicia tiempo y genera ruido en red.

- [ ] **#13a** — Definir TTL de cache por tipo de scan (nmap: 4h, WHOIS: 24h, DNS: 1h)
- [ ] **#13b** — Implementar índice de cache en `findings/<engagement>/cache/` con metadata
- [ ] **#13c** — Modificar run-recon.sh para consultar cache antes de ejecutar
- [ ] **#13d** — Agregar flag `--force-rescan` para invalidar cache explícitamente
- [ ] **#13e** — Mostrar indicador `[CACHED]` vs `[LIVE]` en el output del agente

---

### #14 — `enhancement` `priority: medium`
**Procesamiento paralelo de múltiples targets con control de concurrencia**

Actualmente `/recon` y `/vuln-scan` solo operan sobre un target a la vez. Engagements
con múltiples hosts requieren invocar el comando repetidamente de forma manual.

- [ ] **#14a** — Agregar soporte para lista de targets en scope.md con procesamiento paralelo
- [ ] **#14b** — Implementar semáforo configurable (`MAX_PARALLEL_TARGETS`, default: 3)
- [ ] **#14c** — Live feed diferenciado por target cuando corren en paralelo
- [ ] **#14d** — Agregar flag `--sequential` para modo de un target a la vez

---

### #15 — `enhancement` `priority: medium`
**Base de datos local de CVEs para correlación offline**

La correlación de CVEs hoy depende de searchsploit y conectividad a NVD. En
entornos air-gapped o con restricciones de red, la correlación queda ciega.

- [ ] **#15a** — Script de descarga y actualización del feed NVD en JSON
- [ ] **#15b** — Índice local SQLite con lookup por CVE-ID, CPE y keyword
- [ ] **#15c** — Modificar run-vuln-scan.sh para usar índice local con fallback a online
- [ ] **#15d** — Comando `/update-cve-db` para refrescar la base de datos manualmente

---

### #16 — `enhancement` `priority: low`
**Compresión automática de evidencias de engagements cerrados**

Después de `/session-close`, los directorios de evidencia raw (capturas, logs completos)
ocupan espacio innecesario. Los findings ya sanitizados son la fuente de verdad.

- [ ] **#16a** — Al ejecutar `/session-close`, comprimir subdirectorios raw con `tar.zst`
- [ ] **#16b** — Mantener context.md y finding_*.md sin comprimir para lectura rápida
- [ ] **#16c** — Agregar comando `/engagement-archive <nombre>` para archivar manualmente

---

## M4 — Gobernanza & Auditoría Forense `v1.4.0`

> Hace al asistente apto para entornos regulados y auditables. Cada artefacto tiene
> integridad verificable. Cada acción queda en un trail estructurado ingestible por SIEMs.
> Los reportes tienen firma digital que garantiza no-repudio ante el cliente.

**Criterio de cierre:** el directorio de un engagement cerrado pasa una auditoría de
integridad completa sin fallos. El audit trail importa correctamente en Splunk/Elastic.

---

### #17 — `enhancement` `priority: high`
**Cadena de custodia de evidencias con hash SHA-256 automático**

Actualmente no hay mecanismo para probar que un archivo de evidencia no fue modificado
después de su captura. Esto es requerido en algunos contratos y procesos legales.

- [ ] **#17a** — Hashear y registrar cada archivo al momento de creación en `chain-of-custody.json`
- [ ] **#17b** — Comando `/verify-custody <engagement>` que valida todos los hashes
- [ ] **#17c** — Integrar la verificación automáticamente en `/report` antes de generar

---

### #18 — `enhancement` `priority: high`
**Audit trail estructurado en JSON compatible con SIEMs**

El log de sesión actual es texto plano legible por humanos pero no parseable por
herramientas de SIEM (Splunk, Elastic, Wazuh) sin transformaciones manuales.

- [ ] **#18a** — Definir schema JSON del evento de audit (timestamp, actor, action, target, result)
- [ ] **#18b** — Modificar logger.sh para emitir eventos JSON a `logs/audit_YYYY-MM-DD.jsonl`
- [ ] **#18c** — Mantener el log de texto plano como vista humana (no eliminarlo)
- [ ] **#18d** — Documentar schema de eventos en MANUAL.md con ejemplos de queries Splunk/KQL

---

### #19 — `enhancement` `priority: medium`
**Modo revisión read-only para auditorías internas**

Actualmente no hay forma de darle acceso a un engagement a un revisor sin que este
pueda accidentalmente modificar findings, ejecutar comandos o cerrar la sesión.

- [ ] **#19a** — Variable de entorno `OFFSEC_READONLY=1` que deshabilita herramientas activas
- [ ] **#19b** — En modo read-only, `/exploit` y `/vuln-scan` solo muestran hallazgos previos
- [ ] **#19c** — Indicador visual en el prompt del agente cuando está en modo read-only

---

### #20 — `enhancement` `priority: medium`
**Firma digital de reportes finales con GPG**

El reporte que el operador entrega al cliente no tiene mecanismo de verificación de
autenticidad. Un tercero podría modificarlo y el cliente no podría detectarlo.

- [ ] **#20a** — Modificar `/report` para firmar el PDF/MD generado con la clave GPG del operador
- [ ] **#20b** — Incluir instrucciones de verificación al final del reporte para el cliente
- [ ] **#20c** — Documentar setup de clave GPG en MANUAL.md

---

### #21 — `enhancement` `priority: low`
**Control de versiones de templates con migración automática**

Cuando se actualiza `templates/finding.md` o `templates/context.md`, los engagements
activos usan la versión anterior. No hay mecanismo de migración ni advertencia.

- [ ] **#21a** — Agregar campo `template_version` al frontmatter de cada template
- [ ] **#21b** — Al abrir un engagement con template desactualizado, advertir y ofrecer migrar
- [ ] **#21c** — Script `tools/migrate-templates.sh` para actualización masiva

---

## M5 — Módulo CTF & Plataformas `v2.0.0`

> Primera versión mayor después de la base. Extiende el asistente para soportar los
> flujos de CTF (HackTheBox, TryHackMe) como ciudadanos de primera clase: spawn de
> máquina, tracking de flags, cierre automático de instancia.

**Breaking changes:** estructura de engagement incluye campo `platform` en context.md.
Los engagements de v1.x son compatibles con valor `platform: manual`.

---

### #22 — `enhancement` `priority: high`
**Integración con HackTheBox API**

- [ ] **#22a** — Autenticación con HTB API v4 via token en `.env`
- [ ] **#22b** — Comando `/htb spawn <machine>` que levanta la instancia y crea el engagement
- [ ] **#22c** — Importar IP de la máquina directamente a scope.md sin intervención manual
- [ ] **#22d** — Comando `/htb submit <flag> <engagement>` que envía la flag y registra en context.md
- [ ] **#22e** — Cierre automático de la instancia al ejecutar `/session-close`

---

### #23 — `enhancement` `priority: medium`
**Integración con TryHackMe**

- [ ] **#23a** — Autenticación con THM API via cookie/token
- [ ] **#23b** — Comando `/thm join <room>` que inicializa el engagement con los datos de la sala
- [ ] **#23c** — Obtener IP de la VM automáticamente cuando la sala la provee
- [ ] **#23d** — Comando `/thm task complete <n>` que marca tarea y registra en context.md

---

### #24 — `enhancement` `priority: medium`
**Flujo CTF optimizado con tracking de progreso**

- [ ] **#24a** — Tipo de engagement `ctf` en context.md con campos: platform, difficulty, points, flags
- [ ] **#24b** — `/status` en modo CTF muestra flags obtenidas, pendientes y puntuación
- [ ] **#24c** — `/morning-brief` incluye instancias CTF activas con tiempo restante si aplica
- [ ] **#24d** — `/report` en modo CTF genera writeup estructurado en formato convencional CTF

---

### #25 — `enhancement` `priority: low`
**Importador de máquinas desde YAML/JSON de plataforma**

- [ ] **#25a** — Parsear metadata de la máquina (OS, dificultad, puntos) al crear el engagement
- [ ] **#25b** — Pre-poblar context.md con información pública disponible (OS fingerprint esperado)

---

## M6 — Threat Intelligence `v2.1.0`

> Conecta los hallazgos del engagement con inteligencia de amenazas externa. Los IOCs
> encontrados durante el engagement se correlacionan automáticamente con feeds de amenazas.

**Criterio de cierre:** al ejecutar `/vuln-scan` sobre un target con IOCs conocidos,
el finding generado incluye contexto de TI sin intervención manual.

---

### #26 — `enhancement` `priority: high`
**Integración con MISP para correlación de IOCs**

- [ ] **#26a** — Conexión a instancia MISP via PyMISP con URL y API key en `.env`
- [ ] **#26b** — Al tokenizar una IP/hash/dominio, buscar matches en MISP automáticamente
- [ ] **#26c** — Si hay match, agregar sección "Threat Context" al finding correspondiente
- [ ] **#26d** — Comando `/ti lookup <token>` para búsqueda manual de un IOC

---

### #27 — `enhancement` `priority: medium`
**Integración con OpenCTI**

- [ ] **#27a** — Cliente HTTP para la GraphQL API de OpenCTI
- [ ] **#27b** — Enrichment de observables (IPs, dominios) con contexto de actor y campaña
- [ ] **#27c** — Exportar IOCs del engagement a OpenCTI como nuevo bundle STIX 2.1

---

### #28 — `enhancement` `priority: medium`
**Enrichment de IPs con threat feeds públicos**

- [ ] **#28a** — Integración con AbuseIPDB para score de reputación de IPs del scope
- [ ] **#28b** — Integración con Shodan para contexto pasivo (sin escaneo activo)
- [ ] **#28c** — Integración con VirusTotal para hashes de artefactos encontrados
- [ ] **#28d** — Respetar DLP: enrichment usa tokens, no IPs reales en las llamadas de API

---

### #29 — `enhancement` `priority: low`
**Correlación automática IOCs ↔ findings MITRE**

- [ ] **#29a** — Cruzar técnicas MITRE detectadas con grupos de actores conocidos en MISP/OpenCTI
- [ ] **#29b** — Incluir sección "Threat Actor Context" en el reporte ejecutivo si hay correlación

---

## M7 — Multi-Engagement Dashboard `v2.2.0`

> Interfaz TUI local para operadores que llevan múltiples engagements simultáneos.
> Vista unificada, exportación a herramientas de gestión y notificaciones opcionales.

**Criterio de cierre:** el dashboard arranca en <1s, muestra todos los engagements
activos con su estado y permite navegar a cualquier finding sin salir de la vista.

---

### #30 — `enhancement` `priority: high` `needs-design`
**Dashboard TUI local con Textual/Rich**

- [ ] **#30a** — Pantalla principal: tabla de engagements con columnas estado/hallazgos/próximo paso
- [ ] **#30b** — Panel de detalle: findings del engagement seleccionado con severidad en color
- [ ] **#30c** — Atajo de teclado para abrir el context.md del engagement en el editor del sistema
- [ ] **#30d** — Comando `/dashboard` que lanza la TUI

---

### #31 — `enhancement` `priority: medium`
**Vista unificada de findings cross-engagement**

- [ ] **#31a** — Agregar vista "All Findings" que agrupa hallazgos de todos los engagements activos
- [ ] **#31b** — Filtrado por severidad, MITRE tactic y estado (open/mitigated/accepted)
- [ ] **#31c** — Exportación de la vista filtrada a CSV/JSON

---

### #32 — `enhancement` `priority: medium`
**Exportación de findings a Jira y Confluence**

- [ ] **#32a** — Comando `/export jira <engagement>` que crea tickets por cada finding
- [ ] **#32b** — Mapeo de severidad CVSS → prioridad Jira (Critical→P1, High→P2, etc.)
- [ ] **#32c** — Comando `/export confluence <engagement>` que publica el reporte como página

---

### #33 — `enhancement` `priority: low`
**Sistema de notificaciones para eventos del engagement**

- [ ] **#33a** — Notificación local (notify-send) cuando un escaneo autónomo completa
- [ ] **#33b** — Webhook opcional a Slack cuando se genera un finding de severidad crítica
- [ ] **#33c** — Configuración de canales en `config/notifications.yaml`

---

## M8 — DevSecOps Pipeline `v2.3.0`

> Hace el proyecto mantenible y confiable a escala. CI automatizado, imagen Docker
> firmada, tests de integración y release semántico sin intervención manual.

**Criterio de cierre:** cada PR pasa CI en <5 minutos. La imagen publicada tiene firma
verificable. El número de versión en CHANGELOG y tags git siempre está sincronizado.

---

### #34 — `ci/cd` `priority: high`
**GitHub Actions: test suite y Trivy scan en cada PR**

- [ ] **#34a** — Workflow `ci.yml`: lint de shell (shellcheck), pytest para tools Python
- [ ] **#34b** — Workflow `security.yml`: Trivy scan de imagen Docker, bloquear en CVEs CRITICAL
- [ ] **#34c** — Status checks requeridos antes de merge a main
- [ ] **#34d** — Matrix de Python versions (3.11, 3.12, 3.13) para tools Python

---

### #35 — `ci/cd` `priority: medium`
**Firmado de imagen Docker con cosign/sigstore**

- [ ] **#35a** — Integrar `cosign` en el workflow de build y push
- [ ] **#35b** — Publicar firma en registro público de sigstore Rekor
- [ ] **#35c** — Documentar verificación de firma en README para usuarios que descarguen la imagen

---

### #36 — `ci/cd` `priority: medium`
**Perfiles AppArmor y Seccomp para el contenedor**

- [ ] **#36a** — Generar perfil AppArmor mínimo que permita solo syscalls necesarias
- [ ] **#36b** — Perfil Seccomp equivalente para compatibilidad con entornos sin AppArmor
- [ ] **#36c** — Integrar perfiles en docker-compose.yml como default

---

### #37 — `ci/cd` `priority: medium`
**Release semántico automatizado**

- [ ] **#37a** — Workflow `release.yml` disparado en push a main con conventional commits
- [ ] **#37b** — Auto-incrementar versión en CHANGELOG.md, README y Dockerfile
- [ ] **#37c** — Crear GitHub Release con notas generadas desde commits
- [ ] **#37d** — Taggear imagen Docker con semver y `latest`

---

## M9 — Payload Engine Contextual `v2.4.0`

> Módulo de generación de payloads adaptados al entorno detectado. Toma el fingerprint
> del target (OS, servicios, AV detectado) y propone vectores de explotación específicos.
> Requiere confirmación explícita del operador antes de cualquier generación.

**Criterio de cierre:** el agente propone al menos 3 variantes de payload ordenadas por
probabilidad de éxito dado el fingerprint, sin generar ninguna hasta confirmación.

---

### #38 — `enhancement` `priority: high` `needs-design`
**Generación de payloads adaptados al fingerprint del target**

- [ ] **#38a** — Leer fingerprint de OS/servicios desde el context.md del engagement
- [ ] **#38b** — Mapear fingerprint a lista de vectores candidatos ordenados por éxito estimado
- [ ] **#38c** — Proponer variantes (staged/stageless, arquitectura, protocolo) antes de generar
- [ ] **#38d** — Confirmación obligatoria con display de exactamente qué se va a generar

---

### #39 — `enhancement` `priority: medium`
**Generación de stagers para Metasploit con contexto del engagement**

- [ ] **#39a** — Comando `/generate-stager <engagement> <lhost> <lport>` como shortcut de msfvenom
- [ ] **#39b** — Auto-seleccionar payload por OS detectado en context.md
- [ ] **#39c** — Guardar stager generado en `findings/<engagement>/exploitation/` con metadatos

---

### #40 — `enhancement` `priority: medium`
**Encoders y técnicas de evasión básicas**

- [ ] **#40a** — Soporte para encoders de msfvenom seleccionados por AV detectado
- [ ] **#40b** — Documentación clara de límites éticos y legales de esta funcionalidad
- [ ] **#40c** — Gate de scope obligatorio: solo genera payloads si el target está en scope.md

---

### #41 — `enhancement` `priority: low`
**Auto-selección de exploit por OS y servicio fingerprint**

- [ ] **#41a** — Cruzar fingerprint con exploits de searchsploit y Metasploit modules
- [ ] **#41b** — Rankear por reliability, fecha y presencia de PoC público
- [ ] **#41c** — Presentar shortlist al operador con resumen de cada opción

---

## M10 — Enterprise & API Pública `v3.0.0`

> Visión a largo plazo: OffSec Assistant como plataforma. API REST que permite integrar
> el asistente en pipelines externos, soporte multi-operador con permisos y un CLI
> standalone que no requiere Claude Code para despliegues automatizados.

**Breaking changes:** arquitectura de carpetas y formato de context.md cambia a v2.
Script de migración incluido. Los engagements v1.x no son compatibles sin migración.

---

### #42 — `enhancement` `priority: medium` `needs-design`
**API REST del OffSec Assistant (FastAPI)**

- [ ] **#42a** — Endpoints para crear/leer/actualizar engagements via HTTP
- [ ] **#42b** — Endpoint para disparar fases (recon, vuln-scan) de forma programática
- [ ] **#42c** — Autenticación con API key local, sin dependencia de servicios externos
- [ ] **#42d** — Documentación OpenAPI auto-generada accesible en `/docs`

---

### #43 — `enhancement` `priority: medium`
**Soporte multi-operador con RBAC básico**

- [ ] **#43a** — Roles: `admin`, `operator`, `reviewer` con permisos diferenciados
- [ ] **#43b** — `admin` gestiona operadores y acceso a engagements
- [ ] **#43c** — `reviewer` tiene acceso read-only (ver M4/#19)
- [ ] **#43d** — Audit trail incluye campo `operator_id` para trazabilidad

---

### #44 — `enhancement` `priority: medium`
**CLI standalone sin dependencia de Claude Code**

- [ ] **#44a** — Wrapper Python que llama la Anthropic API directamente
- [ ] **#44b** — Paridad de comandos con el sistema de slash commands actual
- [ ] **#44c** — Instalable via `pip install offsec-assistant`
- [ ] **#44d** — Documentar modo standalone en README con tabla de diferencias vs Claude Code

---

### #45 — `enhancement` `priority: low`
**Plugin system para herramientas custom del operador**

- [ ] **#45a** — Definir interfaz de plugin: shell script o Python con metadata YAML
- [ ] **#45b** — Directorio `plugins/` cargado automáticamente al inicio
- [ ] **#45c** — Los plugins se exponen como subcomandos de `/run-plugin <nombre>`
- [ ] **#45d** — Documentar guía de desarrollo de plugins en CONTRIBUTING.md

---

### #46 — `enhancement` `priority: low`
**Webhooks de notificación para integración con pipelines externos**

- [ ] **#46a** — Evento webhook en cada cambio de estado de engagement (opened, finding-added, closed)
- [ ] **#46b** — Payload JSON con schema documentado y versionado
- [ ] **#46c** — Retry con backoff exponencial ante fallos de entrega

---

## Issues sin Milestone

Issues que no pertenecen a una fase específica. Pueden abrirse y cerrarse en cualquier
ciclo. Tienen prioridad propia y se trabajan en paralelo a los milestones activos.

---

### Bugs

| # | Título | Labels |
|---|--------|--------|
| #B1 | `logs/` no se crea automáticamente en instalaciones nuevas, session_log falla silenciosamente | `bug` `priority: high` |
| #B2 | run-ad-enum.sh no verifica si bloodhound-python está instalado antes de ejecutar | `bug` `priority: medium` |
| #B3 | map-mitre.py lanza KeyError si el keyword no tiene mapping exacto (sin fuzzy fallback) | `bug` `priority: medium` |
| #B4 | `/session-close` no hace commit si no hay cambios staged, pero tampoco avisa | `bug` `priority: low` |
| #B5 | parse-privesc.py falla con UnicodeDecodeError en outputs de winPEAS con caracteres especiales | `bug` `priority: medium` |

---

### Security Fixes

| # | Título | Labels |
|---|--------|--------|
| #S1 | `.env.example` contiene comentarios que revelan estructura interna de rutas y servicios | `security-fix` `priority: high` |
| #S2 | `burp-api.py` loguea la API key completa en stderr cuando falla la conexión | `security-fix` `priority: critical` |
| #S3 | `docker-compose.yml` monta el socket Docker del host (`/var/run/docker.sock`) sin necesidad | `security-fix` `priority: high` |
| #S4 | Imagen Docker base no tiene versión pinned — un rebuild puede traer dependencias vulnerables | `security-fix` `priority: medium` |

---

### Testing

| # | Título | Labels |
|---|--------|--------|
| #T1 | Crear test suite pytest para `sanitizer.py` (IPv4, IPv6, credenciales, edge cases) | `testing` `priority: high` |
| #T2 | Tests de integración para `auto-runner.sh` con target mockeado | `testing` `priority: high` |
| #T3 | Test de regresión: validar que `dlp-map.json` no puede ser staged en git | `testing` `priority: high` |
| #T4 | Test de carga del DLP con outputs grandes de nmap (>10MB) | `testing` `priority: medium` |
| #T5 | Test de regresión del scope gate: verificar bloqueo con scope.md vacío, inexistente y válido | `testing` `priority: high` |
| #T6 | Tests unitarios para `map-mitre.py`: cobertura de las 60+ técnicas documentadas | `testing` `priority: medium` |
| #T7 | Smoke test de Docker: build + `/check-tools` + `/new-engagement test` en CI | `testing` `priority: high` |

---

### Documentación

| # | Título | Labels |
|---|--------|--------|
| #D1 | Guía de desarrollo de comandos custom (`.claude/commands/`) con ejemplo paso a paso | `documentation` `priority: high` `good-first-issue` |
| #D2 | Documentar schema interno de `context.md` y todos sus campos con descripción y ejemplo | `documentation` `priority: medium` |
| #D3 | Documentar API pública de `sanitizer.py` con docstrings y ejemplos de uso | `documentation` `priority: medium` |
| #D4 | Traducción del README al inglés para aumentar alcance en la comunidad de seguridad | `documentation` `priority: low` `help-wanted` |
| #D5 | Wiki: preguntas frecuentes y troubleshooting (Docker, VPN, permisos, herramientas faltantes) | `documentation` `priority: medium` `good-first-issue` |
| #D6 | Vídeo walkthrough del flujo completo de engagement (recon → report) | `documentation` `priority: low` |
| #D7 | Documentar schema del audit trail JSON (#18) para integración con Splunk/Elastic/Wazuh | `documentation` `priority: medium` |

---

## Convenciones de gestión

### Apertura de issues

- Un issue por cambio atómico. Si el trabajo puede dividirse en dos PRs independientes,
  son dos issues.
- El título sigue la forma: `<verbo en infinitivo>: <descripción concreta>`.
  Ej: `Agregar soporte IPv6 en sanitizer.py`, no `sanitizer IPv6 broken`.
- Los sub-issues se listan en el cuerpo del issue padre con checkboxes y referencia cruzada.

### Criterio de cierre de milestone

Un milestone se cierra cuando **todos** sus issues están cerrados o explícitamente
pospuestos al siguiente ciclo con comentario de justificación. No se cierra un milestone
con issues abiertos marcados como "in progress".

### Versionado

Este proyecto sigue [Semantic Versioning](https://semver.org/):
- `MAJOR`: cambios de arquitectura o breaking changes en la estructura de engagements
- `MINOR`: nuevo milestone completado (funcionalidades nuevas, backward-compatible)
- `PATCH`: bugs, security fixes y issues sin milestone

### Relación con CHANGELOG.md

Cada issue cerrado que produce un cambio observable debe tener entrada en
`[Unreleased]` de `CHANGELOG.md` antes de que el PR sea mergeado.

---

*Última actualización: 2026-06-10 — v1.0.0 base*
