#!/usr/bin/env python3
"""
map-mitre.py — Mapeador de hallazgos a MITRE ATT&CK

Uso:
  python3 map-mitre.py "sql injection"
  python3 map-mitre.py --finding findings/2026-01-01_eng/finding_001.md
  python3 map-mitre.py --list-tactics
  python3 map-mitre.py --json "rce"
"""

import sys
import json
import argparse
from pathlib import Path

# ---------------------------------------------------------------------------
# Base de conocimiento: keyword/category → técnica(s) ATT&CK
# Formato: { "categoria": { "id": "T...", "name": "...", "tactic": "...", "url": "..." } }
# ---------------------------------------------------------------------------

TECHNIQUE_DB = {
    # ── Reconocimiento ───────────────────────────────────────────────────────
    "port scan": {
        "id": "T1046",
        "name": "Network Service Discovery",
        "tactic": "Discovery",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1046/",
    },
    "service enumeration": {
        "id": "T1046",
        "name": "Network Service Discovery",
        "tactic": "Discovery",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1046/",
    },
    "subdomain enumeration": {
        "id": "T1595.002",
        "name": "Active Scanning: Vulnerability Scanning",
        "tactic": "Reconnaissance",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1595/002/",
    },
    "directory brute force": {
        "id": "T1595.002",
        "name": "Active Scanning: Vulnerability Scanning",
        "tactic": "Reconnaissance",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1595/002/",
    },
    "whois": {
        "id": "T1590.002",
        "name": "Gather Victim Network Information: DNS",
        "tactic": "Reconnaissance",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1590/002/",
    },
    "osint": {
        "id": "T1589",
        "name": "Gather Victim Identity Information",
        "tactic": "Reconnaissance",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1589/",
    },
    # ── Initial Access ───────────────────────────────────────────────────────
    "sql injection": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "sqli": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "rce": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "remote code execution": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "command injection": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "file upload": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "lfi": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "local file inclusion": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "rfi": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "ssrf": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "xxe": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "deserialization": {
        "id": "T1190",
        "name": "Exploit Public-Facing Application",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1190/",
    },
    "vpn": {
        "id": "T1133",
        "name": "External Remote Services",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1133/",
    },
    "rdp": {
        "id": "T1133",
        "name": "External Remote Services",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1133/",
    },
    "ssh": {
        "id": "T1078",
        "name": "Valid Accounts",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1078/",
    },
    "default credentials": {
        "id": "T1078.001",
        "name": "Valid Accounts: Default Accounts",
        "tactic": "Initial Access",
        "sub": "001",
        "url": "https://attack.mitre.org/techniques/T1078/001/",
    },
    "phishing": {
        "id": "T1566",
        "name": "Phishing",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1566/",
    },
    # ── Execution ────────────────────────────────────────────────────────────
    "webshell": {
        "id": "T1505.003",
        "name": "Server Software Component: Web Shell",
        "tactic": "Persistence",
        "sub": "003",
        "url": "https://attack.mitre.org/techniques/T1505/003/",
    },
    "web shell": {
        "id": "T1505.003",
        "name": "Server Software Component: Web Shell",
        "tactic": "Persistence",
        "sub": "003",
        "url": "https://attack.mitre.org/techniques/T1505/003/",
    },
    "powershell": {
        "id": "T1059.001",
        "name": "Command and Scripting Interpreter: PowerShell",
        "tactic": "Execution",
        "sub": "001",
        "url": "https://attack.mitre.org/techniques/T1059/001/",
    },
    "bash": {
        "id": "T1059.004",
        "name": "Command and Scripting Interpreter: Unix Shell",
        "tactic": "Execution",
        "sub": "004",
        "url": "https://attack.mitre.org/techniques/T1059/004/",
    },
    # ── Privilege Escalation ─────────────────────────────────────────────────
    "privilege escalation": {
        "id": "T1068",
        "name": "Exploitation for Privilege Escalation",
        "tactic": "Privilege Escalation",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1068/",
    },
    "lpe": {
        "id": "T1068",
        "name": "Exploitation for Privilege Escalation",
        "tactic": "Privilege Escalation",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1068/",
    },
    "suid": {
        "id": "T1548.001",
        "name": "Abuse Elevation Control Mechanism: Setuid and Setgid",
        "tactic": "Privilege Escalation",
        "sub": "001",
        "url": "https://attack.mitre.org/techniques/T1548/001/",
    },
    "sudo": {
        "id": "T1548.003",
        "name": "Abuse Elevation Control Mechanism: Sudo and Sudo Caching",
        "tactic": "Privilege Escalation",
        "sub": "003",
        "url": "https://attack.mitre.org/techniques/T1548/003/",
    },
    "cron": {
        "id": "T1053.003",
        "name": "Scheduled Task/Job: Cron",
        "tactic": "Privilege Escalation",
        "sub": "003",
        "url": "https://attack.mitre.org/techniques/T1053/003/",
    },
    "scheduled task": {
        "id": "T1053.005",
        "name": "Scheduled Task/Job: Scheduled Task",
        "tactic": "Privilege Escalation",
        "sub": "005",
        "url": "https://attack.mitre.org/techniques/T1053/005/",
    },
    "dll hijacking": {
        "id": "T1574.001",
        "name": "Hijack Execution Flow: DLL Search Order Hijacking",
        "tactic": "Privilege Escalation",
        "sub": "001",
        "url": "https://attack.mitre.org/techniques/T1574/001/",
    },
    "path hijacking": {
        "id": "T1574.007",
        "name": "Hijack Execution Flow: Path Interception",
        "tactic": "Privilege Escalation",
        "sub": "007",
        "url": "https://attack.mitre.org/techniques/T1574/007/",
    },
    "token impersonation": {
        "id": "T1134.001",
        "name": "Access Token Manipulation: Token Impersonation/Theft",
        "tactic": "Privilege Escalation",
        "sub": "001",
        "url": "https://attack.mitre.org/techniques/T1134/001/",
    },
    # ── Credential Access ────────────────────────────────────────────────────
    "brute force": {
        "id": "T1110",
        "name": "Brute Force",
        "tactic": "Credential Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1110/",
    },
    "password spraying": {
        "id": "T1110.003",
        "name": "Brute Force: Password Spraying",
        "tactic": "Credential Access",
        "sub": "003",
        "url": "https://attack.mitre.org/techniques/T1110/003/",
    },
    "credential dumping": {
        "id": "T1003",
        "name": "OS Credential Dumping",
        "tactic": "Credential Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1003/",
    },
    "ntlm": {
        "id": "T1003.002",
        "name": "OS Credential Dumping: Security Account Manager",
        "tactic": "Credential Access",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1003/002/",
    },
    "lsass": {
        "id": "T1003.001",
        "name": "OS Credential Dumping: LSASS Memory",
        "tactic": "Credential Access",
        "sub": "001",
        "url": "https://attack.mitre.org/techniques/T1003/001/",
    },
    "kerberoasting": {
        "id": "T1558.003",
        "name": "Steal or Forge Kerberos Tickets: Kerberoasting",
        "tactic": "Credential Access",
        "sub": "003",
        "url": "https://attack.mitre.org/techniques/T1558/003/",
    },
    "as-rep roasting": {
        "id": "T1558.004",
        "name": "Steal or Forge Kerberos Tickets: AS-REP Roasting",
        "tactic": "Credential Access",
        "sub": "004",
        "url": "https://attack.mitre.org/techniques/T1558/004/",
    },
    "asreproasting": {
        "id": "T1558.004",
        "name": "Steal or Forge Kerberos Tickets: AS-REP Roasting",
        "tactic": "Credential Access",
        "sub": "004",
        "url": "https://attack.mitre.org/techniques/T1558/004/",
    },
    "pass the hash": {
        "id": "T1550.002",
        "name": "Use Alternate Authentication Material: Pass the Hash",
        "tactic": "Lateral Movement",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1550/002/",
    },
    "pth": {
        "id": "T1550.002",
        "name": "Use Alternate Authentication Material: Pass the Hash",
        "tactic": "Lateral Movement",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1550/002/",
    },
    # ── Defense Evasion ───────────────────────────────────────────────────────
    "xss": {
        "id": "T1059.007",
        "name": "Command and Scripting Interpreter: JavaScript",
        "tactic": "Execution",
        "sub": "007",
        "url": "https://attack.mitre.org/techniques/T1059/007/",
    },
    "cross-site scripting": {
        "id": "T1059.007",
        "name": "Command and Scripting Interpreter: JavaScript",
        "tactic": "Execution",
        "sub": "007",
        "url": "https://attack.mitre.org/techniques/T1059/007/",
    },
    "csrf": {
        "id": "T1185",
        "name": "Browser Session Hijacking",
        "tactic": "Collection",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1185/",
    },
    "misconfiguration": {
        "id": "T1562.001",
        "name": "Impair Defenses: Disable or Modify Tools",
        "tactic": "Defense Evasion",
        "sub": "001",
        "url": "https://attack.mitre.org/techniques/T1562/001/",
    },
    # ── Discovery ────────────────────────────────────────────────────────────
    "smb enumeration": {
        "id": "T1135",
        "name": "Network Share Discovery",
        "tactic": "Discovery",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1135/",
    },
    "ldap enumeration": {
        "id": "T1087.002",
        "name": "Account Discovery: Domain Account",
        "tactic": "Discovery",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1087/002/",
    },
    "active directory enumeration": {
        "id": "T1087.002",
        "name": "Account Discovery: Domain Account",
        "tactic": "Discovery",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1087/002/",
    },
    "bloodhound": {
        "id": "T1069.002",
        "name": "Permission Groups Discovery: Domain Groups",
        "tactic": "Discovery",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1069/002/",
    },
    # ── Lateral Movement ─────────────────────────────────────────────────────
    "lateral movement": {
        "id": "T1021",
        "name": "Remote Services",
        "tactic": "Lateral Movement",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1021/",
    },
    "smb": {
        "id": "T1021.002",
        "name": "Remote Services: SMB/Windows Admin Shares",
        "tactic": "Lateral Movement",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1021/002/",
    },
    "winrm": {
        "id": "T1021.006",
        "name": "Remote Services: Windows Remote Management",
        "tactic": "Lateral Movement",
        "sub": "006",
        "url": "https://attack.mitre.org/techniques/T1021/006/",
    },
    # ── Exfiltration ─────────────────────────────────────────────────────────
    "exfiltration": {
        "id": "T1041",
        "name": "Exfiltration Over C2 Channel",
        "tactic": "Exfiltration",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1041/",
    },
    "data exfiltration": {
        "id": "T1041",
        "name": "Exfiltration Over C2 Channel",
        "tactic": "Exfiltration",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1041/",
    },
    # ── Impact ───────────────────────────────────────────────────────────────
    "ransomware": {
        "id": "T1486",
        "name": "Data Encrypted for Impact",
        "tactic": "Impact",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1486/",
    },
    "dos": {
        "id": "T1499",
        "name": "Endpoint Denial of Service",
        "tactic": "Impact",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1499/",
    },
    "denial of service": {
        "id": "T1499",
        "name": "Endpoint Denial of Service",
        "tactic": "Impact",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1499/",
    },
    # ── Web Application ──────────────────────────────────────────────────────
    "idor": {
        "id": "T1078",
        "name": "Valid Accounts",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1078/",
    },
    "broken access control": {
        "id": "T1078",
        "name": "Valid Accounts",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1078/",
    },
    "authentication bypass": {
        "id": "T1078",
        "name": "Valid Accounts",
        "tactic": "Initial Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1078/",
    },
    "jwt": {
        "id": "T1539",
        "name": "Steal Web Session Cookie",
        "tactic": "Credential Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1539/",
    },
    "session hijacking": {
        "id": "T1539",
        "name": "Steal Web Session Cookie",
        "tactic": "Credential Access",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1539/",
    },
    "open redirect": {
        "id": "T1566.002",
        "name": "Phishing: Spearphishing Link",
        "tactic": "Initial Access",
        "sub": "002",
        "url": "https://attack.mitre.org/techniques/T1566/002/",
    },
    "information disclosure": {
        "id": "T1592",
        "name": "Gather Victim Host Information",
        "tactic": "Reconnaissance",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1592/",
    },
    "path traversal": {
        "id": "T1083",
        "name": "File and Directory Discovery",
        "tactic": "Discovery",
        "sub": None,
        "url": "https://attack.mitre.org/techniques/T1083/",
    },
}


def find_techniques(query: str) -> list:
    """Busca técnicas ATT&CK que coincidan con el query (fuzzy)."""
    query_lower = query.lower().strip()
    results = []
    seen_ids = set()

    for keyword, technique in TECHNIQUE_DB.items():
        tid = technique["id"]
        if tid in seen_ids:
            continue
        if (
            keyword in query_lower
            or query_lower in keyword
            or any(word in keyword for word in query_lower.split() if len(word) > 3)
        ):
            results.append(technique)
            seen_ids.add(tid)

    return results


def analyze_finding_file(filepath: str) -> list:
    """Lee un finding_*.md y extrae técnicas sugeridas basadas en el contenido."""
    path = Path(filepath)
    if not path.exists():
        print(f"[ERROR] Archivo no encontrado: {filepath}", file=sys.stderr)
        return []

    content = path.read_text(errors="replace").lower()
    results = []
    seen_ids = set()

    for keyword, technique in TECHNIQUE_DB.items():
        tid = technique["id"]
        if tid in seen_ids:
            continue
        if keyword in content:
            results.append(technique)
            seen_ids.add(tid)

    return results


def format_technique(t: dict) -> str:
    """Formatea una técnica para output legible."""
    lines = [
        f"  ID:      {t['id']}",
        f"  Name:    {t['name']}",
        f"  Tactic:  {t['tactic']}",
        f"  URL:     {t['url']}",
    ]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Mapea hallazgos de pentest a técnicas MITRE ATT&CK"
    )
    parser.add_argument(
        "query", nargs="?", help="Término a buscar (ej: 'sql injection', 'rce')"
    )
    parser.add_argument(
        "--finding", help="Archivo finding_*.md para análisis automático"
    )
    parser.add_argument(
        "--list-tactics",
        action="store_true",
        help="Lista todas las tácticas disponibles",
    )
    parser.add_argument("--json", action="store_true", help="Output en formato JSON")

    args = parser.parse_args()

    if args.list_tactics:
        tactics = sorted(set(t["tactic"] for t in TECHNIQUE_DB.values()))
        for tactic in tactics:
            techs = [t for t in TECHNIQUE_DB.values() if t["tactic"] == tactic]
            unique = {t["id"]: t for t in techs}
            print(f"\n[{tactic}]")
            for tid, tech in sorted(unique.items()):
                print(f"  {tid:15} {tech['name']}")
        return

    results = []

    if args.finding:
        results = analyze_finding_file(args.finding)
        source = f"finding: {args.finding}"
    elif args.query:
        results = find_techniques(args.query)
        source = f"query: {args.query}"
    else:
        parser.print_help()
        return

    if not results:
        print(
            f"[MITRE] Sin coincidencias para: {args.query or args.finding}",
            file=sys.stderr,
        )
        sys.exit(1)

    if args.json:
        print(json.dumps(results, indent=2, ensure_ascii=False))
        return

    print(f"\n[MITRE ATT&CK] Tecnicas mapeadas ({source}):\n")
    for i, tech in enumerate(results, 1):
        print(f"  [{i}] {tech['id']} — {tech['name']}")
        print(f"       Tactica: {tech['tactic']}")
        print(f"       Ref:     {tech['url']}")
        print()


if __name__ == "__main__":
    main()
