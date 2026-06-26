#!/bin/bash
# OffSec Assistant — Vulnerability scan autonomo
# Uso: run-vuln-scan.sh <engagement> <target>
# Env:  SCAN_PROFILE=silent|standard|aggressive (default: standard)

ENGAGEMENT="$1"
TARGET="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFSEC_HOME="${OFFSEC_HOME:-$(dirname "$SCRIPT_DIR")}"

# Cargar motor de ejecucion (inicializa DLP, lib.sh, define log/run_cmd/sanitize_log)
source "$OFFSEC_HOME/tools/auto-runner.sh" "$ENGAGEMENT" "vulnscan" "$TARGET"

# Cargar perfil de scan
source "$OFFSEC_HOME/tools/scan-profiles.sh"

VULN_DIR="$ENGAGEMENT_DIR/vulns"
RECON_DIR="$ENGAGEMENT_DIR/recon"
mkdir -p "$VULN_DIR"

# DLP: token del target para mensajes al agente
TARGET_TOKEN=$(sanitize_log "$TARGET")

log "PHASE" "=========================================="
log "PHASE" " VULN-SCAN AUTONOMO — Target: $TARGET_TOKEN"
log "PHASE" " Perfil: $SCAN_PROFILE"
log "PHASE" "=========================================="

# Leer resultados de recon previo
if [ -f "$RECON_DIR/nmap_ports.txt" ]; then
    log "THINK" "Leyendo resultados de recon previo..."
    OPEN_PORTS=$(grep "^[0-9]" "$RECON_DIR/nmap_ports.txt" \
        | grep "open" | awk -F'/' '{print $1}' | sort -u | tr '\n' ',' | sed 's/,$//')
    # Puertos no son sensibles
    log "THINK" "Puertos conocidos del recon: $OPEN_PORTS"
    HAS_WEB=false
    grep -q "80/tcp.*open\|443/tcp.*open\|8080/tcp.*open" "$RECON_DIR/nmap_ports.txt" \
        && HAS_WEB=true
else
    log "THINK" "Sin recon previo — ejecutando escaneo basico"
    nmap -T4 --top-ports 100 -oN "$VULN_DIR/quick_ports.txt" "$TARGET" &>/dev/null
    OPEN_PORTS=$(grep "open" "$VULN_DIR/quick_ports.txt" \
        | awk -F'/' '{print $1}' | sort -u | tr '\n' ',' | sed 's/,$//')
    HAS_WEB=false
    grep -q "80/tcp.*open\|443/tcp.*open\|8080/tcp.*open" "$VULN_DIR/quick_ports.txt" \
        && HAS_WEB=true
fi

log "PLAN" "Plan de analisis:"
log "PLAN" "  1. Nmap scripts de vulnerabilidades"
log "PLAN" "  2. Searchsploit en servicios detectados"
$HAS_WEB && log "PLAN" "  3. Nikto — analisis HTTP"
$HAS_WEB && log "PLAN" "  4. Nuclei — templates critical/high"

# ----- Nmap vuln scripts -----
log "PHASE" "--- Nmap vulnerability scripts ---"
if [ -n "$OPEN_PORTS" ]; then
    run_cmd "Nmap --script vuln en $TARGET_TOKEN" \
        "nmap --script vuln -p $OPEN_PORTS -oN $VULN_DIR/nmap_vuln.txt $TARGET" \
        "$VULN_DIR/nmap_vuln.txt"

    VULNS_FOUND=$(grep -c "VULNERABLE\|CVE" "$VULN_DIR/nmap_vuln.txt" 2>/dev/null || echo 0)
    if [ "$VULNS_FOUND" -gt 0 ]; then
        log "CRITICAL" "$VULNS_FOUND referencias de vulnerabilidades en nmap scripts"
        # DLP: sanitizar cada linea antes de logearla (puede contener IPs en el output)
        grep "VULNERABLE\|CVE" "$VULN_DIR/nmap_vuln.txt" | while IFS= read -r vuln_line; do
            log "FIND" "$(sanitize_log "$vuln_line")"
        done
    else
        log "DONE" "Nmap vuln scripts — sin hallazgos criticos inmediatos"
    fi
fi

# ----- Searchsploit -----
log "PHASE" "--- Correlacion con ExploitDB ---"
if command -v searchsploit &>/dev/null; then
    if [ -f "$RECON_DIR/nmap_services.txt" ]; then
        # DLP: sanitizar el archivo de servicios antes de que el agente vea resultados
        # Las versiones de servicio (Apache 2.4.49) no son sensibles — son publicas
        grep -oP "(?<=\s)[A-Za-z\-]+\s[0-9]+\.[0-9]+" "$RECON_DIR/nmap_services.txt" \
            | sort -u | while IFS= read -r SERVICE; do
            log "START" "Buscando exploits para: $SERVICE"
            RESULTS=$(searchsploit "$SERVICE" --disable-colour 2>/dev/null \
                | grep -v "^--\|^Exploit Title" | head -5)
            if [ -n "$RESULTS" ]; then
                log "FIND" "Exploits disponibles para $SERVICE:"
                # Las rutas de ExploitDB no son sensibles — se pueden logear directamente
                echo "$RESULTS" | while IFS= read -r exploit_line; do
                    log "FIND" "  $exploit_line"
                done
            fi
        done
        searchsploit --nmap "$RECON_DIR/nmap_services.txt" > "$VULN_DIR/searchsploit.txt" 2>&1
        log "DONE" "Correlacion guardada en: $VULN_DIR/searchsploit.txt"
    fi
else
    log "SKIP" "searchsploit no instalado — omitiendo correlacion ExploitDB"
fi

# ----- Web: Nikto + Nuclei -----
NIKTO_FINDINGS=0
NUCLEI_COUNT=0

if $HAS_WEB; then
    log "PHASE" "--- Analisis web ---"

    PROTO="http"
    grep -q "443/open" "$RECON_DIR/nmap_ports.txt" 2>/dev/null && PROTO="https"
    WEB_URL="${PROTO}://${TARGET}"
    WEB_URL_SAFE="${PROTO}://${TARGET_TOKEN}"

    if check_tool nikto; then
        run_cmd "Nikto web scan en $WEB_URL_SAFE [perfil: $SCAN_PROFILE]" \
            "nikto -h $WEB_URL $NIKTO_OPTS -o $VULN_DIR/nikto.txt -Format txt" \
            "$VULN_DIR/nikto_live.txt"

        NIKTO_FINDINGS=$(grep -c "^\+" "$VULN_DIR/nikto.txt" 2>/dev/null || echo 0)
        log "THINK" "Nikto encontro $NIKTO_FINDINGS items — revisar $VULN_DIR/nikto.txt"
    else
        log "SKIP" "nikto no instalado"
    fi

    if check_tool nuclei; then
        run_cmd "Nuclei ${NUCLEI_SEVERITY} en $WEB_URL_SAFE [perfil: $SCAN_PROFILE]" \
            "nuclei -u $WEB_URL -severity $NUCLEI_SEVERITY -o $VULN_DIR/nuclei.txt -silent" \
            "$VULN_DIR/nuclei_live.txt"

        NUCLEI_COUNT=$(wc -l < "$VULN_DIR/nuclei.txt" 2>/dev/null || echo 0)
        if [ "$NUCLEI_COUNT" -gt 0 ]; then
            log "CRITICAL" "Nuclei encontro $NUCLEI_COUNT hallazgos critical/high"
            # DLP: sanitizar output de nuclei (puede contener URLs con paths internos)
            while IFS= read -r nuclei_line; do
                log "FIND" "$(sanitize_log "$nuclei_line")"
            done < "$VULN_DIR/nuclei.txt"
        else
            log "DONE" "Nuclei — sin hallazgos critical/high"
        fi
    else
        log "SKIP" "nuclei no instalado"
    fi
fi

# ----- RESUMEN -----
log "PHASE" "=========================================="
log "SUMMARY" "VULN-SCAN COMPLETADO — $TARGET_TOKEN"
log "SUMMARY" "Archivos en: $VULN_DIR"
[ -f "$VULN_DIR/nmap_vuln.txt" ]    && log "SUMMARY" "nmap_vuln.txt — revisar VULNERABLE entries"
[ -f "$VULN_DIR/searchsploit.txt" ] && log "SUMMARY" "searchsploit.txt — exploits disponibles"
[ -f "$VULN_DIR/nikto.txt" ]        && log "SUMMARY" "nikto.txt — $NIKTO_FINDINGS hallazgos web"
[ -f "$VULN_DIR/nuclei.txt" ]       && log "SUMMARY" "nuclei.txt — $NUCLEI_COUNT hallazgos criticos"
log "SUMMARY" "Siguiente: /report $ENGAGEMENT o revisar hallazgos manualmente"
log "SUMMARY" "Live feed: $LIVEFEED_FILE"
log "PHASE" "=========================================="
