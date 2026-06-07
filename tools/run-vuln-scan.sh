#!/bin/bash
# OffSec Assistant — Vulnerability scan autónomo
# Uso: run-vuln-scan.sh <engagement> <target>

ENGAGEMENT="$1"
TARGET="$2"
OFFSEC_HOME="/home/joseph/Documents/OffSec/OffSec-Assistant"

source "$OFFSEC_HOME/tools/auto-runner.sh" "$ENGAGEMENT" "vulnscan" "$TARGET"

VULN_DIR="$ENGAGEMENT_DIR/vulns"
RECON_DIR="$ENGAGEMENT_DIR/recon"
mkdir -p "$VULN_DIR"

log "PHASE" "=========================================="
log "PHASE" " VULN-SCAN AUTÓNOMO — Target: $TARGET"
log "PHASE" "=========================================="

# Leer resultados de recon si existen
if [ -f "$RECON_DIR/nmap_ports.txt" ]; then
    log "THINK" "Leyendo resultados de recon previo..."
    OPEN_PORTS=$(grep "^[0-9]" "$RECON_DIR/nmap_ports.txt" | grep "open" | awk -F'/' '{print $1}' | sort -u | tr '\n' ',' | sed 's/,$//')
    log "THINK" "Puertos conocidos: $OPEN_PORTS"
    HAS_WEB=false
    grep -q "80/tcp.*open\|443/tcp.*open\|8080/tcp.*open" "$RECON_DIR/nmap_ports.txt" && HAS_WEB=true
else
    log "THINK" "No hay recon previo — ejecutando escaneo básico primero"
    nmap -T4 --top-ports 100 -oN "$VULN_DIR/quick_ports.txt" "$TARGET" &>/dev/null
    OPEN_PORTS=$(grep "open" "$VULN_DIR/quick_ports.txt" | awk -F'/' '{print $1}' | sort -u | tr '\n' ',' | sed 's/,$//')
    HAS_WEB=false
    grep -q "80/tcp.*open\|443/tcp.*open\|8080/tcp.*open" "$VULN_DIR/quick_ports.txt" && HAS_WEB=true
fi

log "PLAN" "Plan de análisis:"
log "PLAN" "  1. Nmap scripts de vulnerabilidades"
log "PLAN" "  2. Searchsploit en servicios detectados"
$HAS_WEB && log "PLAN" "  3. Nikto — análisis HTTP"
$HAS_WEB && log "PLAN" "  4. Nuclei — templates critical/high"

# ----- Nmap vuln scripts -----
log "PHASE" "--- Nmap vulnerability scripts ---"
if [ -n "$OPEN_PORTS" ]; then
    run_cmd "Nmap --script vuln" \
        "nmap --script vuln -p $OPEN_PORTS -oN $VULN_DIR/nmap_vuln.txt $TARGET" \
        "$VULN_DIR/nmap_vuln.txt"

    VULNS_FOUND=$(grep -c "VULNERABLE\|CVE" "$VULN_DIR/nmap_vuln.txt" 2>/dev/null || echo 0)
    if [ "$VULNS_FOUND" -gt 0 ]; then
        log "CRITICAL" "$VULNS_FOUND referencias de vulnerabilidades encontradas en nmap scripts"
        grep "VULNERABLE\|CVE" "$VULN_DIR/nmap_vuln.txt" | while read -r line; do
            log "FIND" "$line"
        done
    else
        log "DONE" "Nmap vuln scripts — sin hallazgos críticos inmediatos"
    fi
fi

# ----- Searchsploit -----
log "PHASE" "--- Correlación con ExploitDB ---"
if command -v searchsploit &>/dev/null; then
    if [ -f "$RECON_DIR/nmap_services.txt" ]; then
        grep -oP "(?<=\s)[A-Za-z\-]+\s[0-9]+\.[0-9]+" "$RECON_DIR/nmap_services.txt" | sort -u | while read -r SERVICE; do
            log "START" "Buscando exploits para: $SERVICE"
            RESULTS=$(searchsploit "$SERVICE" --disable-colour 2>/dev/null | grep -v "^--\|^Exploit Title" | head -5)
            if [ -n "$RESULTS" ]; then
                log "FIND" "Exploits disponibles para $SERVICE:"
                echo "$RESULTS" | while read -r line; do
                    log "FIND" "  $line"
                done
            fi
        done
        searchsploit --nmap "$RECON_DIR/nmap_services.txt" > "$VULN_DIR/searchsploit.txt" 2>&1
        log "DONE" "Correlación guardada en: $VULN_DIR/searchsploit.txt"
    fi
else
    log "SKIP" "searchsploit no instalado — omitiendo correlación ExploitDB"
fi

# ----- Web: Nikto + Nuclei -----
if $HAS_WEB; then
    log "PHASE" "--- Análisis web ---"

    PROTO="http"
    grep -q "443/open" "$RECON_DIR/nmap_ports.txt" 2>/dev/null && PROTO="https"
    WEB_URL="${PROTO}://${TARGET}"

    if command -v nikto &>/dev/null; then
        run_cmd "Nikto web scan" \
            "nikto -h $WEB_URL -o $VULN_DIR/nikto.txt -Format txt" \
            "$VULN_DIR/nikto_live.txt"

        NIKTO_FINDINGS=$(grep -c "^\+" "$VULN_DIR/nikto.txt" 2>/dev/null || echo 0)
        log "THINK" "Nikto encontró $NIKTO_FINDINGS ítems — revisar $VULN_DIR/nikto.txt"
    else
        log "SKIP" "nikto no instalado"
    fi

    if command -v nuclei &>/dev/null; then
        run_cmd "Nuclei critical/high templates" \
            "nuclei -u $WEB_URL -severity critical,high -o $VULN_DIR/nuclei.txt -silent" \
            "$VULN_DIR/nuclei_live.txt"

        NUCLEI_COUNT=$(wc -l < "$VULN_DIR/nuclei.txt" 2>/dev/null || echo 0)
        if [ "$NUCLEI_COUNT" -gt 0 ]; then
            log "CRITICAL" "Nuclei encontró $NUCLEI_COUNT hallazgos critical/high"
            cat "$VULN_DIR/nuclei.txt" | while read -r line; do
                log "FIND" "$line"
            done
        else
            log "DONE" "Nuclei — sin hallazgos critical/high"
        fi
    else
        log "SKIP" "nuclei no instalado"
    fi
fi

# ----- RESUMEN -----
log "PHASE" "=========================================="
log "SUMMARY" "VULN-SCAN COMPLETADO — $TARGET"
log "SUMMARY" "Archivos en: $VULN_DIR"
[ -f "$VULN_DIR/nmap_vuln.txt" ]    && log "SUMMARY" "▶ nmap_vuln.txt — revisar VULNERABLE entries"
[ -f "$VULN_DIR/searchsploit.txt" ] && log "SUMMARY" "▶ searchsploit.txt — exploits disponibles"
[ -f "$VULN_DIR/nikto.txt" ]        && log "SUMMARY" "▶ nikto.txt — $NIKTO_FINDINGS hallazgos web"
[ -f "$VULN_DIR/nuclei.txt" ]       && log "SUMMARY" "▶ nuclei.txt — $NUCLEI_COUNT hallazgos críticos"
log "SUMMARY" "Próximo paso: /report $ENGAGEMENT o revisar hallazgos manualmente"
log "SUMMARY" "Live feed: $LIVEFEED_FILE"
log "PHASE" "=========================================="
