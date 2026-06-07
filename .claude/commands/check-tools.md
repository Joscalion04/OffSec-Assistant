Verifica qué herramientas de seguridad están instaladas en este sistema (Arch/Manjaro).

Ejecuta `which` para cada herramienta y presenta el resultado en una tabla con tres columnas:
Herramienta | Estado | Instalación (si falta)

Herramientas a verificar:
- Reconocimiento: nmap, masscan, amass, subfinder, theHarvester
- Web: ffuf, nikto, sqlmap, nuclei, whatweb, gobuster
- Explotación: metasploit, searchsploit
- Post-explotación: netcat, socat
- Utilidades: git, python3, pip, curl, wget, jq, whois, dig

Para las que falten, indica el comando exacto de instalación en Arch/Manjaro:
- Primero intenta: `pacman -S <tool>`
- Si no está en repos oficiales: `yay -S <tool>` o `pip install <tool>`

Al finalizar muestra un resumen: X/Y herramientas instaladas.
