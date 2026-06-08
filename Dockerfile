# OffSec Assistant — Contenedor de pentesting con IA
#
# Imagen base: kalilinux/kali-rolling (Offensive Security, verificado en Docker Hub)
# https://hub.docker.com/r/kalilinux/kali-rolling
#
# Targets:
#   lite  → herramientas esenciales (~2GB, build rápido)
#   full  → lite + Metasploit Framework (~5GB)
#
# Build:
#   docker build --target lite -t offsec-assistant:lite .
#   docker build --target full -t offsec-assistant:full .

# ════════════════════════════════════════════════════════════════════════════
# STAGE: base — sistema + dependencias compartidas
# ════════════════════════════════════════════════════════════════════════════
FROM kalilinux/kali-rolling AS base

LABEL org.opencontainers.image.title="OffSec Assistant" \
      org.opencontainers.image.description="AI-driven pentesting assistant — Claude Code + Kali toolset" \
      org.opencontainers.image.vendor="OffSec Assistant" \
      org.opencontainers.image.base.name="docker.io/kalilinux/kali-rolling"

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=22

ENV LANG=en_US.UTF-8 \
    TZ=UTC \
    USE_VPN=false \
    REPORT_LANG=es \
    WORKSPACE=/workspace \
    OFFSEC_HOME=/workspace \
    # Evitar que Node/npm escriban a directorios inesperados
    NPM_CONFIG_CACHE=/tmp/.npm \
    # Claude Code requiere esta variable para modo no-interactivo en builds
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# ── Capa 1: Base del sistema ─────────────────────────────────────────────
RUN apt-get update && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        git \
        unzip \
        jq \
        tzdata \
        locales \
        procps \
        iproute2 \
        iputils-ping \
        dnsutils \
        net-tools \
        iptables \
        less \
        vim-tiny \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Capa 2: Herramientas de red y escaneo ────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        nmap \
        masscan \
        netcat-traditional \
        tcpdump \
        ncat \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Capa 3: Reconocimiento ───────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        amass \
        subfinder \
        theharvester \
        whois \
        dnsrecon \
        dnsx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Capa 4: Herramientas web ─────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        ffuf \
        gobuster \
        nikto \
        whatweb \
        sqlmap \
        nuclei \
        python3 \
        python3-pip \
        python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Capa 4b: Active Directory / Windows ─────────────────────────────────
# enum4linux-ng, impacket suite, crackmapexec/netexec, bloodhound-python
RUN apt-get update && apt-get install -y --no-install-recommends \
        enum4linux \
        smbclient \
        ldap-utils \
        krb5-user \
        libkrb5-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir \
        impacket \
        ldapdomaindump \
        bloodhound \
        netexec \
        enum4linux-ng \
    && pip3 install --no-cache-dir \
        requests \
        dnspython

# ── Capa 5: VPN — OpenVPN + WireGuard ────────────────────────────────────
# NET_ADMIN capability requerida en runtime (ver docker-compose.yml)
RUN apt-get update && apt-get install -y --no-install-recommends \
        openvpn \
        wireguard-tools \
        resolvconf \
        openresolv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Capa 6: Node.js (NodeSource oficial) + Claude Code CLI ───────────────
# Fuente: https://github.com/nodesource/distributions (script oficial)
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x \
        -o /tmp/nodesource_setup.sh \
    && bash /tmp/nodesource_setup.sh \
    && rm /tmp/nodesource_setup.sh \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @anthropic-ai/claude-code \
    && npm cache clean --force \
    && rm -rf /tmp/.npm

# ── Workspace ────────────────────────────────────────────────────────────
RUN mkdir -p \
        /workspace/findings \
        /workspace/reports \
        /workspace/logs \
        /workspace/templates \
        /workspace/tools \
        /workspace/wordlists \
        /workspace/.claude \
        /vpn

WORKDIR /workspace

# Copiar solo los archivos que el contenedor necesita (explícito, no COPY . .)
COPY .claude/        /workspace/.claude/
COPY CLAUDE.md       /workspace/CLAUDE.md
COPY templates/      /workspace/templates/
COPY tools/          /workspace/tools/

# Entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Volúmenes para persistencia — datos nunca deben quedar en la imagen
VOLUME ["/workspace/findings", "/workspace/reports", "/workspace/logs", "/vpn"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["claude"]


# ════════════════════════════════════════════════════════════════════════════
# STAGE: lite — target por defecto (sin Metasploit)
# ════════════════════════════════════════════════════════════════════════════
FROM base AS lite

LABEL org.opencontainers.image.version="lite"


# ════════════════════════════════════════════════════════════════════════════
# STAGE: full — incluye Metasploit Framework
# Advertencia: agrega ~3GB al tamaño de la imagen
# ════════════════════════════════════════════════════════════════════════════
FROM base AS full

LABEL org.opencontainers.image.version="full"

RUN apt-get update && apt-get install -y --no-install-recommends \
        metasploit-framework \
        exploitdb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
