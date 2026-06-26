#!/usr/bin/env python3
"""
OffSec Assistant — DLP Sanitizer
Tokeniza datos sensibles del target antes de que lleguen al agente de IA.

El dato real NUNCA sale del entorno local. El agente solo ve tokens abstractos.

Mapa persistente: findings/<engagement>/dlp-map.json
  - TGT-NNN  : direcciones IP del target
  - HST-NNN  : hostnames / FQDNs
  - ORG-NNN  : nombres de organizaciones (WHOIS, certificados)
  - MAIL-NNN : direcciones de email

Credenciales (passwords, hashes): siempre [CREDENTIAL-REDACTED], nunca tokenizadas.

Uso:
  # Sanitizar texto de stdin
  echo "nmap de 192.168.1.50" | python3 sanitizer.py /path/to/engagement_dir

  # Sanitizar un archivo
  python3 sanitizer.py /path/to/engagement_dir archivo.txt

  # Inicializar mapa desde scope.md del engagement
  python3 sanitizer.py /path/to/engagement_dir --init

  # Registrar un hostname descubierto en runtime
  python3 sanitizer.py /path/to/engagement_dir --register-host smtp.victima.com

  # Registrar una org descubierta (por ej. de WHOIS)
  python3 sanitizer.py /path/to/engagement_dir --register-org "Acme Corporation"
"""

import re
import json
import sys
from pathlib import Path
from typing import Optional, Union

MAP_VERSION = 2

# ── Patrones de credenciales — siempre redactadas completamente ──────────────
# El orden importa: de mayor a menor especificidad
CREDENTIAL_PATTERNS = [
    # Pares clave=valor con credenciales
    re.compile(
        r"(?i)\b(password|passwd|pass|pwd|secret|api[_-]?key|token|auth|"
        r"authorization|bearer|credential|cred|private[_-]?key)\s*[:=>\s]+\S+",
        re.IGNORECASE,
    ),
    # Hashes Unix (crypt) — soporta formato básico y rounds=N$
    re.compile(
        r"\$(?:1|2[aby]|5|6)\$(?:rounds=\d+\$)?[A-Za-z0-9./]{1,16}\$[A-Za-z0-9./]{22,86}"
    ),
    # NTLM / LM (32 hex chars) - solo si están en contexto de hash
    re.compile(
        r"\b(?:NTLM|LM|MD5|SHA1|SHA256|hash)[:\s]+([A-Fa-f0-9]{32,64})\b", re.IGNORECASE
    ),
    # SHA-256 aislado (64 hex)
    re.compile(r"\b[A-Fa-f0-9]{64}\b"),
    # SHA-1 aislado (40 hex)
    re.compile(r"\b[A-Fa-f0-9]{40}\b"),
    # Lineas con "password" en cualquier formato (catch-all)
    re.compile(r"(?i)(contraseña|password|passwd)\s*[:\-=]\s*.+"),
]

# ── Patrón IPv4 ──────────────────────────────────────────────────────────────
IPV4_RE = re.compile(
    r"\b"
    r"(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\."
    r"(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\."
    r"(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\."
    r"(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
    r"\b"
)

# ── Patrón IPv6 (RFC 5952 — full, compressed, CIDR) ──────────────────────────
# Cubre las 9 formas canónicas: full 8-grupos, 7 variantes con ::, y :: solo.
# Lookbehind/ahead evitan falsos positivos dentro de URLs o paths.
_S = r"[0-9a-fA-F]{1,4}"
IPV6_RE = re.compile(
    r"(?<![:\.\w])"
    r"(?:"
    rf"(?:{_S}:){{7}}{_S}"  # 1:2:3:4:5:6:7:8
    rf"|(?:{_S}:){{1,7}}:"  # 1:: … 7::
    rf"|(?:{_S}:){{1,6}}:{_S}"  # 1::8 … 6::8
    rf"|(?:{_S}:){{1,5}}(?::{_S}){{1,2}}"  # 1::7:8 … 5::7:8
    rf"|(?:{_S}:){{1,4}}(?::{_S}){{1,3}}"
    rf"|(?:{_S}:){{1,3}}(?::{_S}){{1,4}}"
    rf"|(?:{_S}:){{1,2}}(?::{_S}){{1,5}}"
    rf"|{_S}:(?::{_S}){{1,6}}"
    rf"|:(?::{_S}){{1,7}}"  # ::1 … ::1:2:3:4:5:6:7
    r"|::"  # :: (unspecified)
    r")"
    r"(?:/\d{1,3})?"  # prefijo CIDR opcional
    r"(?![:\.\w])",
    re.IGNORECASE,
)

# ── Patrón email ─────────────────────────────────────────────────────────────
EMAIL_RE = re.compile(r"\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b")

# ── IPs que NUNCA se tokenizan (infraestructura, no targets) ─────────────────
EXEMPT_IPS = {
    "127.0.0.1",
    "0.0.0.0",
    "255.255.255.255",
}

# Prefijos IPv6 exentos (loopback, unspecified, multicast, link-local)
_EXEMPT_IPV6_PREFIXES = ("::1", "::", "fe80:", "ff0", "fc00:", "fd")


def _is_exempt(ip: str) -> bool:
    if ip in EXEMPT_IPS:
        return True
    if ip.startswith("127."):
        return True
    ip_lower = ip.lower().split("/")[0]  # strip CIDR before checking
    for prefix in _EXEMPT_IPV6_PREFIXES:
        if ip_lower == prefix or ip_lower.startswith(prefix):
            return True
    return False


class DLPSanitizer:
    def __init__(self, engagement_dir: str):
        self.base = Path(engagement_dir)
        self.map_file = self.base / "dlp-map.json"
        self._map = self._load()

    # ── Persistencia del mapa ────────────────────────────────────────────────

    def _load(self) -> dict:
        if self.map_file.exists():
            try:
                with open(self.map_file, "r") as fh:
                    data = json.load(fh)
                if data.get("version") == MAP_VERSION:
                    return data
            except (json.JSONDecodeError, OSError):
                pass
        return {
            "version": MAP_VERSION,
            "targets": {},  # ip_str -> "TGT-NNN"
            "hosts": {},  # fqdn_lower -> "HST-NNN"
            "orgs": {},  # org_lower -> "ORG-NNN"
            "emails": {},  # email_lower -> "MAIL-NNN"
            "counters": {"tgt": 0, "hst": 0, "org": 0, "mail": 0},
        }

    def _save(self):
        self.base.mkdir(parents=True, exist_ok=True)
        tmp = self.map_file.with_suffix(".tmp")
        try:
            with open(tmp, "w") as fh:
                json.dump(self._map, fh, indent=2, ensure_ascii=False)
            tmp.replace(self.map_file)
        except OSError as exc:
            sys.stderr.write(f"[DLP] Error guardando mapa: {exc}\n")

    # ── Gestión de tokens ────────────────────────────────────────────────────

    def _token(self, category: str, value: str, prefix: str) -> str:
        """Devuelve token existente o crea uno nuevo para value."""
        key = value.lower() if category != "targets" else value
        store = self._map[category]
        if key in store:
            return store[key]
        counter_key = prefix.lower()
        self._map["counters"][counter_key] = (
            self._map["counters"].get(counter_key, 0) + 1
        )
        token = f'{prefix}-{self._map["counters"][counter_key]:03d}'
        store[key] = token
        self._save()
        return token

    def register_ip(self, ip: str) -> str:
        if _is_exempt(ip):
            return ip
        return self._token("targets", ip, "TGT")

    def register_host(self, hostname: str) -> str:
        hostname = hostname.strip().rstrip(".").lower()
        if not hostname:
            return hostname
        return self._token("hosts", hostname, "HST")

    def register_org(self, org: str) -> str:
        org = org.strip()
        if len(org) < 3:
            return org
        return self._token("orgs", org, "ORG")

    def register_email(self, email: str) -> str:
        return self._token("emails", email.lower(), "MAIL")

    # ── Sanitización de texto ────────────────────────────────────────────────

    def sanitize(self, text: str) -> str:
        if not text:
            return text

        # 1. Credenciales — redacción total (mayor prioridad)
        for pat in CREDENTIAL_PATTERNS:
            text = pat.sub("[CREDENTIAL-REDACTED]", text)

        # 2. Emails (antes de hostnames para no fragmentar el dominio)
        def _replace_email(m):
            return self.register_email(m.group(0))

        text = EMAIL_RE.sub(_replace_email, text)

        # 3. IPs (IPv4 e IPv6)
        def _replace_ip(m):
            ip = m.group(0)
            if _is_exempt(ip):
                return ip
            return self._token("targets", ip, "TGT")

        text = IPV4_RE.sub(_replace_ip, text)
        text = IPV6_RE.sub(_replace_ip, text)

        # 4. Hostnames conocidos (más largo primero, evita reemplazos parciales)
        sorted_hosts = sorted(
            self._map["hosts"].items(), key=lambda kv: len(kv[0]), reverse=True
        )
        for host, token in sorted_hosts:
            # Reemplaza el host y cualquier subdominio directo de él
            pat = re.compile(r"(?:[a-zA-Z0-9\-]+\.)?" + re.escape(host), re.IGNORECASE)
            text = pat.sub(token, text)

        # 5. Organizaciones conocidas (más largo primero)
        sorted_orgs = sorted(
            self._map["orgs"].items(), key=lambda kv: len(kv[0]), reverse=True
        )
        for org, token in sorted_orgs:
            if len(org) >= 4:
                pat = re.compile(re.escape(org), re.IGNORECASE)
                text = pat.sub(token, text)

        return text

    # ── Inicialización desde scope.md ────────────────────────────────────────

    def init_from_scope(self, scope_file: Optional[Union[str, Path]] = None):
        if scope_file is None:
            scope_file = self.base / "scope.md"
        scope_file = Path(scope_file)

        if not scope_file.exists():
            sys.stderr.write(f"[DLP] scope.md no encontrado: {scope_file}\n")
            return

        content = scope_file.read_text()

        # Registrar IPs (IPv4 e IPv6)
        for ip in set(IPV4_RE.findall(content)):
            if not _is_exempt(ip):
                self.register_ip(ip)
        for ip in set(IPV6_RE.findall(content)):
            ip_str = ip if isinstance(ip, str) else ip[0]
            if ip_str and not _is_exempt(ip_str):
                self.register_ip(ip_str)

        # Registrar FQDNs / dominios (patron: word.word.tld)
        host_re = re.compile(r"\b(?:[a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,}\b")
        for host in set(host_re.findall(content)):
            # Excluir patrones de fecha (2026-06-08) o paths (/foo/bar.sh)
            if re.search(r"[0-9]{4}", host):
                continue
            self.register_host(host)

        # Registrar emails
        for email in set(EMAIL_RE.findall(content)):
            self.register_email(email)

        # Extraer nombres de cliente/contacto de las primeras lineas del scope
        for line in content.splitlines():
            m = re.match(r"\*\*Cliente:\*\*\s*(.+)", line)
            if m:
                client = m.group(1).strip().strip("[]")
                if client and not client.startswith("["):
                    self.register_org(client)

        n_ips = len(self._map["targets"])
        n_hosts = len(self._map["hosts"])
        n_orgs = len(self._map["orgs"])
        sys.stderr.write(
            f"[DLP] Mapa inicializado: {n_ips} IPs, {n_hosts} hosts, {n_orgs} orgs\n"
        )

    # ── Validación de scope.md ────────────────────────────────────────────────

    def validate_scope(self, scope_file: Optional[Union[str, Path]] = None) -> list:
        """
        Valida la estructura mínima de scope.md.
        Retorna lista de errores (vacía = válido).
        """
        if scope_file is None:
            scope_file = self.base / "scope.md"
        scope_file = Path(scope_file)

        if not scope_file.exists():
            return [f"scope.md no encontrado en: {scope_file}"]

        content = scope_file.read_text(errors="replace")

        if not content.strip():
            return ["scope.md está vacío — agregá al menos un target autorizado"]

        # Líneas con contenido real (no vacías, no headers markdown)
        meaningful = [
            ln
            for ln in content.splitlines()
            if ln.strip() and not ln.strip().startswith("#")
        ]
        if not meaningful:
            return ["scope.md solo contiene comentarios — no hay targets definidos"]

        errors = []

        # Detectar campos de plantilla sin completar: [TEXTO EN MAYÚSCULAS o descriptivo]
        _placeholder_re = re.compile(r"\[[A-Z][A-Za-z _\-/]{4,}\]")
        unfilled = [ln.strip() for ln in meaningful if _placeholder_re.search(ln)]
        if unfilled:
            errors.append(
                f"scope.md contiene {len(unfilled)} campo(s) de plantilla sin completar "
                f"(ej: {unfilled[0]!r})"
            )

        # Verificar que existe al menos un target (IP o FQDN)
        _fqdn_re = re.compile(r"\b(?:[a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,}\b")
        has_ipv4 = bool(IPV4_RE.search(content))
        has_ipv6 = bool(IPV6_RE.search(content))
        has_fqdn = bool(_fqdn_re.search(content))
        if not (has_ipv4 or has_ipv6 or has_fqdn):
            errors.append(
                "scope.md no contiene IPs ni dominios — "
                "definí al menos un target autorizado"
            )

        return errors


# ── CLI ──────────────────────────────────────────────────────────────────────


def main():
    if len(sys.argv) < 2:
        sys.stderr.write(
            "Uso: sanitizer.py <engagement_dir> [archivo | --init "
            "| --register-host <h> | --register-org <o>]\n"
        )
        sys.exit(1)

    engagement_dir = sys.argv[1]
    s = DLPSanitizer(engagement_dir)

    if len(sys.argv) >= 3:
        cmd = sys.argv[2]

        if cmd == "--init":
            s.init_from_scope()
            return

        if cmd == "--validate":
            errors = s.validate_scope()
            if errors:
                for err in errors:
                    sys.stderr.write(f"[SCOPE] ERROR: {err}\n")
                sys.exit(1)
            sys.stderr.write("[SCOPE] OK — scope.md válido\n")
            return

        if cmd == "--register-host" and len(sys.argv) >= 4:
            token = s.register_host(sys.argv[3])
            print(token)
            return

        if cmd == "--register-org" and len(sys.argv) >= 4:
            org = " ".join(sys.argv[3:])
            token = s.register_org(org)
            print(token)
            return

        # Es un archivo
        file_path = Path(cmd)
        if not file_path.exists():
            sys.stderr.write(f"[DLP] Archivo no encontrado: {file_path}\n")
            sys.exit(1)
        text = file_path.read_text(errors="replace")
    else:
        text = sys.stdin.read()

    print(s.sanitize(text), end="")


if __name__ == "__main__":
    main()
