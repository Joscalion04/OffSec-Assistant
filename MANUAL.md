# OffSec Assistant — Manual de usuario

> Guia completa de instalacion, configuracion y uso del asistente.
> Para la descripcion general del proyecto ver [README.md](README.md).

---

## Indice

1. [Modos de ejecucion](#1-modos-de-ejecucion)
2. [Instalacion y configuracion](#2-instalacion-y-configuracion)
   - [Modo nativo](#21-modo-nativo)
   - [Modo Docker lite](#22-modo-docker-lite-recomendado)
   - [Modo Docker full con Metasploit](#23-modo-docker-full-con-metasploit)
   - [Modo Docker con VPN](#24-modo-docker-con-vpn)
3. [Primer uso](#3-primer-uso)
4. [Flujo de engagement completo](#4-flujo-de-engagement-completo)
   - [Inicio de sesion](#41-inicio-de-sesion)
   - [Crear un engagement](#42-crear-un-engagement)
   - [Definir el scope](#43-definir-el-scope)
   - [Inicializar el mapa DLP](#44-inicializar-el-mapa-dlp)
   - [Reconocimiento](#45-reconocimiento)
   - [Analisis de vulnerabilidades](#46-analisis-de-vulnerabilidades)
   - [Explotacion](#47-explotacion)
   - [Cierre de sesion](#48-cierre-de-sesion)
   - [Generar reporte](#49-generar-reporte)
5. [Control DLP — uso avanzado](#5-control-dlp--uso-avanzado)
6. [Live feed — seguir ejecucion autonoma](#6-live-feed--seguir-ejecucion-autonoma)
7. [Modo conversacional](#7-modo-conversacional)
8. [Referencia de comandos](#8-referencia-de-comandos)
9. [Tips y buenas practicas](#9-tips-y-buenas-practicas)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Modos de ejecucion

OffSec Assistant puede ejecutarse de dos formas:

| Modo | Cuando usarlo | Requisitos en el host |
|------|--------------|----------------------|
| **Nativo** | Maquina propia con herramientas ya instaladas | Claude Code + herramientas de pentesting |
| **Docker** | Cualquier maquina con Docker; entorno limpio y reproducible | Docker + Docker Compose + API key |

El modo Docker es el recomendado para engagements profesionales: garantiza las mismas
versiones de herramientas, aísla el entorno del host y soporta VPN de forma nativa.

---

## 2. Instalacion y configuracion

### 2.1 Modo nativo

```bash
# 1. Clonar el repositorio
git clone https://github.com/Joscalion04/OffSec-Assistant.git
cd OffSec-Assistant

# 2. Instalar herramientas de pentesting (Arch/Manjaro)
sudo pacman -S nmap masscan nikto sqlmap whatweb gobuster netcat socat \
               git python curl wget jq whois bind
yay -S amass subfinder theHarvester nuclei ffuf

# 3. Verificar herramientas instaladas
#    (hacer esto dentro de Claude Code)
/check-tools

# 4. Abrir el asistente
claude
```

Claude Code autentica con tu cuenta de Anthropic. Si es la primera vez:
```bash
claude auth login
```

### 2.2 Modo Docker lite (recomendado)

El target `lite` incluye todo el stack excepto Metasploit. Imagen final ~2-3 GB.

```bash
# 1. Clonar el repositorio
git clone https://github.com/Joscalion04/OffSec-Assistant.git
cd OffSec-Assistant

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env y completar:
#   ANTHROPIC_API_KEY=sk-ant-api03-TU_KEY_AQUI

# 3. Construir la imagen (una sola vez, o cuando cambies el Dockerfile)
docker compose build

# 4. Iniciar el asistente
docker compose run --rm assistant
```

El primer build descarga la imagen base de Kali y compila el stack completo.
Puede tomar 15-30 minutos segun la velocidad de conexion. Los builds siguientes
son rapidos gracias al cache de capas de Docker.

### 2.3 Modo Docker full (con Metasploit)

Agrega Metasploit Framework. Imagen final ~5 GB.

```bash
# Construir (primera vez o para actualizar)
docker compose -f docker-compose.yml -f docker-compose.full.yml build

# Ejecutar
docker compose -f docker-compose.yml -f docker-compose.full.yml run --rm assistant
```

Para no escribir el comando completo cada vez, se puede crear un alias:
```bash
alias offsec-full='docker compose -f docker-compose.yml -f docker-compose.full.yml run --rm assistant'
```

### 2.4 Modo Docker con VPN

El contenedor soporta OpenVPN y WireGuard. La VPN es opcional y se activa por
variable de entorno. Los archivos de configuracion se montan en `/vpn/` y jamas
se incluyen en la imagen ni en el repositorio.

#### OpenVPN

```bash
# Copiar el archivo de configuracion al directorio vpn/
cp /ruta/a/mi_engagement.ovpn docker/vpn/config.ovpn

# Iniciar con VPN activa
USE_VPN=true docker compose run --rm assistant
```

Si tu archivo `.ovpn` requiere credenciales interactivas, agregalas en un archivo
auxiliar y referencialas con `auth-user-pass` en el `.ovpn`.

#### WireGuard

```bash
cp /ruta/a/wg0.conf docker/vpn/wg0.conf
USE_VPN=true docker compose run --rm assistant
```

WireGuard requiere que el kernel del host tenga soporte (kernel >= 5.6 o modulo
`wireguard` cargado). Verificar en el host:
```bash
lsmod | grep wireguard
# o
modinfo wireguard
```

#### Verificar que la VPN esta activa (dentro del contenedor)

```bash
ip addr show tun0        # OpenVPN
ip addr show wg0         # WireGuard
curl -s https://ifconfig.me   # Ver IP publica de salida
```

#### Directorio vpn/ y seguridad

```
docker/vpn/
|-- .gitignore    <- ignora todo excepto .gitignore y .gitkeep
`-- .gitkeep      <- mantiene el directorio en git

# Los archivos .ovpn y .conf son ignorados por git automaticamente
# Verificar que no se van a commitear:
git status docker/vpn/
```

#### Persistencia de datos en Docker

Todos los datos del engagement persisten en el host via bind mounts:

```
Host                          Contenedor
----                          ----------
./findings/          <-->     /workspace/findings/
./reports/           <-->     /workspace/reports/
./logs/              <-->     /workspace/logs/
./templates/         <-->     /workspace/templates/   (read-only)
./tools/             <-->     /workspace/tools/        (read-only)
./docker/vpn/        <-->     /vpn/                    (read-only)

Volumen nombrado:
offsec-claude-config          /root/.claude   (config de Claude Code)
```

Los datos no se pierden al detener el contenedor. Para limpiar completamente:
```bash
docker compose down -v   # elimina tambien el volumen de Claude Code config
```

---

## 3. Primer uso

Al abrir el asistente por primera vez (modo nativo o Docker):

```
# Verificar herramientas disponibles
/check-tools

# El asistente mostrara una tabla como:
# Herramienta | Estado    | Instalacion
# nmap        | instalado | --
# masscan     | instalado | --
# nuclei      | FALTA     | yay -S nuclei
# ...
```

Si hay herramientas faltantes:
- **Modo nativo**: instalarlas en el host segun los comandos que muestra `/check-tools`
- **Modo Docker**: ya deberian estar todas incluidas en la imagen. Si falta alguna,
  reconstruir con `docker compose build --no-cache`

---

## 4. Flujo de engagement completo

### 4.1 Inicio de sesion

El primer comando de cada dia de trabajo:

```
/morning-brief
```

El asistente lee todos los engagements activos en `findings/` y genera un briefing:
- Cliente y deadline de cada engagement
- Fase actual y progreso
- Pendientes de la sesion anterior
- Alerta si algun deadline esta en menos de 3 dias
- Recomendacion de foco para hoy

Si no hay engagements activos, sugiere crear uno con `/new-engagement`.

### 4.2 Crear un engagement

```
/new-engagement acme-corp-2026
```

El asistente:
1. Crea `findings/2026-06-08_acme-corp-2026/` con toda la estructura
2. Copia las plantillas de scope, context y finding
3. Inicializa un repositorio git dentro del engagement
4. Muestra los proximos pasos

Convencion de nombres: usar guiones, sin espacios, sin acentos.
Ejemplos: `acme-corp-webapp`, `lab-htb-active`, `bugbounty-ejemplo-com`

### 4.3 Definir el scope

**Este paso es obligatorio antes de cualquier accion activa.**

El asistente no ejecutara herramientas contra un target que no este en `scope.md`.

```bash
# Editar el scope del engagement recien creado
# (el asistente muestra la ruta exacta despues de /new-engagement)
# Ejemplo: findings/2026-06-08_acme-corp-2026/scope.md
```

Campos clave a completar en `scope.md`:

```markdown
## Informacion del cliente
- Cliente: Acme Corporation
- Contacto tecnico: Juan Perez — juan@acme.com

## Targets autorizados
| IP / Dominio        | Descripcion      | Notas              |
|---------------------|------------------|--------------------|
| 192.168.10.0/24     | Red interna      | Excluir .1 (GW)    |
| webapp.acme.com     | App web principal| Solo HTTP/HTTPS     |
| 192.168.10.50       | Servidor Windows | Authorized for MSF |
```

### 4.4 Inicializar el mapa DLP

Una vez completado el scope, inicializar el sistema de proteccion de datos:

```bash
# Desde el directorio del proyecto
python3 tools/sanitizer.py findings/2026-06-08_acme-corp-2026 --init
```

Salida esperada:
```
[DLP] Mapa inicializado: 3 IPs, 1 hosts, 1 orgs
```

Esto registra en `findings/<engagement>/dlp-map.json` todos los IPs, hostnames
y nombre del cliente del scope.md. A partir de este momento, el agente recibe
`TGT-001` en lugar de `192.168.10.50` en todos los mensajes de herramientas.

El mapa DLP es local y nunca sale del entorno (gitignored, no se monta en la imagen).

### 4.5 Reconocimiento

#### Modo interactivo (recomendado para empezar)

El agente pregunta antes de cada fase y muestra resultados parciales:

```
/recon 192.168.10.50
```

Flujo tipico:
1. El asistente ejecuta WHOIS y DNS
2. Muestra resultados, pregunta si continuar con puertos
3. Ejecuta nmap top-1000
4. Muestra puertos abiertos, decide si ejecutar deteccion de servicios
5. Si hay web, ejecuta WhatWeb
6. Presenta resumen y sugiere `/vuln-scan`

#### Modo autonomo

Para dejar que el agente ejecute toda la fase sin interrupciones:

```
/recon 192.168.10.50 -auto
```

El agente:
1. Verifica que el target esta en `scope.md`
2. Informa la ruta del live feed
3. Ejecuta todas las fases en orden (pasivo → activo)
4. Toma decisiones basadas en resultados intermedios
5. Actualiza `context.md` al finalizar
6. Presenta resumen

Para seguir el progreso en tiempo real abrir otra terminal:
```bash
tail -f logs/livefeed/2026-06-08_acme-corp-2026_recon.log
```

Ver seccion [6. Live feed](#6-live-feed--seguir-ejecucion-autonoma) para detalles.

#### Archivos generados por recon

```
findings/2026-06-08_acme-corp-2026/recon/
|-- whois.txt          <- datos WHOIS completos (raw)
|-- dns.txt            <- registros A, MX, NS
|-- subdomains.txt     <- subdominios encontrados
|-- nmap_ports.txt     <- escaneo top-1000 puertos
|-- nmap_services.txt  <- deteccion de servicios y versiones
`-- whatweb.txt        <- tecnologias web detectadas
```

Estos archivos contienen datos raw del target. Para que el agente los analice
sin violar el control DLP, pasarlos por el sanitizador:

```bash
# Leer nmap sanitizado
python3 tools/sanitizer.py findings/2026-06-08_acme-corp-2026 \
    findings/2026-06-08_acme-corp-2026/recon/nmap_services.txt
```

### 4.6 Analisis de vulnerabilidades

```
/vuln-scan 192.168.10.50
/vuln-scan 192.168.10.50 -auto   # modo autonomo
```

Prerequisito recomendado: tener recon previo. Si no existe, el agente pregunta
si ejecutar `/recon` primero.

Herramientas que ejecuta:
- `nmap --script vuln` en puertos abiertos
- `searchsploit` correlacionando servicios y versiones encontrados
- `nikto` si hay web
- `nuclei -severity critical,high` si hay web

Hallazgos son pre-documentados automaticamente por el agente `doc-writer` en
`findings/<engagement>/vulns/FIND-NNN_<titulo>.md` con formato CVSS 3.1.

### 4.7 Explotacion

```
/exploit 192.168.10.50
/exploit 192.168.10.50 -auto   # analisis autonomo; la ejecucion SIEMPRE pide confirmacion
```

El flag `-auto` solo automatiza el analisis y preparacion del exploit, nunca su ejecucion.
El agente siempre presenta el comando exacto y espera confirmacion explicita:

```
[CONFIRMACION REQUERIDA]
Vector seleccionado: EternalBlue — MS17-010
Comando a ejecutar: msfconsole -q -x "use exploit/windows/smb/ms17_010_eternalblue; ..."
Impacto potencial: RCE como SYSTEM
Responde "si, ejecutar" para confirmar
```

Si el operador escribe cualquier otra cosa, la ejecucion se cancela.

### 4.8 Cierre de sesion

```
/session-close acme-corp-2026
```

El asistente:
1. Lee `context.md` y los logs del dia
2. Genera resumen de sesion (duracion, comandos, hallazgos)
3. Lista pendientes para la proxima sesion
4. Actualiza `context.md`
5. Hace commit en el git del engagement: `session: 2026-06-08 — X hallazgos documentados`

Si hay multiples engagements activos y no se especifica nombre, el asistente pregunta.

### 4.9 Generar reporte

```
/report acme-corp-2026
```

Lee todos los archivos del engagement y genera `reports/acme-corp-2026_report_2026-06-08.md`:

**Secciones del reporte:**
1. Executive Summary — lenguaje no tecnico para gerencia
2. Scope y metodologia
3. Hallazgos por severidad (Critical → Informational)
   - Descripcion del hallazgo
   - Evidencia (referencia a archivos, no contenido raw)
   - Impacto de negocio
   - Remediacion especifica con version/configuracion concreta
4. Conclusiones y recomendaciones generales

**Nota DLP sobre reportes**: el reporte usa tokens (TGT-001, HST-001). Antes de
entregar al cliente, el operador reemplaza los tokens con los valores reales usando
el `dlp-map.json` como referencia. Esto es intencional: mantiene el dato sensible
fuera del ciclo del agente hasta el momento de entrega.

---

## 5. Control DLP — uso avanzado

El sistema DLP tokeniza datos sensibles del target antes de que lleguen al agente
(y por ende a la API de Anthropic). Ver [README.md](README.md#caracteristicas) para
descripcion de la arquitectura.

### Consultar el mapa actual

```bash
cat findings/2026-06-08_acme-corp-2026/dlp-map.json
```

Salida ejemplo:
```json
{
  "version": 2,
  "targets": {
    "192.168.10.50": "TGT-001",
    "192.168.10.51": "TGT-002"
  },
  "hosts": {
    "webapp.acme.com": "HST-001"
  },
  "orgs": {
    "acme corporation": "ORG-001"
  },
  "emails": {
    "juan@acme.com": "MAIL-001"
  }
}
```

### Obtener el token de un valor especifico

```bash
echo "192.168.10.50" | python3 tools/sanitizer.py findings/2026-06-08_acme-corp-2026
# Output: TGT-001
```

### Registrar un hostname descubierto manualmente

```bash
# Si encontras un hostname durante una fase manual que no esta en scope.md
python3 tools/sanitizer.py findings/2026-06-08_acme-corp-2026 \
    --register-host internal.acme.com
# Output: HST-002
```

### Registrar una organizacion descubierta en WHOIS

```bash
python3 tools/sanitizer.py findings/2026-06-08_acme-corp-2026 \
    --register-org "Acme Holdings Ltd"
# Output: ORG-002
```

### Sanitizar un archivo de output manual

Si ejecutas una herramienta fuera del modo -auto, sanitizar el output antes
de pasarselo al agente:

```bash
# Ejecutar herramienta
nmap -sV -p 80,443,8080 192.168.10.50 > /tmp/scan.txt

# Sanitizar y mostrar (lo que el agente deberia ver)
python3 tools/sanitizer.py findings/2026-06-08_acme-corp-2026 /tmp/scan.txt

# Output sanitizado:
# PORT     STATE  SERVICE  VERSION
# 80/tcp   open   http     Apache httpd 2.4.49
# 443/tcp  open   https    Apache httpd 2.4.49
# Host: TGT-001 (TGT-001)
```

### Recuperar valores reales desde tokens (para entregar el reporte)

El operador hace la substitucion final de tokens en el reporte antes de entregarlo:

```bash
# Script simple de substitucion usando el mapa DLP
python3 - << 'EOF'
import json, re, sys

map_file = "findings/2026-06-08_acme-corp-2026/dlp-map.json"
report_file = "reports/acme-corp-2026_report_2026-06-08.md"

with open(map_file) as f:
    dlp = json.load(f)

with open(report_file) as f:
    content = f.read()

# Invertir el mapa: token -> valor_real
reverse = {}
for category in ("targets", "hosts", "orgs", "emails"):
    for real, token in dlp[category].items():
        reverse[token] = real

# Reemplazar tokens con valores reales
for token, real in sorted(reverse.items(), key=lambda x: len(x[0]), reverse=True):
    content = content.replace(token, real)

print(content)
EOF
```

---

## 6. Live feed — seguir ejecucion autonoma

Cuando se usa `-auto`, el agente escribe progreso en tiempo real a dos lugares:
1. La terminal donde esta corriendo (para el operador presente)
2. Un archivo de log en `logs/livefeed/` (para seguir desde otra terminal)

### Ver el livefeed en otra terminal

```bash
# Ver el log mas reciente
tail -f logs/livefeed/$(ls -t logs/livefeed/ | head -1)

# O con ruta explicita (el asistente siempre informa la ruta al iniciar -auto)
tail -f logs/livefeed/2026-06-08_acme-corp-2026_recon.log
```

### Leyenda de prefijos del livefeed

```
[PHASE]   inicio de una fase nueva
[PLAN]    plan de ejecucion antes de empezar
[START]   comando iniciado
[DONE]    comando completado sin errores
[FIND]    hallazgo menor o advertencia
[CRIT]    hallazgo critico — revisar inmediatamente
[THINK]   decision tomada por el agente con justificacion
[SKIP]    herramienta no disponible, paso omitido
[CONF]    requiere confirmacion del operador (solo en /exploit)
[SUM]     resumen final de la fase
```

### Ejemplo de livefeed tipico

```
[09:14:22] [PHASE] ==========================================
[09:14:22] [PHASE]  RECON AUTONOMO — Target: TGT-001
[09:14:22] [PLAN]  Plan de ejecucion (pasivo a activo):
[09:14:22] [PLAN]    1. WHOIS y DNS pasivo
[09:14:23] [START] WHOIS TGT-001
[09:14:25] [DONE]  WHOIS TGT-001 completado
[09:14:25] [THINK] Organizacion detectada: ORG-001
[09:14:26] [START] DNS registros A/MX/NS para TGT-001
[09:14:27] [THINK] TGT-001 resuelve a TGT-002 — usando para escaneos activos
[09:14:28] [START] Nmap top-1000 puertos en TGT-002
[09:17:03] [THINK] 5 puertos abiertos: 22,80,443,445,3389
[09:17:03] [THINK] HTTP/HTTPS detectado — ejecutando analisis web
[09:17:03] [THINK] SMB detectado — vector de alto interes
```

Notese que los datos sensibles aparecen como tokens (`TGT-001`, `ORG-001`).
Los datos reales estan en el `dlp-map.json` del engagement.

### Interrumpir una ejecucion autonoma

Para detener un `-auto` en progreso: `Ctrl+C` en la terminal del asistente.
El progreso hasta ese punto queda guardado en los archivos de findings y en el livefeed.

---

## 7. Modo conversacional

No todos los problemas requieren un comando. El asistente entiende lenguaje natural
y activa el agente `decision-advisor` cuando detecta que el operador necesita razonar,
no ejecutar.

### Cuando usar el modo conversacional

```
# Estas frases activan razonamiento guiado automaticamente:
"estoy trabado en X"
"que harias con Y"
"por donde sigo"
"no entiendo por que Z no funciona"
"tengo acceso a la maquina pero soy usuario de bajos privilegios"
```

### Comando /think para razonamiento explicito

```
/think encontre SMB abierto en un Windows Server 2019 pero EternalBlue no aplica
       porque esta parcheado. Tengo credenciales de un usuario de dominio.
```

El agente `decision-advisor` responde con:
1. Hechos confirmados del contexto
2. Suposiciones explicitas
3. Gaps de informacion
4. Perspectiva del atacante real
5. Vectores ordenados por probabilidad x impacto
6. Una sola recomendacion concreta

### Comando /explain para contexto tecnico

```
/explain CVE-2021-41773
/explain pass-the-hash
/explain Kerberoasting
/explain privilege escalation linux desde usuario www-data
```

El agente adapta la explicacion al contexto del engagement activo si existe.
Para CVEs incluye CVSS score, versiones afectadas y si hay exploit publico disponible.

---

## 8. Referencia de comandos

### Gestion de engagements

| Comando | Descripcion | Ejemplo |
|---------|-------------|---------|
| `/new-engagement <nombre>` | Crea estructura completa + git | `/new-engagement banco-xyz` |
| `/morning-brief` | Briefing diario de todos los engagements | `/morning-brief` |
| `/status [nombre]` | Estado actual del engagement | `/status banco` |
| `/session-close [nombre]` | Cierra sesion y hace commit | `/session-close banco-xyz` |

### Pentesting

| Comando | Descripcion | Ejemplo |
|---------|-------------|---------|
| `/recon <target> [-auto]` | Reconocimiento completo | `/recon 10.10.10.5 -auto` |
| `/vuln-scan <target> [-auto]` | Analisis de vulnerabilidades | `/vuln-scan webapp.com` |
| `/exploit <target> [-auto]` | Vectores y explotacion | `/exploit 10.10.10.5` |
| `/report <engagement>` | Reporte ejecutivo + tecnico | `/report banco-xyz` |

### Asistencia inteligente

| Comando | Descripcion | Ejemplo |
|---------|-------------|---------|
| `/think <situacion>` | Razonamiento guiado | `/think tengo shell como www-data` |
| `/explain <tema>` | Explicacion tecnica contextualizada | `/explain SSRF` |
| `/livefeed` | Ruta del live feed activo | `/livefeed` |

### Utilidades

| Comando | Descripcion |
|---------|-------------|
| `/check-tools` | Verifica herramientas instaladas; da comandos de instalacion para las que faltan |
| `/help` | Menu general de comandos |
| `/help <comando>` | Ayuda detallada de un comando especifico |

---

## 9. Tips y buenas practicas

### Flujo diario optimo

```
Inicio del dia:
  /morning-brief             <- ver estado de todos los engagements

Trabajo:
  /recon <target> -auto      <- en segundo plano si es largo
  /think <duda especifica>   <- cuando estes trabado
  /vuln-scan <target>        <- modo interactivo para revisar cada hallazgo

Fin del dia:
  /session-close             <- siempre cerrar antes de salir
```

### Scope y DLP — habitos criticos

1. **Nunca ejecutar** `/recon` ni `/vuln-scan` sin `scope.md` completo
2. **Siempre inicializar** el mapa DLP despues de completar el scope:
   ```bash
   python3 tools/sanitizer.py findings/<engagement_dir> --init
   ```
3. **Sanitizar archivos** antes de pasarselos al agente para analisis manual:
   ```bash
   python3 tools/sanitizer.py findings/<dir> <archivo>
   ```
4. Al redactar hallazgos manualmente, **usar los tokens** del mapa, no los valores reales

### Modo -auto vs interactivo

- Usar `-auto` cuando el target esta bien definido y queres resultados rapidos
- Usar interactivo cuando es un target nuevo y queres controlar el ritmo
- En entornos con IDS/IPS, el interactivo permite pausar entre fases para reducir ruido
- `/exploit -auto` sigue pidiendo confirmacion siempre — no hay forma de saltarse eso

### Multiple terminales

Para trabajo eficiente con modo `-auto`:

```
Terminal 1: asistente (claude)
Terminal 2: tail -f logs/livefeed/<ultimo_log>
Terminal 3: vim/nano para editar scope.md y context.md
```

### Naming de engagements

Convencion recomendada: `<cliente>-<tipo>-<año>` o `<plataforma>-<nombre>`

```
# Engagements de clientes
acme-corp-webapp-2026
banco-xyz-infra-2026

# Laboratorios y CTF
lab-htb-active
lab-thm-overpass
ctf-hackthebox-2026

# Bug bounty
bb-programa-ejemplo-com
```

Esto facilita el uso de `/status` y `/session-close` con nombre parcial:
```
/status acme        <- encuentra acme-corp-webapp-2026 automaticamente
/session-close banco <- encuentra banco-xyz-infra-2026
```

### Git en engagements

Cada engagement tiene su propio repositorio git. El asistente hace commits
automaticos en `/session-close`, pero se puede hacer commit manual en cualquier momento:

```bash
cd findings/2026-06-08_acme-corp-2026
git log --oneline   # ver historial de la sesion
git add .
git commit -m "recon: nmap completo, 5 puertos abiertos"
```

El `.gitignore` del engagement excluye pcaps, evidencias binarias, logs y el mapa DLP.

### Docker — rebuild selectivo

Si solo cambias archivos de comandos o CLAUDE.md, no hace falta rebuild:
```bash
# Solo cambia configuracion del agente — no necesita rebuild
docker compose run --rm assistant

# Cambias el Dockerfile o los scripts de herramientas — rebuild necesario
docker compose build --no-cache
```

---

## 10. Troubleshooting

### El agente no encuentra el engagement

```
Sintoma: /status no encuentra el engagement
Causa: el nombre parcial no coincide con ninguna carpeta en findings/

Solucion: usar el nombre completo o verificar con:
ls findings/
```

### scope.md no encontrado al ejecutar /recon

```
Sintoma: "Target no encontrado en scope.md — abortando"
Causa: el target no esta en la tabla de targets del scope.md del engagement activo

Solucion:
1. Verificar que scope.md tiene el target en la tabla "Targets autorizados"
2. Asegurar que el formato de la IP/dominio coincide exactamente
3. Si el engagement es nuevo, confirmar que /new-engagement se ejecuto correctamente
```

### El mapa DLP no se inicializa

```
Sintoma: python3 tools/sanitizer.py ... --init no genera el mapa
Causa: scope.md esta vacio o tiene solo el template sin completar

Solucion: completar scope.md con IPs/dominios reales en la tabla de targets
y volver a ejecutar --init
```

### Docker — la VPN no conecta

```
Sintoma: "VPN no pudo establecerse en 30s" en el arranque del contenedor
Causas comunes:
  - El archivo .ovpn requiere credenciales interactivas
  - El servidor VPN no es alcanzable desde el contenedor
  - Falta permiso NET_ADMIN (no deberia ocurrir con el docker-compose.yml incluido)

Verificar:
  docker compose run --rm assistant bash
  cat /workspace/logs/openvpn.log   # dentro del contenedor
```

### Claude Code no reconoce los slash commands

```
Sintoma: /recon o /vuln-scan no ejecutan nada o dan error
Causa: Claude Code no esta leyendo el directorio .claude/commands/

Solucion:
1. Verificar que estas en el directorio raiz del proyecto cuando abres claude
2. En modo Docker, verificar que el volumen de .claude esta montado correctamente
3. Reiniciar Claude Code desde el directorio correcto:
   cd /path/to/OffSec-Assistant && claude
```

### Herramientas no disponibles en Docker

```
Sintoma: [SKIP] nmap no instalado dentro del contenedor
Causa: el build de Docker no completo correctamente

Solucion:
  docker compose build --no-cache
  # Si persiste, verificar la salida del build para errores de apt
```

### Permisos en los directorios de findings/

```
Sintoma: "Permission denied" al crear archivos dentro del contenedor
Causa: los directorios de findings/ en el host no tienen los permisos correctos

Solucion (en el host):
  chmod 755 findings/ reports/ logs/
  # O si el contenedor corre como root:
  sudo chown -R $USER:$USER findings/ reports/ logs/
```

---

*Para contribuir al proyecto ver [CONTRIBUTING.md](CONTRIBUTING.md).*
*Para reportar bugs o sugerir features ver las [Issues](https://github.com/Joscalion04/OffSec-Assistant/issues).*
