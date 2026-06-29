#!/usr/bin/env bash
# OffSec Assistant — Entrypoint del contenedor
# Gestiona el ciclo de vida: VPN opcional → validación → proceso principal
#
# En modo daemon (docker compose up -d), el proceso principal es "tail -f /dev/null".
# Las sesiones de Claude Code se abren vía: docker exec -it offsec-assistant claude

set -euo pipefail

# ── Colores para logs ─────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

log_info()  { echo -e "${CYAN}[offsec]${RESET} $*" >&2; }
log_ok()    { echo -e "${GREEN}[offsec]${RESET} $*" >&2; }
log_warn()  { echo -e "${YELLOW}[offsec][WARN]${RESET} $*" >&2; }
log_error() { echo -e "${RED}[offsec][ERROR]${RESET} $*" >&2; }

# ── Validar API key ───────────────────────────────────────────────────────────
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    log_error "ANTHROPIC_API_KEY no está definida."
    log_error "Pasala al ejecutar el contenedor:"
    log_error "  -e ANTHROPIC_API_KEY=sk-ant-..."
    log_error "  o vía archivo .env"
    exit 1
fi

# ── Configuración VPN ─────────────────────────────────────────────────────────
setup_openvpn() {
    local config_file="$1"
    log_info "Iniciando OpenVPN con: $(basename "$config_file")"

    mkdir -p /workspace/logs

    openvpn \
        --config "$config_file" \
        --daemon \
        --log /workspace/logs/openvpn.log \
        --writepid /tmp/openvpn.pid \
        --script-security 2 \
        --up-restart

    log_info "Esperando interfaz tun0..."
    local timeout=30
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if ip link show tun0 &>/dev/null 2>&1; then
            log_ok "VPN activa — interfaz tun0 disponible"
            log_info "IP del túnel: $(ip addr show tun0 2>/dev/null | grep 'inet ' | awk '{print $2}' || echo 'N/A')"
            return 0
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    log_error "OpenVPN no levantó tun0 en ${timeout}s"
    log_error "Revisá el log: /workspace/logs/openvpn.log"
    return 1
}

setup_wireguard() {
    local config_file="$1"
    local iface
    iface=$(basename "$config_file" .conf)

    log_info "Iniciando WireGuard con: $(basename "$config_file")"

    # wg-quick necesita que el archivo esté en /etc/wireguard/ o ruta absoluta
    if wg-quick up "$config_file" 2>&1; then
        log_ok "WireGuard activo — interfaz ${iface}"
        log_info "IP del túnel: $(ip addr show "$iface" 2>/dev/null | grep 'inet ' | awk '{print $2}' || echo 'N/A')"
    else
        log_error "wg-quick falló. Verificá que el kernel tenga soporte WireGuard."
        log_error "En el host: lsmod | grep wireguard"
        return 1
    fi
}

# ── VPN: lógica principal ─────────────────────────────────────────────────────
if [ "${USE_VPN:-false}" = "true" ]; then
    log_info "USE_VPN=true — buscando configuración en /vpn/"

    if [ -f "/vpn/config.ovpn" ]; then
        setup_openvpn "/vpn/config.ovpn"

    elif ls /vpn/*.ovpn &>/dev/null 2>&1; then
        # Tomar el primer .ovpn disponible
        first_ovpn=$(find /vpn -name "*.ovpn" -print | head -n1)
        setup_openvpn "$first_ovpn"

    elif [ -f "/vpn/wg0.conf" ]; then
        setup_wireguard "/vpn/wg0.conf"

    elif ls /vpn/*.conf &>/dev/null 2>&1; then
        first_conf=$(find /vpn -name "*.conf" -print | head -n1)
        setup_wireguard "$first_conf"

    else
        log_warn "USE_VPN=true pero no se encontró ningún archivo de configuración en /vpn/"
        log_warn "Archivos esperados:"
        log_warn "  OpenVPN  → /vpn/config.ovpn  (o cualquier .ovpn)"
        log_warn "  WireGuard → /vpn/wg0.conf    (o cualquier .conf)"
        log_warn "Continuando SIN VPN..."
    fi
else
    log_info "Modo sin VPN (USE_VPN=${USE_VPN:-false})"
fi

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${CYAN}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║       OffSec Assistant — Listo        ║"
echo "  ║   Claude Code + Kali Linux Tools      ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${RESET}"

log_ok "Workspace: /workspace"

# Mostrar IP de VPN si está activa
if [ "${USE_VPN:-false}" = "true" ]; then
    log_info "Ruta de salida: $(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1 || echo 'N/A')"
fi

# ── Modo daemon ───────────────────────────────────────────────────────────────
# Cuando el comando principal es un proceso persistente (tail -f /dev/null),
# registramos un handler de SIGTERM para apagado limpio.
if [ "${1:-}" = "tail" ]; then
    log_info "Modo daemon activo — conectate con: offsec in"

    # shellcheck disable=SC2317  # función invocada vía trap, no directamente
    _shutdown() {
        log_info "Señal de apagado recibida — cerrando..."
        kill 0 2>/dev/null || true
        exit 0
    }
    trap '_shutdown' SIGTERM SIGINT

    # exec reemplaza este proceso — el trap no sobreviviría.
    # Lanzamos tail en background y esperamos para que el trap funcione.
    tail -f /dev/null &
    wait $!
    exit 0
fi

# ── Lanzar comando ────────────────────────────────────────────────────────────
exec "$@"
