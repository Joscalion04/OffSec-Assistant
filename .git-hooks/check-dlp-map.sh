#!/bin/bash
# Bloquea el staging de dlp-map.json — contiene IPs y hostnames reales del target.
# Este archivo debe permanecer local y nunca llegar al repositorio.

BLOCKED=0
for file in "$@"; do
    if [[ "$file" == *"dlp-map.json"* ]]; then
        echo "[ERROR] Intento de commit bloqueado: $file"
        echo "        dlp-map.json contiene datos sensibles del target (IPs, hostnames)."
        echo "        Este archivo NO debe ir al repositorio."
        echo "        Verificar que findings/ esté en .gitignore."
        BLOCKED=1
    fi
done

exit $BLOCKED
