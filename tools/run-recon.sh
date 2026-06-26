#!/bin/bash
# OffSec Assistant — Reconocimiento autonomo
# Uso: run-recon.sh <engagement> <target>
# Env:  SCAN_PROFILE=silent|standard|aggressive (default: standard)

ENGAGEMENT="$1"
TARGET="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFSEC_HOME="${OFFSEC_HOME:-$(dirname "$SCRIPT_DIR")}"

# Cargar motor de ejecucion (inicializa DLP, lib.sh, define log/run_cmd/sanitize_log)
source "$OFFSEC_HOME/tools/auto-runner.sh" "$ENGAGEMENT" "recon" "$TARGET"

# Cargar perfil de scan
source "$OFFSEC_HOME/tools/scan-profiles.sh"

RECON_DIR="$ENGAGEMENT_DIR/recon"
mkdir -p "$RECON_DIR"

# DLP: obtener el token del target para usar en mensajes al agente
# TARGET_TOKEN es lo que el agente ve; TARGET es lo que las herramientas usan
TARGET_TOKEN=$(sanitize_log "$TARGET")

log "PHASE" "=========================================="
log "PHASE" " RECON AUTONOMO — Target: $TARGET_TOKEN"
log "PHASE" " Perfil: $SCAN_PROFILE"
log "PHASE" "=========================================="

# ----- PLAN -----
log "PLAN" "Plan de ejecucion (pasivo a semi-activo a activo):"
log "PLAN" "  1. WHOIS y DNS pasivo"
log "PLAN" "  2. Resolucion y registros DNS"
log "PLAN" "  3. Subdominios (pasivo)"
log "PLAN" "  4. Nmap — top 1000 puertos (SYN scan)"
log "PLAN" "  5. Nmap — deteccion de servicios y versiones"
log "PLAN" "  6. Deteccion de tecnologias web (si hay HTTP/HTTPS)"
log "PLAN" "  7. Busqueda de CVEs en servicios encontrados"

# ----- FASE 1: PASIVO -----
log "PHASE" "--- FASE 1: Reconocimiento pasivo ---"

if command -v whois &>/dev/null; then
    run_cmd "WHOIS $TARGET_TOKEN" "whois $TARGET" "$RECON_DIR/whois.txt"

    # DLP: extraer org pero sanitizar antes de logear
    WHOIS_ORG_RAW=$(grep -i "OrgName\|org-name\|registrant" "$RECON_DIR/whois.txt" 2>/dev/null | head -3)
    if [ -n "$WHOIS_ORG_RAW" ]; then
        # Registrar la org en el mapa DLP para tokenizarla en futuros mensajes
        ORG_LINE=$(echo "$WHOIS_ORG_RAW" | awk -F: '{print $2}' | head -1 | tr -d ' ')
        if [ -n "$ORG_LINE" ]; then
            python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" --register-org "$ORG_LINE" 2>/dev/null
        fi
        WHOIS_ORG_SAFE=$(sanitize_log "$WHOIS_ORG_RAW")
        log "THINK" "Organizacion detectada: $WHOIS_ORG_SAFE"
    fi
else
    log "SKIP" "whois no instalado — omitiendo"
fi

# DLP: guardar output DNS completo en archivo (raw) pero sanitizar el mensaje de log
run_cmd "DNS registros A/MX/NS para $TARGET_TOKEN" \
    "dig +noall +answer $TARGET A && dig +noall +answer $TARGET MX && dig +noall +answer $TARGET NS" \
    "$RECON_DIR/dns.txt"

RESOLVED_IP=$(dig +short "$TARGET" A 2>/dev/null | head -1)
if [ -n "$RESOLVED_IP" ]; then
    # Registrar la IP resuelta en el mapa DLP
    RESOLVED_TOKEN=$(sanitize_log "$RESOLVED_IP")
    log "THINK" "$TARGET_TOKEN resuelve a $RESOLVED_TOKEN — usando para escaneos activos"
    SCAN_TARGET="$RESOLVED_IP"
else
    log "THINK" "No se resolvio DNS — usando target original para escaneos"
    SCAN_TARGET="$TARGET"
fi
SCAN_TOKEN=$(sanitize_log "$SCAN_TARGET")

if command -v subfinder &>/dev/null; then
    run_cmd "Subdominios con subfinder para $TARGET_TOKEN" \
        "subfinder -d $TARGET -silent" \
        "$RECON_DIR/subdomains.txt"

    SUB_COUNT=$(wc -l < "$RECON_DIR/subdomains.txt" 2>/dev/null || echo 0)
    # Registrar subdominios descubiertos en el mapa DLP
    if [ "$SUB_COUNT" -gt 0 ]; then
        while IFS= read -r subdomain; do
            [ -n "$subdomain" ] && python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" \
                --register-host "$subdomain" 2>/dev/null
        done < "$RECON_DIR/subdomains.txt"
    fi
    log "THINK" "Subdominios encontrados: $SUB_COUNT — revisar para ampliar superficie"
elif command -v amass &>/dev/null; then
    run_cmd "Subdominios con amass (pasivo)" \
        "amass enum -passive -d $TARGET" \
        "$RECON_DIR/subdomains.txt"
else
    log "SKIP" "subfinder/amass no instalados — omitiendo subdominios"
fi

# ----- FASE 2: ESCANEO DE PUERTOS -----
log "PHASE" "--- FASE 2: Escaneo de puertos ---"

HAS_WEB=false
HAS_SSH=false
HAS_SMB=false
HAS_FTP=false

if check_tool nmap; then
    if $NMAP_FULL_PORTS; then
        NMAP_PORT_ARGS="-p-"
    else
        NMAP_PORT_ARGS="--top-ports $NMAP_TOP_PORTS"
    fi
    run_cmd "Nmap ${NMAP_PORT_ARGS} en $SCAN_TOKEN [perfil: $SCAN_PROFILE]" \
        "nmap $NMAP_TIMING $NMAP_PORT_ARGS $NMAP_EXTRA_FLAGS -oN $RECON_DIR/nmap_ports.txt $SCAN_TARGET" \
        "$RECON_DIR/nmap_ports.txt"

    OPEN_PORTS=$(grep "^[0-9]" "$RECON_DIR/nmap_ports.txt" 2>/dev/null \
        | grep "open" | awk -F'/' '{print $1}' | sort -u | tr '\n' ',' | sed 's/,$//')

    if [ -n "$OPEN_PORTS" ]; then
        PORT_COUNT=$(echo "$OPEN_PORTS" | tr ',' '\n' | wc -l)
        # Los numeros de puerto no son sensibles — se pueden logear directamente
        log "THINK" "$PORT_COUNT puertos abiertos: $OPEN_PORTS"
        log "THINK" "Ejecutando deteccion de versiones en puertos abiertos"

        run_cmd "Nmap servicios y versiones en $SCAN_TOKEN" \
            "nmap -sV -sC -p $OPEN_PORTS -oN $RECON_DIR/nmap_services.txt $SCAN_TARGET" \
            "$RECON_DIR/nmap_services.txt"

        grep -q "80/open\|443/open\|8080/open\|8443/open" "$RECON_DIR/nmap_ports.txt" && HAS_WEB=true
        grep -q "22/open" "$RECON_DIR/nmap_ports.txt" && HAS_SSH=true
        grep -q "445/open\|139/open" "$RECON_DIR/nmap_ports.txt" && HAS_SMB=true
        grep -q "21/open" "$RECON_DIR/nmap_ports.txt" && HAS_FTP=true

        $HAS_WEB && log "THINK" "HTTP/HTTPS detectado — ejecutando analisis web"
        $HAS_SSH && log "THINK" "SSH detectado — verificar version para CVEs"
        $HAS_SMB && log "THINK" "SMB detectado — vector de alto interes"
        $HAS_FTP && log "THINK" "FTP detectado — verificar acceso anonimo"
    else
        log "FIND" "No se encontraron puertos abiertos en top-1000"
        log "THINK" "Considerar escaneo completo: nmap -p- $SCAN_TOKEN"
    fi
else
    warn "nmap no instalado — escaneo de puertos omitido"
    log "SKIP" "nmap no instalado — escaneo de puertos omitido"
fi

# ----- FASE 3: WEB (si aplica) -----
if $HAS_WEB; then
    log "PHASE" "--- FASE 3: Analisis web ---"

    PROTO="http"
    grep -q "443/open\|8443/open" "$RECON_DIR/nmap_ports.txt" && PROTO="https"
    WEB_URL="${PROTO}://${SCAN_TARGET}"
    WEB_URL_SAFE="${PROTO}://${SCAN_TOKEN}"

    if command -v whatweb &>/dev/null; then
        run_cmd "Deteccion de tecnologias web en $WEB_URL_SAFE" \
            "whatweb -a 3 $WEB_URL" \
            "$RECON_DIR/whatweb.txt"

        # DLP: sanitizar output de whatweb antes de logear (puede contener headers con IPs)
        TECHS_RAW=$(head -3 "$RECON_DIR/whatweb.txt" 2>/dev/null)
        TECHS_SAFE=$(sanitize_log "$TECHS_RAW")
        log "THINK" "Tecnologias: $TECHS_SAFE"
    fi
fi

# ----- RESUMEN FINAL -----
log "PHASE" "=========================================="
log "SUMMARY" "RECON COMPLETADO — $TARGET_TOKEN"
log "SUMMARY" "Archivos generados en: $RECON_DIR"
log "SUMMARY" "Puertos abiertos: ${OPEN_PORTS:-ninguno}"
$HAS_WEB && log "SUMMARY" "Web detectada — ejecutar: /vuln-scan $TARGET_TOKEN -auto"
$HAS_SMB && log "SUMMARY" "SMB detectado — vector prioritario para enumeracion"
$HAS_SSH && log "SUMMARY" "SSH detectado — verificar version y credenciales debiles"
$HAS_FTP && log "SUMMARY" "FTP detectado — verificar acceso anonimo"
log "SUMMARY" "Live feed guardado en: $LIVEFEED_FILE"
log "PHASE" "=========================================="
