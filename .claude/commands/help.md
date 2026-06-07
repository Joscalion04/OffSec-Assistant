Muestra la guía completa del OffSec Assistant.

Si el usuario escribe solo "/help", muestra el menú general completo.
Si el usuario escribe "/help <comando>", muestra la ayuda detallada de ese comando específico.

---

## MENÚ GENERAL

Presenta exactamente así:
╔══════════════════════════════════════════════════════════════╗
║           OffSec Assistant — Guía de comandos               ║
╠══════════════════════════════════════════════════════════════╣
║  /help <comando>   Para ayuda detallada de cualquier opción  ║
╚══════════════════════════════════════════════════════════════╝
📁 GESTIÓN DE ENGAGEMENTS
──────────────────────────────────────────────────────────────
/new-engagement <nombre>     Inicializa un nuevo engagement completo
/status [engagement]         Estado actual y progreso del engagement
/morning-brief               Resumen de todos los engagements activos
/session-close [engagement]  Cierra sesión, commit git y genera resumen
🔍 FASES DE PENTESTING
──────────────────────────────────────────────────────────────
/recon <target> [-auto]      Reconocimiento pasivo y activo
/vuln-scan <target> [-auto]  Análisis de vulnerabilidades
/exploit <target> [-auto]    Vectores de explotación (siempre pide confirmación)
🧠 ASISTENCIA Y DECISIONES
──────────────────────────────────────────────────────────────
/think <situación>           Razonamiento guiado sobre un problema
/explain <CVE o técnica>     Explicación técnica contextualizada
/livefeed                    Cómo seguir la ejecución autónoma en vivo
📄 DOCUMENTACIÓN Y REPORTES
──────────────────────────────────────────────────────────────
/report <engagement>         Genera reporte final completo en español
🛠️  UTILIDADES
──────────────────────────────────────────────────────────────
/check-tools                 Verifica herramientas instaladas en el sistema
💬 MODO CONVERSACIONAL
──────────────────────────────────────────────────────────────
Sin comandos — Hablá directamente: "estoy trabado en X", "qué harías con Y"
El agente decision-advisor se activa automáticamente cuando detecta que
necesitás razonar un problema, no ejecutar un comando.
⚡ FLAG ESPECIAL
──────────────────────────────────────────────────────────────
-auto    Disponible en /recon, /vuln-scan y /exploit
Ejecuta la fase de forma autónoma con live feed en tiempo real
Ver: /help -auto

---

## AYUDA DETALLADA POR COMANDO

Cuando el usuario pide "/help <comando>", mostrá la ficha correspondiente:

### /help new-engagement
📁 /new-engagement <nombre>
─────────────────────────────────────────────
Descripción:
Inicializa la estructura completa de un nuevo engagement de pentesting.
Crea carpetas, copia plantillas, inicializa git y pre-llena context.md.
Parámetros:
<nombre>   Nombre del engagement (usar guiones, sin espacios)
Ejemplo: cliente-acme, lab-htb-machines, bugbounty-ejemplo-com
Respuesta esperada:
✅ Confirmación de carpetas creadas
📋 Estructura de archivos generada
📌 Próximos pasos: editar scope.md antes de cualquier acción activa
Ejemplo:
/new-engagement acme-corp-2026
Archivos creados:
findings/YYYY-MM-DD_<nombre>/
├── scope.md              ← EDITAR ANTES DE CONTINUAR
├── context.md            ← cerebro vivo del engagement
├── finding_template.md
├── recon/
├── vulns/
├── exploitation/
├── post-exploitation/
├── evidence/{screenshots,captures,files}
└── notes/session_log.md

### /help status
📊 /status [engagement]
─────────────────────────────────────────────
Descripción:
Muestra el estado actual del engagement: fases completadas, hallazgos,
vectores pendientes y próximo paso recomendado.
Parámetros:
[engagement]   Nombre o parte del nombre del engagement (opcional)
Si se omite, usa el engagement más recientemente modificado
Respuesta esperada:
Tabla de progreso por fase (✅ Completo / 🔄 En progreso / ⬜ Pendiente)
Lista de hallazgos actuales con severidad
Vectores pendientes de explorar
Recomendación concreta del próximo paso
Ejemplo:
/status
/status acme-corp

### /help morning-brief
☀️  /morning-brief
─────────────────────────────────────────────
Descripción:
Genera un briefing de inicio de día revisando todos los engagements activos.
Lee scope.md, context.md y logs de sesión de cada engagement.
Parámetros:
Ninguno
Respuesta esperada:
Lista de engagements activos con cliente, deadline y días restantes
Pendientes de cada engagement
⚠️ Alertas si algún deadline es en menos de 3 días
Recomendación de foco para el día (un solo engagement o tarea)
Uso recomendado:
Primer comando al iniciar el día de trabajo

### /help session-close
🔒 /session-close [engagement]
─────────────────────────────────────────────
Descripción:
Cierra la sesión de trabajo: genera resumen, actualiza context.md,
hace commit git con todo lo trabajado.
Parámetros:
[engagement]   Nombre del engagement a cerrar (opcional)
Si se omite, pregunta cuál cerrar
Respuesta esperada:
Resumen de sesión: duración, comandos ejecutados, hallazgos documentados
Lista de pendientes para la próxima sesión
Confirmación de commit git realizado
Próximo paso recomendado para la siguiente sesión
Uso recomendado:
Último comando al terminar el día de trabajo

### /help recon
🔍 /recon <target> [-auto]
─────────────────────────────────────────────
Descripción:
Reconocimiento completo sobre un target: WHOIS, DNS, subdominios,
escaneo de puertos, detección de servicios y tecnologías web.
Parámetros:
<target>   IP o dominio autorizado en scope.md
-auto      Ejecución autónoma sin interrupciones (ver /help -auto)
Fases ejecutadas:

WHOIS y registros DNS (pasivo)
Enumeración de subdominios (pasivo)
Nmap top-1000 puertos
Detección de servicios y versiones
Detección de tecnologías web (si hay HTTP/HTTPS)

Respuesta esperada (sin -auto):
Resultados parciales por fase con opción de continuar o pausar
Respuesta esperada (con -auto):
Ruta del live feed para seguir en otra terminal
Ejecución completa autónoma con decisiones explicadas
Resumen final + actualización de context.md
Archivos generados:
findings/<engagement>/recon/whois.txt
findings/<engagement>/recon/dns.txt
findings/<engagement>/recon/subdomains.txt
findings/<engagement>/recon/nmap_ports.txt
findings/<engagement>/recon/nmap_services.txt
findings/<engagement>/recon/whatweb.txt
Ejemplos:
/recon 192.168.1.50
/recon ejemplo.com -auto

### /help vuln-scan
🔎 /vuln-scan <target> [-auto]
─────────────────────────────────────────────
Descripción:
Análisis de vulnerabilidades basado en resultados de recon.
Correlaciona servicios con CVEs, ejecuta Nikto y Nuclei en web.
Parámetros:
<target>   IP o dominio (debe estar en scope.md)
-auto      Ejecución autónoma (ver /help -auto)
Prerequisito recomendado:
Tener recon previo en findings/<engagement>/recon/
Si no existe, el agente pregunta si ejecutar /recon primero
Fases ejecutadas:

Nmap --script vuln en puertos abiertos
Correlación con ExploitDB via searchsploit
Nikto (si hay web)
Nuclei templates critical/high (si hay web)

Respuesta esperada:
Hallazgos ordenados por severidad
Pre-llenado automático de finding.md por el agente doc-writer
Actualización de context.md con vectores identificados
Ejemplos:
/vuln-scan 192.168.1.50
/vuln-scan 192.168.1.50 -auto

### /help exploit
💥 /exploit <target> [-auto]
─────────────────────────────────────────────
Descripción:
Analiza vectores de explotación y propone estrategia priorizada.
SIEMPRE pide confirmación antes de ejecutar cualquier exploit,
independientemente del flag -auto.
Parámetros:
<target>   IP o dominio (debe estar en scope.md)
-auto      Automatiza el análisis y preparación, NO la ejecución
Comportamiento de confirmación:
El agente presenta el comando exacto y espera que escribas:
"sí, ejecutar" para proceder
Cualquier otra respuesta cancela la ejecución
Respuesta esperada:
Tabla de vectores priorizados por probabilidad × impacto
Comando exacto preparado para el vector recomendado
Solicitud de confirmación explícita antes de ejecutar
⚠️  Nota de seguridad:
Este comando nunca ejecuta exploits destructivos sin confirmación.
Siempre documenta cada intento en context.md.
Ejemplos:
/exploit 192.168.1.50
/exploit 192.168.1.50 -auto

### /help think
🧠 /think <situación>
─────────────────────────────────────────────
Descripción:
Activa razonamiento guiado sobre un problema ofensivo.
El agente decision-advisor piensa en voz alta y da UNA recomendación concreta.
Parámetros:
<situación>   Descripción libre del problema o contexto actual
Cuanto más detalle, mejor el análisis
Estructura de respuesta:

Hechos confirmados
Suposiciones (marcadas explícitamente)
Gaps de información
Perspectiva del atacante real
Vectores posibles ordenados por probabilidad × impacto
Riesgos por vector
Recomendación final — UN solo próximo paso

Ejemplos:
/think tengo puerto 445 abierto en un Windows Server 2016
/think el login no responde a SQLi básico pero hay diferencia de tiempo en usuarios válidos
/think estoy en la máquina pero soy usuario de bajos privilegios

### /help explain
📖 /explain <CVE o técnica>
─────────────────────────────────────────────
Descripción:
Explica cualquier CVE, técnica ofensiva o concepto de seguridad,
adaptado al contexto del engagement activo si existe.
Parámetros:
<CVE o técnica>   Identificador CVE, nombre de técnica o concepto
Ejemplos: CVE-2021-41773, pass-the-hash, SSRF, LFI
Estructura de respuesta:

Qué es y cómo funciona
Por qué importa en un pentest
Cómo detectarlo en un escaneo
Cómo explotarlo (conceptual + técnico)
Herramientas que lo automatizan
Cómo remediarlo (para el reporte)
Relevancia en tu engagement actual (si hay context.md)

Para CVEs: CVSS score, versiones afectadas, exploit disponible
Para técnicas: comando de ejemplo concreto
Ejemplos:
/explain CVE-2021-41773
/explain pass-the-hash
/explain SSRF
/explain privilege escalation linux

### /help report
📄 /report <engagement>
─────────────────────────────────────────────
Descripción:
Genera el reporte final de pentesting en español, compilando
toda la información del engagement.
Parámetros:
<engagement>   Nombre o parte del nombre del engagement
Estructura del reporte generado:

Executive Summary (no técnico, para gerencia)
Scope y metodología aplicada
Hallazgos por severidad (Critical → Informational)

Descripción, evidencia, impacto, remediación por cada uno

Conclusiones y recomendaciones generales

Archivos de entrada leídos:
findings/<engagement>/context.md
findings/<engagement>/vulns/*.md
findings/<engagement>/scope.md
Archivo generado:
reports/<engagement>_report_YYYY-MM-DD.md
Ejemplo:
/report acme-corp-2026

### /help check-tools
🛠️  /check-tools
─────────────────────────────────────────────
Descripción:
Verifica qué herramientas de seguridad están instaladas en el sistema
y proporciona el comando de instalación para las que falten (Arch/Manjaro).
Parámetros:
Ninguno
Herramientas verificadas:
Reconocimiento: nmap, masscan, amass, subfinder, theHarvester
Web:            ffuf, nikto, sqlmap, nuclei, whatweb, gobuster
Explotación:    metasploit, searchsploit
Post-explot:    netcat, socat
Utilidades:     git, python3, pip, curl, wget, jq, whois, dig
Respuesta esperada:
Tabla: Herramienta | Estado | Comando de instalación
Resumen: X/Y herramientas instaladas

### /help livefeed
📡 /livefeed
─────────────────────────────────────────────
Descripción:
Muestra cómo seguir el live feed de la ejecución autónoma actual
en una segunda terminal.
Parámetros:
Ninguno
Respuesta esperada:
Comando tail -f con la ruta del log más reciente
Leyenda completa de iconos del live feed
Leyenda de iconos:
🔍 START    — comando iniciado
✅ DONE     — comando completado
⚠️  FIND     — hallazgo menor o advertencia
🔴 CRITICAL — hallazgo crítico
🧠 THINK    — decisión tomada por el agente
⏭️  SKIP     — herramienta no disponible
📍 PHASE    — inicio de nueva fase
📋 PLAN     — plan de ejecución
🛑 CONFIRM  — requiere confirmación del operador
📊 SUMMARY  — resumen final

### /help -auto
⚡ Flag -auto
─────────────────────────────────────────────
Descripción:
Activa el modo de ejecución autónoma en los comandos de pentesting.
El agente ejecuta la fase completa sin interrupciones, tomando
decisiones inteligentes basadas en los resultados de cada herramienta.
Disponible en:
/recon <target> -auto
/vuln-scan <target> -auto
/exploit <target> -auto    ← siempre pide confirmación igual
Comportamiento con -auto:
✅ Verifica scope.md antes de iniciar
✅ Muestra el plan completo antes de ejecutar
✅ Ejecuta herramientas en orden lógico (pasivo → activo)
✅ Toma decisiones basadas en resultados intermedios
✅ Escribe live feed en terminal Y en archivo simultáneamente
✅ Actualiza context.md al finalizar
✅ Presenta resumen y próximo paso recomendado
Live feed — seguir en otra terminal:
tail -f ~/Documents/OffSec/OffSec-Assistant/logs/livefeed/<archivo>.log
Qué NUNCA hace -auto:
⛔ Ejecutar contra targets fuera de scope.md
⛔ Ejecutar exploits sin confirmación explícita
⛔ Ejecutar herramientas destructivas (DoS, rm, dd)
