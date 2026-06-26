#!/bin/bash
# OffSec Assistant — Perfiles de scan
#
# Uso:
#   export SCAN_PROFILE=aggressive  # antes de /recon o /vuln-scan
#   source scan-profiles.sh         # dentro de un script
#
# Perfiles disponibles:
#   silent     — sigilo máximo, mínima huella de red (redes monitoreadas)
#   standard   — balance detección/velocidad (default)
#   aggressive — cobertura máxima, sin restricción de velocidad (labs/CTF)

SCAN_PROFILE="${SCAN_PROFILE:-standard}"

case "$SCAN_PROFILE" in
    silent)
        NMAP_TIMING="-T2"
        NMAP_TOP_PORTS="100"
        NMAP_EXTRA_FLAGS=""
        NMAP_FULL_PORTS=false
        NUCLEI_SEVERITY="critical"
        FFUF_RATE="10"
        NIKTO_OPTS="-Pause 2"
        ;;
    standard)
        NMAP_TIMING="-T4"
        NMAP_TOP_PORTS="1000"
        NMAP_EXTRA_FLAGS=""
        NMAP_FULL_PORTS=false
        NUCLEI_SEVERITY="critical,high"
        FFUF_RATE="50"
        NIKTO_OPTS=""
        ;;
    aggressive)
        NMAP_TIMING="-T5"
        NMAP_TOP_PORTS="65535"
        NMAP_EXTRA_FLAGS="-A"
        NMAP_FULL_PORTS=true
        NUCLEI_SEVERITY="critical,high,medium"
        FFUF_RATE="200"
        NIKTO_OPTS="-C all"
        ;;
    *)
        echo "[WARN] Perfil desconocido: '${SCAN_PROFILE}' — usando standard" >&2
        SCAN_PROFILE="standard"
        NMAP_TIMING="-T4"
        NMAP_TOP_PORTS="1000"
        NMAP_EXTRA_FLAGS=""
        NMAP_FULL_PORTS=false
        NUCLEI_SEVERITY="critical,high"
        FFUF_RATE="50"
        NIKTO_OPTS=""
        ;;
esac

export SCAN_PROFILE
export NMAP_TIMING NMAP_TOP_PORTS NMAP_EXTRA_FLAGS NMAP_FULL_PORTS
export NUCLEI_SEVERITY FFUF_RATE NIKTO_OPTS
