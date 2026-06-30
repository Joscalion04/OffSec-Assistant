# OffSec Assistant — Referencia del CLI

El CLI `offsec` gestiona el ciclo de vida del contenedor y los engagements
directamente desde el host, sin necesidad de entrar al contenedor.

---

## Instalación

```bash
./install.sh
```

El instalador:
- Verifica dependencias (Docker, Git, Python 3)
- Crea un symlink en `~/.local/bin/offsec`
- Guarda `OFFSEC_HOME` en `~/.config/offsec/env`
- Copia `.env.example` → `.env` si no existe

**Desinstalar:**

```bash
./install.sh --uninstall
```

---

## Primeros pasos

```bash
# 1. Configurar API key
vim .env  # editar ANTHROPIC_API_KEY

# 2. Levantar el contenedor
offsec start

# 3. Conectarse
offsec in

# Dentro del assistant: iniciar un engagement
# /new-engagement cliente-2024

# 4. Salir de la sesión (el contenedor sigue vivo)
# exit / Ctrl+D

# 5. Ver engagements desde el host
offsec list

# 6. Apagar al final del día
offsec down
```

---

## Referencia de comandos

### Ciclo de vida del contenedor

#### `offsec start [--vpn]`

Levanta el contenedor en background (modo daemon).

```bash
offsec start          # sin VPN
offsec start --vpn    # con OpenVPN o WireGuard
```

Requiere `.env` con `ANTHROPIC_API_KEY` configurado.
Con `--vpn` requiere `docker/vpn/config.ovpn` (OpenVPN) o `docker/vpn/wg0.conf` (WireGuard).

---

#### `offsec down`

Detiene el contenedor limpiamente.

```bash
offsec down
```

Alias: `offsec stop`

---

#### `offsec restart`

Reinicia el contenedor sin perder datos.

```bash
offsec restart
```

---

#### `offsec in`

Abre una sesión interactiva de Claude Code dentro del contenedor.
`exit` o `Ctrl+D` cierra la sesión — el contenedor **no** se detiene.

```bash
offsec in
```

Las variables configuradas con `offsec config set` se inyectan automáticamente en la sesión.

---

#### `offsec status`

Muestra el estado del contenedor y un resumen de engagements activos.

```bash
offsec status
```

Salida incluye: estado del contenedor, imagen, health, lista de engagements con última actividad.

---

#### `offsec logs [-f]`

Muestra los logs del contenedor. Acepta todos los flags de `docker compose logs`.

```bash
offsec logs           # logs históricos
offsec logs -f        # seguimiento en tiempo real
offsec logs --tail=50 # últimas 50 líneas
```

---

#### `offsec build [lite|full]`

Reconstruye la imagen Docker localmente.

```bash
offsec build          # imagen lite (default)
offsec build full     # imagen con Metasploit
```

---

### Engagement shortcuts

#### `offsec list`

Lista todos los engagements con número de findings y última actividad.
No requiere que el contenedor esté corriendo.

```bash
offsec list
```

---

#### `offsec new <nombre>`

Inicializa un nuevo engagement dentro del assistant (ejecuta `/new-engagement`).

```bash
offsec new cliente-2024
offsec new htb-machine-name
```

Requiere contenedor corriendo.

---

#### `offsec brief`

Ejecuta el morning brief dentro del assistant (ejecuta `/morning-brief`).

```bash
offsec brief
```

Requiere contenedor corriendo.

---

#### `offsec report <nombre>`

Genera el reporte final del engagement (ejecuta `/report`).

```bash
offsec report cliente-2024
```

Acepta nombre parcial del engagement. Requiere contenedor corriendo.

---

#### `offsec scope <nombre>`

Abre el `scope.md` del engagement en el editor configurado.
No requiere contenedor corriendo.

```bash
offsec scope cliente-2024
```

Usa `$EDITOR` o `$VISUAL`. Configurable con `offsec config set EDITOR code`.

---

### Mantenimiento

#### `offsec update [--check]`

Actualiza el assistant a la última versión desde `origin/main`.

```bash
offsec update           # aplica la actualización
offsec update --check   # verifica sin aplicar
```

Flujo:
1. `git fetch origin main`
2. Muestra commits nuevos
3. `git pull origin main`
4. Si el `Dockerfile` cambió → rebuild automático
5. Si el contenedor estaba corriendo → restart automático
6. Muestra diff del CHANGELOG

Los datos en `findings/`, `logs/` y `reports/` nunca son tocados.

---

#### `offsec config <subcomando>`

Gestiona la configuración persistente del CLI.

```bash
offsec config list                         # muestra configuración activa
offsec config set EDITOR code              # guarda una clave
offsec config set SCAN_PROFILE aggressive
offsec config get EDITOR                   # lee una clave
offsec config reset                        # limpia toda la configuración
```

La configuración se guarda en `~/.config/offsec/config` y se inyecta en
cada sesión de `offsec in`.

**Claves disponibles:**

| Clave | Descripción | Default |
|-------|-------------|---------|
| `EDITOR` | Editor de texto para scope/findings | `vim` |
| `REPORT_LANG` | Idioma de reportes | `es` |
| `BURP_TIMEOUT` | Timeout de Burp API (segundos) | `120` |
| `SCAN_PROFILE` | Perfil de escaneo: `silent`, `standard`, `aggressive` | `standard` |

---

## Troubleshooting

### Docker no corre

```
[offsec][ERROR] El daemon de Docker no está corriendo.
```

**Solución:**

```bash
sudo systemctl start docker
# Para que arranque automáticamente:
sudo systemctl enable docker
```

### PATH no configurado

```
zsh: command not found: offsec
```

**Solución:**

```bash
source ~/.zshrc   # o ~/.bashrc según tu shell
# Verificar:
which offsec
```

### Contenedor no responde

```bash
offsec logs -f          # revisar logs en tiempo real
offsec restart          # reiniciar
offsec down && offsec start  # ciclo completo
```

### OFFSEC_HOME no configurado

```
[offsec][ERROR] OFFSEC_HOME no configurado.
```

**Solución:**

```bash
./install.sh            # reinstalar
# o manualmente:
export OFFSEC_HOME=/ruta/al/proyecto
```

---

## Flujo de engagement completo

```bash
# Inicio del día
offsec start
offsec brief

# Nuevo engagement
offsec new cliente-abc

# Trabajar desde la sesión del assistant
offsec in
# /recon TGT-001
# /vuln-scan TGT-001
# exit

# Ver progreso desde el host
offsec list
offsec status

# Generar reporte
offsec report cliente-abc

# Fin del día
offsec down
```
