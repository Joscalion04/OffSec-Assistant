#!/usr/bin/env bash
# OffSec Assistant — Bootstrap installer
# Instala el CLI offsec en el host y configura el entorno.
#
# Uso:
#   ./install.sh              # instalación interactiva
#   ./install.sh --uninstall  # desinstala el CLI

set -euo pipefail

# ── Colores ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${CYAN}[install]${RESET} $*"; }
ok()    { echo -e "${GREEN}[install]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[install][WARN]${RESET} $*"; }
error() { echo -e "${RED}[install][ERROR]${RESET} $*" >&2; }
die()   { error "$*"; exit 1; }

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${HOME}/.local/bin"
CLI_TARGET="${INSTALL_DIR}/offsec"
CONFIG_DIR="${HOME}/.config/offsec"
CONFIG_FILE="${CONFIG_DIR}/env"

# ── Detectar shell profile ─────────────────────────────────────────────────────
_detect_profile() {
    local shell_name
    shell_name="$(basename "${SHELL:-bash}")"
    case "$shell_name" in
        zsh)  echo "${HOME}/.zshrc" ;;
        bash) [[ -f "${HOME}/.bash_profile" ]] && echo "${HOME}/.bash_profile" || echo "${HOME}/.bashrc" ;;
        fish) echo "${HOME}/.config/fish/config.fish" ;;
        *)    echo "${HOME}/.profile" ;;
    esac
}

# ── Verificar dependencias ─────────────────────────────────────────────────────
_check_deps() {
    info "Verificando dependencias..."

    local missing=()

    command -v docker &>/dev/null   || missing+=("docker")
    command -v git    &>/dev/null   || missing+=("git")
    command -v python3 &>/dev/null  || missing+=("python3")

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Dependencias faltantes: ${missing[*]}"
        echo ""
        echo "  Instalación en Arch/Manjaro:"
        echo "    sudo pacman -S docker git python"
        echo ""
        echo "  Instalación en Kali/Debian/Ubuntu:"
        echo "    sudo apt install docker.io git python3"
        echo ""
        die "Instalá las dependencias y volvé a ejecutar install.sh"
    fi

    ok "Docker   $(docker --version | awk '{print $3}' | tr -d ',')"
    ok "Git      $(git --version | awk '{print $3}')"
    ok "Python   $(python3 --version | awk '{print $2}')"

    # Verificar que Docker corra (sin sudo si está en el grupo)
    if ! docker info &>/dev/null 2>&1; then
        warn "El daemon de Docker no está activo o necesitás sudo."
        warn "Activalo con: sudo systemctl start docker"
        warn "Para usar Docker sin sudo: sudo usermod -aG docker \$USER  (requiere logout)"
    fi
}

# ── Crear estructura de directorios ────────────────────────────────────────────
_create_dirs() {
    info "Creando estructura de directorios..."

    mkdir -p \
        "${SCRIPT_DIR}/findings" \
        "${SCRIPT_DIR}/reports" \
        "${SCRIPT_DIR}/logs" \
        "${SCRIPT_DIR}/docker/vpn" \
        "${CONFIG_DIR}" \
        "${INSTALL_DIR}"

    ok "Directorios listos"
}

# ── Instalar el CLI ────────────────────────────────────────────────────────────
_install_cli() {
    info "Instalando CLI offsec en ${CLI_TARGET}..."

    if [[ ! -f "${SCRIPT_DIR}/offsec" ]]; then
        die "No se encontró el script offsec en ${SCRIPT_DIR}"
    fi

    chmod +x "${SCRIPT_DIR}/offsec"

    # Symlink apunta siempre a la versión del repo (auto-actualizable)
    ln -sf "${SCRIPT_DIR}/offsec" "${CLI_TARGET}"

    ok "CLI instalado → ${CLI_TARGET}"
}

# ── Guardar OFFSEC_HOME ────────────────────────────────────────────────────────
_save_config() {
    info "Guardando configuración..."

    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOF
# OffSec Assistant — Configuración del CLI
# Generado por install.sh el $(date +%Y-%m-%d)
OFFSEC_HOME="${SCRIPT_DIR}"
EOF

    ok "OFFSEC_HOME=${SCRIPT_DIR}  →  ${CONFIG_FILE}"
}

# ── Agregar ~/.local/bin al PATH si no está ────────────────────────────────────
_patch_path() {
    local profile
    profile="$(_detect_profile)"

    if echo "$PATH" | tr ':' '\n' | grep -qx "${INSTALL_DIR}"; then
        ok "${HOME}/.local/bin ya está en PATH"
        return 0
    fi

    info "Agregando ${INSTALL_DIR} al PATH en ${profile}..."

    cat >> "$profile" <<'SHELL'

# OffSec Assistant CLI
export PATH="${HOME}/.local/bin:${PATH}"
SHELL

    warn "PATH actualizado en ${profile}"
    warn "Para aplicarlo ahora: source ${profile}"
    warn "O abrí una nueva terminal."
}

# ── Configurar .env ────────────────────────────────────────────────────────────
_setup_env() {
    local env_file="${SCRIPT_DIR}/.env"

    if [[ -f "$env_file" ]]; then
        ok ".env ya existe — no se sobreescribe"
        return 0
    fi

    if [[ ! -f "${SCRIPT_DIR}/.env.example" ]]; then
        warn ".env.example no encontrado — saltando configuración de .env"
        return 0
    fi

    info "Creando .env desde .env.example..."
    cp "${SCRIPT_DIR}/.env.example" "$env_file"

    echo ""
    warn "ACCIÓN REQUERIDA: configurá tu API key en ${env_file}"
    warn "Editá la línea: ANTHROPIC_API_KEY=sk-ant-api03-REEMPLAZAR"
    echo ""
}

# ── Desinstalación ─────────────────────────────────────────────────────────────
_uninstall() {
    info "Desinstalando CLI offsec..."

    [[ -L "$CLI_TARGET" ]] && rm -f "$CLI_TARGET" && ok "Symlink removido: ${CLI_TARGET}"
    [[ -f "$CONFIG_FILE" ]] && rm -f "$CONFIG_FILE" && ok "Config removida: ${CONFIG_FILE}"

    warn "OFFSEC_HOME y los datos de engagement NO fueron eliminados."
    warn "Para eliminar todo: rm -rf ${SCRIPT_DIR}"
}

# ── Banner final ───────────────────────────────────────────────────────────────
_print_next_steps() {
    echo ""
    echo -e "${GREEN}${BOLD}  ✓ OffSec Assistant instalado correctamente${RESET}"
    echo ""
    echo -e "${BOLD}  Próximos pasos:${RESET}"
    echo ""

    if ! echo "$PATH" | tr ':' '\n' | grep -qx "${INSTALL_DIR}"; then
        echo "  1. Recargá tu shell:"
        echo "     source $(_detect_profile)"
        echo ""
        echo "  2. Configurá tu API key:"
    else
        echo "  1. Configurá tu API key:"
    fi

    echo "     vim ${SCRIPT_DIR}/.env"
    echo "     # ANTHROPIC_API_KEY=sk-ant-..."
    echo ""
    echo "  3. Iniciá el assistant:"
    echo "     offsec start"
    echo ""
    echo "  4. Conectate:"
    echo "     offsec in"
    echo ""
    echo -e "  ${CYAN}Ayuda:${RESET} offsec help"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════
main() {
    echo ""
    echo -e "${BOLD}  OffSec Assistant — Instalador${RESET}"
    echo "  ─────────────────────────────────────"
    echo ""

    # Modo desinstalación
    if [[ "${1:-}" == "--uninstall" ]]; then
        _uninstall
        exit 0
    fi

    _check_deps
    _create_dirs
    _install_cli
    _save_config
    _patch_path
    _setup_env
    _print_next_steps
}

main "$@"
