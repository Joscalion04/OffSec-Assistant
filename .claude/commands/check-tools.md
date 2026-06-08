Verifica qué herramientas de seguridad están instaladas en este sistema (Arch/Manjaro).

Determina OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}" antes de comenzar.

Ejecuta `which` para cada herramienta y presenta el resultado en una tabla:
Herramienta | Estado | Instalación (si falta)

Herramientas a verificar por categoria:

- Reconocimiento: nmap, masscan, amass, subfinder, theHarvester
- Web: ffuf, nikto, sqlmap, nuclei, whatweb, gobuster
- Active Directory: enum4linux-ng, enum4linux, ldapdomaindump, bloodhound-python, crackmapexec, netexec
- Impacket (AD): GetUserSPNs.py, GetNPUsers.py, secretsdump.py
- Explotacion: metasploit, searchsploit
- Post-explotacion: netcat, socat, linpeas, winpeas
- Utilidades: git, curl, wget, jq, whois, dig

Para las que falten, indica el comando exacto de instalacion en Arch/Manjaro:
- Primero intenta: `pacman -S <tool>`
- Si no esta en repos oficiales: `yay -S <tool>` o `pip install <tool>`
- Herramientas AD via pip: pip install impacket ldapdomaindump bloodhound netexec enum4linux-ng

Tambien verificar herramientas del proyecto:
- test -f "$OFFSEC_HOME/tools/map-mitre.py" && echo "MITRE mapper: OK" || echo "MITRE mapper: FALTA"
- test -f "$OFFSEC_HOME/tools/parse-privesc.py" && echo "Privesc parser: OK" || echo "Privesc parser: FALTA"
- test -f "$OFFSEC_HOME/tools/burp-api.py" && echo "Burp API client: OK" || echo "Burp API client: FALTA"
- test -f "$OFFSEC_HOME/tools/run-ad-enum.sh" && echo "AD enum script: OK" || echo "AD enum script: FALTA"

Ademas, verifica el sistema DLP del proyecto ejecutando estos checks:

1. Version de Python:
   python3 --version
   Requerido: >= 3.8. Si la version es menor, advertir que el sanitizador DLP no funcionara.

2. Sanitizador DLP:
   test -f "$OFFSEC_HOME/tools/sanitizer.py" && echo "OK" || echo "FALTA"
   Si falta: el archivo tools/sanitizer.py no esta presente — clonar el proyecto correctamente.

3. Verificacion funcional del sanitizador:
   python3 "$OFFSEC_HOME/tools/sanitizer.py" /tmp --init 2>&1 | head -1
   Resultado esperado: linea que contiene "[DLP]". Si falla, reportar el error.

Al finalizar muestra dos resumenes:

Resumen 1 — Herramientas: X/Y instaladas
Resumen 2 — DLP: sistema [operativo | degradado | no disponible]
  - operativo: python3 >= 3.8 y sanitizer.py presente y funcional
  - degradado: python3 disponible pero version < 3.8, o sanitizer.py falta
  - no disponible: python3 no instalado
