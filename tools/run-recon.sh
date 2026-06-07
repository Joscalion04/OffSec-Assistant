#!/bin/bash
# OffSec Assistant — Reconocimiento autónomo
# Uso: run-recon.sh <engagement> <target>

ENGAGEMENT="$1"
TARGET="$2"
OFFSEC_HOME="/home/joseph/Documents/OffSec/OffSec-Assistant"

source "$OFFSEC_HOME/tools/auto-runner.sh" "$ENGAGEMENT" "recon" "$TARGET"

RECON_DIR="$ENGAGEMENT_DIR/recon"
mkdir -p "$RECON_DIR"

log "PHASE" "=========================================="
log "PHASE" " RECON AUTÓNOMO — Target: $TARGET"
log "PHASE" "=========================================="

# ----- PLAN -----
log "PLAN" "Plan de ejecución (pasivo → semi-activo → activo):"
log "PLAN" "  1. WHOIS y DNS pasivo"
log "PLAN" "  2. Resolución y registros DNS"
log "PLAN" "  3. Subdominios (pasivo)"
log "PLAN" "  4. Nmap — top 1000 puertos (SYN scan)"
log "PLAN" "  5. Nmap — detección de servicios y versiones"
log "PLAN" "  6. Detección de tecnologías web (si hay HTTP/HTTPS)"
log "PLAN" "  7. Búsqueda de CVEs en servicios encontrados"

# ----- FASE 1: PASIVO -----
log "PHASE" "--- FASE 1: Reconocimiento pasivo ---"

if command -v whois &>/dev/null; then
    run_cmd "WHOIS $TARGET" "whois $TARGET" "$RECON_DIR/whois.txt"
    WHOIS_ORG=$(grep -i "OrgName\|org-name\|registrant" "$RECON_DIR/whois.txt" 2>/dev/null | head -3)
    [ -n "$WHOIS_ORG" ] && log "THINK" "Organización detectada: $WHOIS_ORG"
else
    log "SKIP" "whois no instalado — omitiendo"
fi

run_cmd "DNS registros A/MX/NS" \
    "dig +noall +answer $TARGET A && dig +noall +answer $TARGET MX && dig +noall +answer $TARGET NS" \
    "$RECON_DIR/dns.txt"

RESOLVED_IP=$(dig +short $TARGET A 2>/dev/null | head -1)
if [ -n "$RESOLVED_IP" ]; then
    log "THINK" "$TARGET resuelve a $RESOLVED_IP — usando IP para escaneos activos"
    SCAN_TARGET="$RESOLVED_IP"
else
    log "THINK" "No se resolvió DNS — usando target original para escaneos"
    SCAN_TARGET="$TARGET"
fi

if command -v subfinder &>/dev/null; then
    run_cmd "Subdominios con subfinder" \
        "subfinder -d $TARGET -silent" \
        "$RECON_DIR/subdomains.txt"
    SUB_COUNT=$(wc -l < "$RECON_DIR/subdomains.txt" 2>/dev/null || echo 0)
    log "THINK" "Subdominios encontrados: $SUB_COUNT — revisar para ampliar superficie"
elif command -v amass &>/dev/null; then
    run_cmd "Subdominios con amass (pasivo)" \
        "amass enum -passive -d $TARGET" \
        "$RECON_DIR/subdomains.txt"
else
    log "SKIP" "subfinder/amass no instalados — omitiendo subdominios"
fi

# ----- FASE 2: SEMI-ACTIVO -----
log "PHASE" "--- FASE 2: Escaneo de puertos ---"

if command -v nmap &>/dev/null; then
    run_cmd "Nmap top-1000 puertos" \
        "nmap -T4 --top-ports 1000 -oN $RECON_DIR/nmap_ports.txt $SCAN_TARGET" \
        "$RECON_DIR/nmap_ports.txt"

    OPEN_PORTS=$(grep "^[0-9]" "$RECON_DIR/nmap_ports.txt" 2>/dev/null | grep "open" | awk -F'/' '{print $1}' | sort -u | tr '\n' ',' | sed 's/,$//')

    if [ -n "$OPEN_PORTS" ]; then
        PORT_COUNT=$(echo "$OPEN_PORTS" | tr ',' '\n' | wc -l)
        log "THINK" "$PORT_COUNT puertos abiertos: $OPEN_PORTS"
        log "THINK" "Ejecutando detección de versiones en puertos abiertos únicamente"

        run_cmd "Nmap detección de servicios y versiones" \
            "nmap -sV -sC -p $OPEN_PORTS -oN $RECON_DIR/nmap_services.txt $SCAN_TARGET" \
            "$RECON_DIR/nmap_services.txt"

        # Analizar servicios encontrados
        HAS_WEB=false
        HAS_SSH=false
        HAS_SMB=false
        HAS_FTP=false

        grep -q "80/open\|443/open\|8080/open\|8443/open" "$RECON_DIR/nmap_ports.txt" && HAS_WEB=true
        grep -q "22/open" "$RECON_DIR/nmap_ports.txt" && HAS_SSH=true
        grep -q "445/open\|139/open" "$RECON_DIR/nmap_ports.txt" && HAS_SMB=true
        grep -q "21/open" "$RECON_DIR/nmap_ports.txt" && HAS_FTP=true

        $HAS_WEB && log "THINK" "HTTP/HTTPS detectado — ejecutando análisis web"
        $HAS_SSH && log "THINK" "SSH detectado — verificar versión para CVEs"
        $HAS_SMB && log "THINK" "SMB detectado — vector de alto interés"
        $HAS_FTP && log "THINK" "FTP detectado — verificar acceso anónimo"
    else
        log "FIND" "No se encontraron puertos abiertos en top-1000"
        log "THINK" "Considerar escaneo completo con: nmap -p- $SCAN_TARGET"
    fi
else
    log "SKIP" "nmap no instalado — escaneo de puertos omitido"
fi

# ----- FASE 3: WEB (si aplica) -----
if $HAS_WEB; then
    log "PHASE" "--- FASE 3: Análisis web ---"

    WEB_PORT=$(grep -oP "[0-9]+(?=/open.*http)" "$RECON_DIR/nmap_ports.txt" 2>/dev/null | head -1)
    PROTO="http"
    grep -q "443/open\|8443/open" "$RECON_DIR/nmap_ports.txt" && PROTO="https"
    WEB_URL="${PROTO}://${SCAN_TARGET}"

    if command -v whatweb &>/dev/null; then
        run_cmd "Detección de tecnologías web" \
            "whatweb -a 3 $WEB_URL" \
            "$RECON_DIR/whatweb.txt"
        TECHS=$(cat "$RECON_DIR/whatweb.txt" 2>/dev/null | head -3)
        log "THINK" "Tecnologías: $TECHS"
    fi
fi

# ----- RESUMEN FINAL -----
log "PHASE" "=========================================="
log "SUMMARY" "RECON COMPLETADO — $TARGET"
log "SUMMARY" "Archivos generados en: $RECON_DIR"
log "SUMMARY" "Puertos abiertos: ${OPEN_PORTS:-ninguno}"
$HAS_WEB  && log "SUMMARY" "▶ Web detectada — ejecutar: /vuln-scan $TARGET -auto"
$HAS_SMB  && log "SUMMARY" "▶ SMB detectado — vector prioritario para enumeración"
$HAS_SSH  && log "SUMMARY" "▶ SSH detectado — verificar versión y credenciales débiles"
$HAS_FTP  && log "SUMMARY" "▶ FTP detectado — verificar acceso anónimo"
log "SUMMARY" "Live feed guardado en: $LIVEFEED_FILE"
log "PHASE" "=========================================="
