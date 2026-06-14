#!/usr/bin/env python3
"""
parse-privesc.py — Parser automático de output de linPEAS / winPEAS

Uso:
  python3 parse-privesc.py <engagement_dir> <output_file>
  python3 parse-privesc.py <engagement_dir> <output_file> --json
  python3 parse-privesc.py <engagement_dir> <output_file> --finding

Flags:
  --json      Output JSON crudo de hallazgos
  --finding   Genera un finding_privesc.md directamente en el engagement

El parser detecta automáticamente si el archivo es de linPEAS o winPEAS.
"""

import sys
import re
import json
import argparse
from pathlib import Path
from datetime import datetime

# ---------------------------------------------------------------------------
# Patrones de detección linPEAS
# ---------------------------------------------------------------------------

LINPEAS_SECTION_RE = re.compile(
    r"(?:╔══════════════════════════╣|═══════════════════════╣)\s*(.+?)(?:\s*╠|$)",
    re.IGNORECASE,
)

LINPEAS_HIGH_RE = re.compile(
    r"(?:\x1b\[[0-9;]*m)?(?:\[!\]|CRITICAL|High|95%|\+\+\+|\*\*\*)", re.IGNORECASE
)

LINPEAS_CRED_RE = re.compile(
    r"(?:password|passwd|secret|token|api.?key|credentials?)\s*[=:]\s*(\S+)",
    re.IGNORECASE,
)

LINPEAS_SUID_RE = re.compile(
    r"(-rws[rwx-]{6}|--s[rwx-]{6})\s+\S+\s+\S+\s+(\S+)", re.IGNORECASE
)

LINPEAS_SUDO_RE = re.compile(r"(\w+)\s+ALL=.*NOPASSWD.*", re.IGNORECASE)

LINPEAS_WRITABLE_RE = re.compile(
    r"(?:Writable|world.?writable)\s+(?:path|dir|file):\s*(\S+)", re.IGNORECASE
)

LINPEAS_CRON_RE = re.compile(
    r"(?:/etc/cron\S*|crontab).*?(\S+\.(?:sh|py|pl|rb|php))", re.IGNORECASE
)

LINPEAS_KERNEL_RE = re.compile(r"Linux version\s+([\d.]+)", re.IGNORECASE)

LINPEAS_INTERESTING_FILE_RE = re.compile(
    r"(?:interesting|sensitive|backup|\.bak|\.old|\.config|id_rsa|\.pem)\s+(?:file|path)?\s*:?\s*(\S+)",
    re.IGNORECASE,
)

# ---------------------------------------------------------------------------
# Patrones de detección winPEAS
# ---------------------------------------------------------------------------

WINPEAS_SECTION_RE = re.compile(r"={10,}\s*(.+?)\s*={10,}", re.IGNORECASE)

WINPEAS_HIGH_RE = re.compile(
    r"(?:\[!\]|\[!!!\]|CRITICAL|Found interesting)", re.IGNORECASE
)

WINPEAS_CRED_RE = re.compile(
    r"(?:Password|Credential|Secret|Token)\s*[=:]\s*(\S+)", re.IGNORECASE
)

WINPEAS_ALWAYSINSTALLELEVATED_RE = re.compile(
    r"AlwaysInstallElevated.*?(?:PRESENT|enabled|1)", re.IGNORECASE
)

WINPEAS_AUTOLOGON_RE = re.compile(r"DefaultPassword\s*[=:]\s*(\S+)", re.IGNORECASE)

WINPEAS_UNQUOTED_RE = re.compile(r"Unquoted Service Path.*?:\s*(.+)", re.IGNORECASE)

WINPEAS_WRITABLEREG_RE = re.compile(
    r"(?:Writable|Modifiable)\s+(?:Registry|Service)\s*:\s*(\S+)", re.IGNORECASE
)

WINPEAS_MODIFIABLE_RE = re.compile(
    r"Modifiable\s+(?:binary|path|service)\s*:\s*(\S+)", re.IGNORECASE
)

# ---------------------------------------------------------------------------
# MITRE mapping para privesc (local, sin importar map-mitre.py)
# ---------------------------------------------------------------------------

PRIVESC_MITRE = {
    "suid": "T1548.001 — Abuse Elevation Control Mechanism: Setuid",
    "sudo": "T1548.003 — Abuse Elevation Control Mechanism: Sudo",
    "cron": "T1053.003 — Scheduled Task/Job: Cron",
    "credentials": "T1552 — Unsecured Credentials",
    "writable_path": "T1574.007 — Hijack Execution Flow: Path Interception",
    "kernel_exploit": "T1068 — Exploitation for Privilege Escalation",
    "unquoted_service": "T1574.009 — Hijack Execution Flow: Path Interception by PATH Environment Variable",
    "always_install_elevated": "T1548.002 — Abuse Elevation Control Mechanism: Bypass User Access Control",
    "autologon": "T1552.002 — Unsecured Credentials: Credentials in Registry",
    "modifiable_service": "T1574.010 — Hijack Execution Flow: Services File Permissions Weakness",
}


# ---------------------------------------------------------------------------
# Funciones de detección
# ---------------------------------------------------------------------------


def strip_ansi(text: str) -> str:
    """Elimina códigos de escape ANSI."""
    ansi_escape = re.compile(r"\x1b\[[0-9;]*[mGKH]")
    return ansi_escape.sub("", text)


def detect_tool(content: str) -> str:
    """Detecta si el output es de linPEAS o winPEAS."""
    if (
        "PEASS-ng" in content
        or "linpeas" in content.lower()
        or "Linux Privesc" in content
    ):
        return "linpeas"
    if (
        "winpeas" in content.lower()
        or "Windows Privesc" in content
        or "WinPEAS" in content
    ):
        return "winpeas"
    # fallback: si hay referencias a /etc/, /proc/, asumimos linux
    if "/etc/" in content or "/proc/" in content:
        return "linpeas"
    return "unknown"


def parse_linpeas(lines: list) -> dict:
    """Parsea output de linPEAS y retorna dict de categorías."""
    findings = {
        "tool": "linPEAS",
        "platform": "Linux",
        "high_priority": [],
        "credentials": [],
        "suid_binaries": [],
        "sudo_misconfig": [],
        "writable_paths": [],
        "cron_jobs": [],
        "interesting_files": [],
        "kernel_version": None,
        "raw_high_lines": [],
    }

    current_section = "general"

    for i, line in enumerate(lines):
        clean = strip_ansi(line).strip()
        if not clean:
            continue

        # Detectar sección
        sec_match = LINPEAS_SECTION_RE.search(clean)
        if sec_match:
            current_section = sec_match.group(1).strip().lower()
            continue

        # Credenciales
        cred_match = LINPEAS_CRED_RE.search(clean)
        if cred_match and len(cred_match.group(1)) > 3:
            findings["credentials"].append(
                {
                    "context": clean[:200],
                    "section": current_section,
                    "mitre": PRIVESC_MITRE["credentials"],
                }
            )

        # SUID
        suid_match = LINPEAS_SUID_RE.search(clean)
        if suid_match:
            findings["suid_binaries"].append(
                {
                    "path": suid_match.group(2),
                    "perms": suid_match.group(1),
                    "mitre": PRIVESC_MITRE["suid"],
                }
            )

        # Sudo
        sudo_match = LINPEAS_SUDO_RE.search(clean)
        if sudo_match:
            findings["sudo_misconfig"].append(
                {"line": clean[:200], "mitre": PRIVESC_MITRE["sudo"]}
            )

        # Rutas escribibles
        writable_match = LINPEAS_WRITABLE_RE.search(clean)
        if writable_match:
            findings["writable_paths"].append(
                {
                    "path": writable_match.group(1),
                    "mitre": PRIVESC_MITRE["writable_path"],
                }
            )

        # Cron jobs
        cron_match = LINPEAS_CRON_RE.search(clean)
        if cron_match:
            findings["cron_jobs"].append(
                {
                    "script": cron_match.group(1),
                    "line": clean[:200],
                    "mitre": PRIVESC_MITRE["cron"],
                }
            )

        # Kernel version
        if not findings["kernel_version"]:
            kernel_match = LINPEAS_KERNEL_RE.search(clean)
            if kernel_match:
                findings["kernel_version"] = kernel_match.group(1)

        # Archivos interesantes
        interesting_match = LINPEAS_INTERESTING_FILE_RE.search(clean)
        if interesting_match:
            findings["interesting_files"].append(interesting_match.group(1))

        # Líneas de alta prioridad (marcadores visuales de linPEAS)
        if LINPEAS_HIGH_RE.search(line):
            findings["raw_high_lines"].append(clean[:300])

    # Calcular severity basada en hallazgos
    findings["severity"] = _calc_severity_linux(findings)
    return findings


def parse_winpeas(lines: list) -> dict:
    """Parsea output de winPEAS y retorna dict de categorías."""
    findings = {
        "tool": "winPEAS",
        "platform": "Windows",
        "high_priority": [],
        "credentials": [],
        "autologon": [],
        "unquoted_services": [],
        "always_install_elevated": False,
        "modifiable_services": [],
        "writable_registry": [],
        "raw_high_lines": [],
    }

    for line in lines:
        clean = strip_ansi(line).strip()
        if not clean:
            continue

        # Credenciales / passwords
        cred_match = WINPEAS_CRED_RE.search(clean)
        if cred_match and len(cred_match.group(1)) > 3:
            findings["credentials"].append(
                {"context": clean[:200], "mitre": PRIVESC_MITRE["credentials"]}
            )

        # Autologon
        autologon_match = WINPEAS_AUTOLOGON_RE.search(clean)
        if autologon_match:
            findings["autologon"].append(
                {"context": clean[:200], "mitre": PRIVESC_MITRE["autologon"]}
            )

        # AlwaysInstallElevated
        if WINPEAS_ALWAYSINSTALLELEVATED_RE.search(clean):
            findings["always_install_elevated"] = True

        # Unquoted service paths
        unquoted_match = WINPEAS_UNQUOTED_RE.search(clean)
        if unquoted_match:
            findings["unquoted_services"].append(
                {
                    "path": unquoted_match.group(1).strip(),
                    "mitre": PRIVESC_MITRE["unquoted_service"],
                }
            )

        # Servicios modificables
        modifiable_match = WINPEAS_MODIFIABLE_RE.search(clean)
        if modifiable_match:
            findings["modifiable_services"].append(
                {
                    "path": modifiable_match.group(1),
                    "mitre": PRIVESC_MITRE["modifiable_service"],
                }
            )

        # Registro escribible
        writable_reg_match = WINPEAS_WRITABLEREG_RE.search(clean)
        if writable_reg_match:
            findings["writable_registry"].append(
                {
                    "path": writable_reg_match.group(1),
                    "mitre": PRIVESC_MITRE["writable_path"],
                }
            )

        # Líneas de alta prioridad
        if WINPEAS_HIGH_RE.search(line):
            findings["raw_high_lines"].append(clean[:300])

    findings["severity"] = _calc_severity_windows(findings)
    return findings


def _calc_severity_linux(f: dict) -> str:
    if f["credentials"] or (f["suid_binaries"] and len(f["suid_binaries"]) > 2):
        return "High"
    if f["sudo_misconfig"] or f["cron_jobs"]:
        return "Medium"
    if f["writable_paths"] or f["interesting_files"]:
        return "Low"
    return "Info"


def _calc_severity_windows(f: dict) -> str:
    if f["credentials"] or f["autologon"] or f["always_install_elevated"]:
        return "High"
    if f["unquoted_services"] or f["modifiable_services"]:
        return "Medium"
    if f["writable_registry"]:
        return "Low"
    return "Info"


def generate_finding_md(findings: dict, engagement_dir: Path) -> str:
    """Genera el contenido de un finding_privesc.md."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    tool = findings.get("tool", "PEAS")
    platform = findings.get("platform", "Unknown")
    severity = findings.get("severity", "Medium")
    cvss_map = {
        "Critical": "9.0",
        "High": "7.5",
        "Medium": "5.5",
        "Low": "3.5",
        "Info": "1.0",
    }
    cvss = cvss_map.get(severity, "5.0")

    sections = [
        "# FIND-PRIVESC — Post-Explotacion: Privilege Escalation Vectors",
        "",
        f"**Fecha:** {now}",
        f"**Herramienta:** {tool}",
        f"**Plataforma:** {platform}",
        f"**Severidad:** {severity}",
        f"**CVSS 3.1:** {cvss} (estimado — ajustar con vector completo)",
        "",
        "---",
        "",
        "## Descripcion",
        "",
        f"Analisis automatico de output de {tool} sobre el host comprometido.",
        "Se identificaron vectores potenciales de escalacion de privilegios.",
        "",
        "---",
        "",
    ]

    # Credenciales
    if findings.get("credentials"):
        sections += [
            "## Credenciales Encontradas",
            "",
            f"**MITRE:** {PRIVESC_MITRE['credentials']}",
            "",
        ]
        for c in findings["credentials"][:10]:
            sections.append(f"- `{c['context'][:120]}`")
        sections.append("")

    # SUID (linPEAS)
    if findings.get("suid_binaries"):
        sections += [
            "## Binarios SUID",
            "",
            f"**MITRE:** {PRIVESC_MITRE['suid']}",
            "",
        ]
        for s in findings["suid_binaries"][:15]:
            sections.append(f"- `{s['path']}` ({s['perms']})")
        sections.append("")
        sections.append("Revisar en GTFOBins: https://gtfobins.github.io/")
        sections.append("")

    # Sudo misconfig
    if findings.get("sudo_misconfig"):
        sections += [
            "## Configuracion Sudo Insegura",
            "",
            f"**MITRE:** {PRIVESC_MITRE['sudo']}",
            "",
        ]
        for s in findings["sudo_misconfig"][:10]:
            sections.append(f"- `{s['line'][:150]}`")
        sections.append("")

    # Cron jobs
    if findings.get("cron_jobs"):
        sections += [
            "## Cron Jobs con Scripts Escribibles",
            "",
            f"**MITRE:** {PRIVESC_MITRE['cron']}",
            "",
        ]
        for c in findings["cron_jobs"][:10]:
            sections.append(f"- Script: `{c['script']}` — `{c['line'][:120]}`")
        sections.append("")

    # Kernel version
    if findings.get("kernel_version"):
        sections += [
            f"## Version del Kernel: {findings['kernel_version']}",
            "",
            f"**MITRE:** {PRIVESC_MITRE['kernel_exploit']}",
            "",
            "Verificar exploits disponibles:",
            f"  searchsploit linux kernel {findings['kernel_version'].rsplit('.', 1)[0]}",
            "",
        ]

    # winPEAS specific
    if findings.get("always_install_elevated"):
        sections += [
            "## AlwaysInstallElevated Habilitado",
            "",
            f"**MITRE:** {PRIVESC_MITRE['always_install_elevated']}",
            "",
            "El sistema permite instalar MSI con privilegios SYSTEM.",
            "Vector: generar MSI malicioso con msfvenom.",
            "",
        ]

    if findings.get("unquoted_services"):
        sections += [
            "## Servicios con Rutas sin Comillas",
            "",
            f"**MITRE:** {PRIVESC_MITRE['unquoted_service']}",
            "",
        ]
        for s in findings["unquoted_services"][:10]:
            sections.append(f"- `{s['path']}`")
        sections.append("")

    if findings.get("autologon"):
        sections += [
            "## Credenciales AutoLogon en Registro",
            "",
            f"**MITRE:** {PRIVESC_MITRE['autologon']}",
            "",
        ]
        for a in findings["autologon"][:5]:
            sections.append(f"- `{a['context'][:150]}`")
        sections.append("")

    # Líneas de alta prioridad sin categorizar
    if findings.get("raw_high_lines"):
        sections += [
            "## Otras Lineas de Alta Prioridad",
            "",
        ]
        for line in findings["raw_high_lines"][:20]:
            sections.append(f"- `{line}`")
        sections.append("")

    sections += [
        "---",
        "",
        "## Pasos de Verificacion",
        "",
        "1. Revisar cada vector manualmente antes de intentar explotar",
        "2. Para SUID: consultar GTFOBins",
        "3. Para Sudo: `sudo -l` y verificar version (`sudo --version`)",
        "4. Documentar evidencia en evidence/screenshots/ antes de explotar",
        "",
        "## Remediacion",
        "",
        "- Auditar y corregir bits SUID innecesarios: `chmod u-s <binario>`",
        "- Revisar sudoers: eliminar NOPASSWD y entradas no justificadas",
        "- Asegurar permisos de scripts referenciados en cron",
        "- Rotar credenciales encontradas inmediatamente",
        "",
        "## Referencias",
        "",
        "- GTFOBins: https://gtfobins.github.io/",
        "- HackTricks Privesc: https://book.hacktricks.xyz/linux-hardening/privilege-escalation",
        "- PEASS-ng: https://github.com/carlospolop/PEASS-ng",
    ]

    return "\n".join(sections)


def main():
    parser = argparse.ArgumentParser(description="Parser automático de linPEAS/winPEAS")
    parser.add_argument(
        "engagement_dir", help="Directorio del engagement (para sanitizacion DLP)"
    )
    parser.add_argument("output_file", help="Archivo de output de linPEAS o winPEAS")
    parser.add_argument("--json", action="store_true", help="Output en JSON")
    parser.add_argument(
        "--finding",
        action="store_true",
        help="Genera finding_privesc.md en el engagement_dir",
    )

    args = parser.parse_args()

    output_path = Path(args.output_file)
    if not output_path.exists():
        print(f"[ERROR] Archivo no encontrado: {args.output_file}", file=sys.stderr)
        sys.exit(1)

    engagement_dir = Path(args.engagement_dir)

    content = output_path.read_text(errors="replace")
    lines = content.splitlines()

    tool = detect_tool(content)

    if tool == "linpeas":
        findings = parse_linpeas(lines)
    elif tool == "winpeas":
        findings = parse_winpeas(lines)
    else:
        # Intenta linpeas como fallback
        print(
            "[WARN] Herramienta no detectada, intentando parse como linPEAS",
            file=sys.stderr,
        )
        findings = parse_linpeas(lines)

    findings["source_file"] = str(output_path)
    findings["parsed_at"] = datetime.now().isoformat()

    if args.json:
        print(json.dumps(findings, indent=2, ensure_ascii=False))
        return

    if args.finding:
        finding_content = generate_finding_md(findings, engagement_dir)
        privesc_dir = engagement_dir / "post-exploitation"
        privesc_dir.mkdir(parents=True, exist_ok=True)
        out_file = privesc_dir / "finding_privesc.md"
        out_file.write_text(finding_content)
        print(f"[PRIVESC] Finding generado: {out_file}")
        print(f"[PRIVESC] Severidad detectada: {findings['severity']}")
        print(f"[PRIVESC] Herramienta: {findings['tool']}")
        return

    # Output resumido por defecto
    tool_name = findings.get("tool", "PEAS")
    severity = findings.get("severity", "?")

    print(f"\n[PRIVESC] Analisis de {tool_name}")
    print(f"  Severidad estimada:  {severity}")

    for category, label in [
        ("credentials", "Credenciales"),
        ("suid_binaries", "SUID binaries"),
        ("sudo_misconfig", "Sudo misconfig"),
        ("cron_jobs", "Cron jobs"),
        ("interesting_files", "Archivos interesantes"),
        ("unquoted_services", "Servicios sin comillas"),
        ("modifiable_services", "Servicios modificables"),
        ("raw_high_lines", "Lineas HIGH priority"),
    ]:
        items = findings.get(category, [])
        if items:
            print(f"  {label}: {len(items)}")

    if findings.get("kernel_version"):
        print(f"  Kernel: {findings['kernel_version']}")

    if findings.get("always_install_elevated"):
        print("  [!] AlwaysInstallElevated: HABILITADO")

    print("\n  Ejecutar con --finding para generar finding_privesc.md")
    print("  Ejecutar con --json para output detallado")


if __name__ == "__main__":
    main()
