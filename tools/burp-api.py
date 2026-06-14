#!/usr/bin/env python3
"""
burp-api.py — Cliente para Burp Suite Professional REST API

Requisito: Burp Suite Professional con REST API habilitada.
  - Habilitar en: Project > Extensions > APIs > Enable REST API
  - Puerto por defecto: 1337
  - API Key: visible en User Options > Suite > REST API

Uso:
  python3 burp-api.py --host 127.0.0.1 --port 1337 --key <API_KEY> status
  python3 burp-api.py --host 127.0.0.1 --port 1337 --key <API_KEY> scan <url>
  python3 burp-api.py --host 127.0.0.1 --port 1337 --key <API_KEY> results <scan_id>
  python3 burp-api.py --host 127.0.0.1 --port 1337 --key <API_KEY> findings <scan_id> <engagement_dir>

Comandos:
  status                  Verifica conectividad con Burp
  scan <url>              Inicia un scan activo contra <url>
  list                    Lista todos los scans activos/completados
  results <scan_id>       Muestra estado y estadisticas del scan
  findings <id> <dir>     Exporta hallazgos como finding_*.md al engagement

Variables de entorno (alternativa a flags):
  BURP_HOST, BURP_PORT, BURP_API_KEY
"""

import sys
import os
import json
import argparse
import urllib.request
import urllib.error
import urllib.parse
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Cliente HTTP mínimo (sin dependencias externas)
# ---------------------------------------------------------------------------


class BurpClient:
    def __init__(self, host: str, port: int, api_key: str):
        self.base_url = f"http://{host}:{port}/v0.1"
        self.api_key = api_key
        self.headers = {
            "Authorization": f"Token {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    def _request(self, method: str, path: str, body: dict = None) -> dict:
        url = f"{self.base_url}{path}"
        data = json.dumps(body).encode() if body else None

        req = urllib.request.Request(
            url, data=data, headers=self.headers, method=method
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                raw = resp.read().decode()
                return json.loads(raw) if raw.strip() else {}
        except urllib.error.HTTPError as e:
            body_text = e.read().decode(errors="replace") if e.fp else ""
            raise RuntimeError(f"HTTP {e.code} — {e.reason}: {body_text[:300]}")
        except urllib.error.URLError as e:
            raise RuntimeError(f"Conexion fallida ({url}): {e.reason}")

    def get(self, path: str) -> dict:
        return self._request("GET", path)

    def post(self, path: str, body: dict) -> dict:
        return self._request("POST", path, body)

    def delete(self, path: str) -> dict:
        return self._request("DELETE", path)


# ---------------------------------------------------------------------------
# Acciones
# ---------------------------------------------------------------------------


def cmd_status(client: BurpClient):
    """Verifica que Burp está corriendo y la API responde."""
    try:
        resp = client.get("/")
        print("[BURP] Conexion OK")
        if resp:
            print(f"  Version: {resp.get('burp_version', 'desconocida')}")
            print(f"  Tipo:    {resp.get('license', 'desconocido')}")
    except RuntimeError as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)


def cmd_scan(client: BurpClient, target_url: str, config: dict = None) -> str:
    """Inicia un scan activo. Retorna el ID del scan."""
    payload = {
        "urls": [target_url],
        "scan_configurations": config or [{"name": "Crawl and Audit - Fast"}],
    }
    try:
        resp = client.post("/scan", payload)
        # Burp retorna el Location header con el ID, o lo incluye en el body
        scan_id = resp.get("id") or resp.get("task_id", "desconocido")
        print("[BURP] Scan iniciado")
        print(f"  URL:     {target_url}")
        print(f"  Scan ID: {scan_id}")
        print(f"  Monitorear con: burp-api.py results {scan_id}")
        return str(scan_id)
    except RuntimeError as e:
        print(f"[ERROR] No se pudo iniciar el scan: {e}", file=sys.stderr)
        sys.exit(1)


def cmd_list(client: BurpClient):
    """Lista todos los scans."""
    try:
        resp = client.get("/scan")
        scans = resp if isinstance(resp, list) else resp.get("scans", [])
        if not scans:
            print("[BURP] No hay scans activos o completados.")
            return
        print(f"\n[BURP] Scans ({len(scans)} total):\n")
        for s in scans:
            sid = s.get("id", "?")
            status = s.get("scan_status", "?")
            urls = s.get("urls", [])
            url_str = urls[0] if urls else "?"
            progress = s.get("scan_progress", {})
            pct = progress.get("audit_request_count", "?")
            print(f"  [{sid}] {status:15} {url_str} (requests: {pct})")
    except RuntimeError as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)


def cmd_results(client: BurpClient, scan_id: str):
    """Muestra estado y estadísticas de un scan."""
    try:
        resp = client.get(f"/scan/{scan_id}")
        status = resp.get("scan_status", "desconocido")
        urls = resp.get("urls", [])
        progress = resp.get("scan_progress", {})
        issue_counts = resp.get("issue_events", [])

        print(f"\n[BURP] Scan {scan_id}")
        print(f"  Estado:    {status}")
        print(f"  URLs:      {', '.join(urls)}")
        print(f"  Requests:  {progress.get('audit_request_count', '?')}")
        print(f"  Issues:    {len(issue_counts)}")

        if issue_counts:
            # Conteo por severidad
            severity_counts = {}
            for evt in issue_counts:
                sev = evt.get("issue", {}).get("severity", "unknown")
                severity_counts[sev] = severity_counts.get(sev, 0) + 1
            print("\n  Distribucion por severidad:")
            for sev, count in sorted(severity_counts.items()):
                print(f"    {sev:10}: {count}")

    except RuntimeError as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)


BURP_SEVERITY_MAP = {
    "high": "High",
    "medium": "Medium",
    "low": "Low",
    "informational": "Info",
    "info": "Info",
}

BURP_CVSS_ESTIMATE = {
    "High": "7.5",
    "Medium": "5.0",
    "Low": "3.0",
    "Info": "1.0",
}

BURP_MITRE_MAP = {
    "SQL injection": "T1190 — Exploit Public-Facing Application",
    "Cross-site scripting": "T1059.007 — JavaScript execution",
    "XML injection": "T1190 — Exploit Public-Facing Application",
    "OS command injection": "T1059 — Command and Scripting Interpreter",
    "Path traversal": "T1083 — File and Directory Discovery",
    "SSRF": "T1190 — Exploit Public-Facing Application",
    "CSRF": "T1185 — Browser Session Hijacking",
    "Clickjacking": "T1185 — Browser Session Hijacking",
    "Open redirect": "T1566.002 — Phishing: Spearphishing Link",
    "Information disclosure": "T1592 — Gather Victim Host Information",
    "Authentication": "T1078 — Valid Accounts",
    "Access control": "T1078 — Valid Accounts",
    "File upload": "T1190 — Exploit Public-Facing Application",
    "Deserialization": "T1190 — Exploit Public-Facing Application",
}


def _guess_mitre(issue_name: str) -> str:
    """Mapea nombre de issue Burp a técnica ATT&CK."""
    for key, technique in BURP_MITRE_MAP.items():
        if key.lower() in issue_name.lower():
            return technique
    return "T1190 — Exploit Public-Facing Application"


def cmd_findings(client: BurpClient, scan_id: str, engagement_dir: str):
    """Exporta hallazgos del scan como finding_*.md al directorio del engagement."""
    eng_path = Path(engagement_dir)
    vulns_dir = eng_path / "vulns"
    vulns_dir.mkdir(parents=True, exist_ok=True)

    try:
        resp = client.get(f"/scan/{scan_id}")
        issue_events = resp.get("issue_events", [])

        if not issue_events:
            print(f"[BURP] Sin hallazgos en el scan {scan_id}")
            return

        # Agrupar por tipo de issue para evitar duplicados
        issues_by_type = {}
        for evt in issue_events:
            issue = evt.get("issue", {})
            issue_type = issue.get("type_index", "unknown")
            if issue_type not in issues_by_type:
                issues_by_type[issue_type] = {
                    "issue": issue,
                    "count": 0,
                    "instances": [],
                }
            issues_by_type[issue_type]["count"] += 1
            issues_by_type[issue_type]["instances"].append(
                {
                    "url": issue.get("origin", "?"),
                    "path": issue.get("path", "?"),
                    "evidence": issue.get("evidence", []),
                }
            )

        generated = []
        now = datetime.now().strftime("%Y-%m-%d %H:%M")

        for i, (type_idx, data) in enumerate(issues_by_type.items(), 1):
            issue = data["issue"]
            name = issue.get("name", "Unknown Issue")
            severity_raw = issue.get("severity", "info")
            severity = BURP_SEVERITY_MAP.get(severity_raw.lower(), "Info")
            cvss = BURP_CVSS_ESTIMATE[severity]
            confidence = issue.get("confidence", "tentative")
            description = issue.get(
                "issue_background", "Ver Burp Suite para detalle completo."
            )
            remediation = issue.get(
                "remediation_background", "Ver Burp Suite para recomendaciones."
            )
            mitre = _guess_mitre(name)

            # Instancias (sanitizadas — sin datos reales, solo estructura)
            instance_lines = []
            for inst in data["instances"][:5]:
                instance_lines.append(f"  - {inst['path']}")

            finding_content = f"""# FIND-BURP-{i:03d} — {name}

**Fecha:** {now}
**Herramienta:** Burp Suite Professional
**Scan ID:** {scan_id}
**Severidad:** {severity}
**CVSS 3.1:** {cvss} (estimado — ajustar con vector completo)
**Confianza:** {confidence}
**MITRE ATT&CK:** {mitre}
**Instancias:** {data['count']}

---

## Descripcion

{description}

---

## Instancias Detectadas

(Rutas del target — verificar contra mapa DLP antes de incluir en reporte)
{chr(10).join(instance_lines)}

---

## Evidencia

Ver Burp Suite Project > {scan_id} > Issue {type_idx} para evidencia raw.
Exportar screenshots relevantes a evidence/screenshots/.

---

## Remediacion

{remediation}

---

## Referencias

- OWASP: https://owasp.org/www-project-top-ten/
- CWE mapping: ver Burp issue definition para tipo {type_idx}
"""

            out_file = vulns_dir / f"finding_burp_{i:03d}.md"
            out_file.write_text(finding_content)
            generated.append((str(out_file), name, severity))

        print(f"\n[BURP] Findings generados: {len(generated)}")
        for path, name, sev in generated:
            print(f"  [{sev:8}] {name}")
            print(f"           {path}")

    except RuntimeError as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)


# ---------------------------------------------------------------------------
# CLI principal
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="Cliente CLI para Burp Suite Professional REST API"
    )
    parser.add_argument("--host", default=os.environ.get("BURP_HOST", "127.0.0.1"))
    parser.add_argument(
        "--port", type=int, default=int(os.environ.get("BURP_PORT", "1337"))
    )
    parser.add_argument(
        "--key",
        default=os.environ.get("BURP_API_KEY", ""),
        help="Burp API Key (o BURP_API_KEY env var)",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("status", help="Verifica conectividad con Burp")

    scan_p = subparsers.add_parser("scan", help="Inicia un scan activo")
    scan_p.add_argument("url", help="URL a escanear")

    subparsers.add_parser("list", help="Lista todos los scans")

    results_p = subparsers.add_parser("results", help="Estado de un scan")
    results_p.add_argument("scan_id", help="ID del scan")

    findings_p = subparsers.add_parser("findings", help="Exporta findings a engagement")
    findings_p.add_argument("scan_id", help="ID del scan")
    findings_p.add_argument("engagement_dir", help="Directorio del engagement")

    args = parser.parse_args()

    if not args.key and args.command != "status":
        print("[ERROR] Se requiere BURP_API_KEY o --key", file=sys.stderr)
        sys.exit(1)

    client = BurpClient(args.host, args.port, args.key)

    if args.command == "status":
        cmd_status(client)
    elif args.command == "scan":
        cmd_scan(client, args.url)
    elif args.command == "list":
        cmd_list(client)
    elif args.command == "results":
        cmd_results(client, args.scan_id)
    elif args.command == "findings":
        cmd_findings(client, args.scan_id, args.engagement_dir)


if __name__ == "__main__":
    main()
