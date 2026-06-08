Muestra la guia completa del OffSec Assistant.

Si el usuario escribe solo "/help", muestra el menu general completo.
Si el usuario escribe "/help <comando>", muestra la ayuda detallada de ese comando especifico.

---

## MENU GENERAL

Presenta exactamente asi:
╔══════════════════════════════════════════════════════════════╗
║           OffSec Assistant — Guia de comandos               ║
╠══════════════════════════════════════════════════════════════╣
║  /help <comando>   Para ayuda detallada de cualquier opcion  ║
╚══════════════════════════════════════════════════════════════╝
-- GESTION DE ENGAGEMENTS
──────────────────────────────────────────────────────────────
/new-engagement <nombre>     Inicializa un nuevo engagement completo
/status [engagement]         Estado actual y progreso del engagement
/morning-brief               Resumen de todos los engagements activos
/session-close [engagement]  Cierra sesion, commit git y genera resumen
-- FASES DE PENTESTING
──────────────────────────────────────────────────────────────
/recon <target> [-auto]      Reconocimiento pasivo y activo
/vuln-scan <target> [-auto]  Analisis de vulnerabilidades
/exploit <target> [-auto]    Vectores de explotacion (siempre pide confirmacion)
-- ASISTENCIA Y DECISIONES
──────────────────────────────────────────────────────────────
/think <situacion>           Razonamiento guiado sobre un problema
/explain <CVE o tecnica>     Explicacion tecnica contextualizada
/livefeed                    Como seguir la ejecucion autonoma en vivo
-- DOCUMENTACION Y REPORTES
──────────────────────────────────────────────────────────────
/report <engagement>         Genera reporte final completo en espanol
-- UTILIDADES
──────────────────────────────────────────────────────────────
/check-tools                 Verifica herramientas instaladas en el sistema
-- MODO CONVERSACIONAL
──────────────────────────────────────────────────────────────
Sin comandos — Habla directamente: "estoy trabado en X", "que harias con Y"
El agente decision-advisor se activa automaticamente cuando detecta que
necesitas razonar un problema, no ejecutar un comando.
-- FLAG ESPECIAL
──────────────────────────────────────────────────────────────
-auto    Disponible en /recon, /vuln-scan y /exploit
Ejecuta la fase de forma autonoma con live feed en tiempo real
Ver: /help -auto

---

## AYUDA DETALLADA POR COMANDO

Cuando el usuario pide "/help <comando>", mostra la ficha correspondiente:

### /help new-engagement
/new-engagement <nombre>
─────────────────────────────────────────────
Descripcion:
Inicializa la estructura completa de un nuevo engagement de pentesting.
Crea carpetas, copia plantillas, inicializa git y pre-llena context.md.
Parametros:
<nombre>   Nombre del engagement (usar guiones, sin espacios)
Ejemplo: cliente-acme, lab-htb-machines, bugbounty-ejemplo-com
Respuesta esperada:
[OK] Confirmacion de carpetas creadas
[OK] Estructura de archivos generada
[>]  Proximos pasos: editar scope.md antes de cualquier accion activa
Ejemplo:
/new-engagement acme-corp-2026
Archivos creados:
findings/YYYY-MM-DD_<nombre>/
|-- scope.md              <- EDITAR ANTES DE CONTINUAR
|-- context.md            <- cerebro vivo del engagement
|-- finding_template.md
|-- recon/
|-- vulns/
|-- exploitation/
|-- post-exploitation/
|-- evidence/{screenshots,captures,files}
`-- notes/session_log.md

### /help status
/status [engagement]
─────────────────────────────────────────────
Descripcion:
Muestra el estado actual del engagement: fases completadas, hallazgos,
vectores pendientes y proximo paso recomendado.
Parametros:
[engagement]   Nombre o parte del nombre del engagement (opcional)
Si se omite, usa el engagement mas recientemente modificado
Respuesta esperada:
Tabla de progreso por fase ([OK] Completo / [~] En progreso / [ ] Pendiente)
Lista de hallazgos actuales con severidad
Vectores pendientes de explorar
Recomendacion concreta del proximo paso
Ejemplo:
/status
/status acme-corp

### /help morning-brief
/morning-brief
─────────────────────────────────────────────
Descripcion:
Genera un briefing de inicio de dia revisando todos los engagements activos.
Lee scope.md, context.md y logs de sesion de cada engagement.
Parametros:
Ninguno
Respuesta esperada:
Lista de engagements activos con cliente, deadline y dias restantes
Pendientes de cada engagement
[!] Alertas si algun deadline es en menos de 3 dias
Recomendacion de foco para el dia (un solo engagement o tarea)
Uso recomendado:
Primer comando al iniciar el dia de trabajo

### /help session-close
/session-close [engagement]
─────────────────────────────────────────────
Descripcion:
Cierra la sesion de trabajo: genera resumen, actualiza context.md,
hace commit git con todo lo trabajado.
Parametros:
[engagement]   Nombre del engagement a cerrar (opcional)
Si se omite, pregunta cual cerrar
Respuesta esperada:
Resumen de sesion: duracion, comandos ejecutados, hallazgos documentados
Lista de pendientes para la proxima sesion
Confirmacion de commit git realizado
Proximo paso recomendado para la siguiente sesion
Uso recomendado:
Ultimo comando al terminar el dia de trabajo

### /help recon
/recon <target> [-auto]
─────────────────────────────────────────────
Descripcion:
Reconocimiento completo sobre un target: WHOIS, DNS, subdominios,
escaneo de puertos, deteccion de servicios y tecnologias web.
Parametros:
<target>   IP o dominio autorizado en scope.md
-auto      Ejecucion autonoma sin interrupciones (ver /help -auto)
Fases ejecutadas:

WHOIS y registros DNS (pasivo)
Enumeracion de subdominios (pasivo)
Nmap top-1000 puertos
Deteccion de servicios y versiones
Deteccion de tecnologias web (si hay HTTP/HTTPS)

Respuesta esperada (sin -auto):
Resultados parciales por fase con opcion de continuar o pausar
Respuesta esperada (con -auto):
Ruta del live feed para seguir en otra terminal
Ejecucion completa autonoma con decisiones explicadas
Resumen final + actualizacion de context.md
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
/vuln-scan <target> [-auto]
─────────────────────────────────────────────
Descripcion:
Analisis de vulnerabilidades basado en resultados de recon.
Correlaciona servicios con CVEs, ejecuta Nikto y Nuclei en web.
Parametros:
<target>   IP o dominio (debe estar en scope.md)
-auto      Ejecucion autonoma (ver /help -auto)
Prerequisito recomendado:
Tener recon previo en findings/<engagement>/recon/
Si no existe, el agente pregunta si ejecutar /recon primero
Fases ejecutadas:

Nmap --script vuln en puertos abiertos
Correlacion con ExploitDB via searchsploit
Nikto (si hay web)
Nuclei templates critical/high (si hay web)

Respuesta esperada:
Hallazgos ordenados por severidad
Pre-llenado automatico de finding.md por el agente doc-writer
Actualizacion de context.md con vectores identificados
Ejemplos:
/vuln-scan 192.168.1.50
/vuln-scan 192.168.1.50 -auto

### /help exploit
/exploit <target> [-auto]
─────────────────────────────────────────────
Descripcion:
Analiza vectores de explotacion y propone estrategia priorizada.
SIEMPRE pide confirmacion antes de ejecutar cualquier exploit,
independientemente del flag -auto.
Parametros:
<target>   IP o dominio (debe estar en scope.md)
-auto      Automatiza el analisis y preparacion, NO la ejecucion
Comportamiento de confirmacion:
El agente presenta el comando exacto y espera que escribas:
"si, ejecutar" para proceder
Cualquier otra respuesta cancela la ejecucion
Respuesta esperada:
Tabla de vectores priorizados por probabilidad x impacto
Comando exacto preparado para el vector recomendado
Solicitud de confirmacion explicita antes de ejecutar
[!] Nota de seguridad:
Este comando nunca ejecuta exploits destructivos sin confirmacion.
Siempre documenta cada intento en context.md.
Ejemplos:
/exploit 192.168.1.50
/exploit 192.168.1.50 -auto

### /help think
/think <situacion>
─────────────────────────────────────────────
Descripcion:
Activa razonamiento guiado sobre un problema ofensivo.
El agente decision-advisor piensa en voz alta y da UNA recomendacion concreta.
Parametros:
<situacion>   Descripcion libre del problema o contexto actual
Cuanto mas detalle, mejor el analisis
Estructura de respuesta:

Hechos confirmados
Suposiciones (marcadas explicitamente)
Gaps de informacion
Perspectiva del atacante real
Vectores posibles ordenados por probabilidad x impacto
Riesgos por vector
Recomendacion final — UN solo proximo paso

Ejemplos:
/think tengo puerto 445 abierto en un Windows Server 2016
/think el login no responde a SQLi basico pero hay diferencia de tiempo en usuarios validos
/think estoy en la maquina pero soy usuario de bajos privilegios

### /help explain
/explain <CVE o tecnica>
─────────────────────────────────────────────
Descripcion:
Explica cualquier CVE, tecnica ofensiva o concepto de seguridad,
adaptado al contexto del engagement activo si existe.
Parametros:
<CVE o tecnica>   Identificador CVE, nombre de tecnica o concepto
Ejemplos: CVE-2021-41773, pass-the-hash, SSRF, LFI
Estructura de respuesta:

Que es y como funciona
Por que importa en un pentest
Como detectarlo en un escaneo
Como explotarlo (conceptual + tecnico)
Herramientas que lo automatizan
Como remediarlo (para el reporte)
Relevancia en tu engagement actual (si hay context.md)

Para CVEs: CVSS score, versiones afectadas, exploit disponible
Para tecnicas: comando de ejemplo concreto
Ejemplos:
/explain CVE-2021-41773
/explain pass-the-hash
/explain SSRF
/explain privilege escalation linux

### /help report
/report <engagement>
─────────────────────────────────────────────
Descripcion:
Genera el reporte final de pentesting en espanol, compilando
toda la informacion del engagement.
Parametros:
<engagement>   Nombre o parte del nombre del engagement
Estructura del reporte generado:

Executive Summary (no tecnico, para gerencia)
Scope y metodologia aplicada
Hallazgos por severidad (Critical a Informational)

Descripcion, evidencia, impacto, remediacion por cada uno

Conclusiones y recomendaciones generales

Archivos de entrada leidos:
findings/<engagement>/context.md
findings/<engagement>/vulns/*.md
findings/<engagement>/scope.md
Archivo generado:
reports/<engagement>_report_YYYY-MM-DD.md
Ejemplo:
/report acme-corp-2026

### /help check-tools
/check-tools
─────────────────────────────────────────────
Descripcion:
Verifica que herramientas de seguridad estan instaladas en el sistema
y proporciona el comando de instalacion para las que falten (Arch/Manjaro).
Parametros:
Ninguno
Herramientas verificadas:
Reconocimiento: nmap, masscan, amass, subfinder, theHarvester
Web:            ffuf, nikto, sqlmap, nuclei, whatweb, gobuster
Explotacion:    metasploit, searchsploit
Post-explot:    netcat, socat
Utilidades:     git, python3, pip, curl, wget, jq, whois, dig
Respuesta esperada:
Tabla: Herramienta | Estado | Comando de instalacion
Resumen: X/Y herramientas instaladas

### /help livefeed
/livefeed
─────────────────────────────────────────────
Descripcion:
Muestra como seguir el live feed de la ejecucion autonoma actual
en una segunda terminal.
Parametros:
Ninguno
Respuesta esperada:
Comando tail -f con la ruta del log mas reciente
Leyenda completa de prefijos del live feed
Leyenda de prefijos:
[START]   — comando iniciado
[DONE]    — comando completado
[FIND]    — hallazgo menor o advertencia
[CRIT]    — hallazgo critico
[THINK]   — decision tomada por el agente
[SKIP]    — herramienta no disponible
[PHASE]   — inicio de nueva fase
[PLAN]    — plan de ejecucion
[CONF]    — requiere confirmacion del operador
[SUM]     — resumen final

### /help -auto
Flag -auto
─────────────────────────────────────────────
Descripcion:
Activa el modo de ejecucion autonoma en los comandos de pentesting.
El agente ejecuta la fase completa sin interrupciones, tomando
decisiones inteligentes basadas en los resultados de cada herramienta.
Disponible en:
/recon <target> -auto
/vuln-scan <target> -auto
/exploit <target> -auto    <- siempre pide confirmacion igual
Comportamiento con -auto:
[OK] Verifica scope.md antes de iniciar
[OK] Muestra el plan completo antes de ejecutar
[OK] Ejecuta herramientas en orden logico (pasivo a activo)
[OK] Toma decisiones basadas en resultados intermedios
[OK] Escribe live feed en terminal Y en archivo simultaneamente
[OK] Actualiza context.md al finalizar
[OK] Presenta resumen y proximo paso recomendado
Live feed — seguir en otra terminal:
tail -f ~/Documents/OffSec/OffSec-Assistant/logs/livefeed/<archivo>.log
Que NUNCA hace -auto:
[X] Ejecutar contra targets fuera de scope.md
[X] Ejecutar exploits sin confirmacion explicita
[X] Ejecutar herramientas destructivas (DoS, rm, dd)
