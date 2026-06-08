Ejecuta enumeración de Active Directory sobre: $ARGUMENTS

Parsea los argumentos:
- TARGET = primer argumento (IP o hostname del Domain Controller)
- ENGAGEMENT = segundo argumento o engagement activo
- FLAGS adicionales: --user, --pass, --domain, --anon, --bloodhound, --kerberoast, --asreproast

Determina OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}" antes de comenzar.

-- Pre-flight: verificación de scope

1. Verifica que TARGET está en scope.md del engagement activo.
   Si no está: "[ABORTANDO] DC target no encontrado en scope.md — agregar antes de continuar"

2. Verifica herramientas disponibles:
   which enum4linux-ng enum4linux ldapdomaindump bloodhound-python crackmapexec netexec 2>/dev/null
   Advertir si faltan herramientas críticas (enum4linux-ng, ldapdomaindump, impacket).

-- Modo interactivo (sin flags de credenciales)

Si no se pasan --user y --pass:
  Preguntar al operador:
  "Modo de enumeracion AD:
    [1] Anonimo / null session (sin credenciales)
    [2] Autenticado (usuario de dominio comprometido)
    [3] Solo reconocimiento SMB/NetBIOS

  Opciones disponibles para autenticado:
    --user <usuario> --pass <password> --domain <dominio>
    o pass-the-hash: --user <usuario> --hash <NT_hash> --domain <dominio>"

-- Ejecución autónoma

Si se pasan credenciales o --anon:

  1. Informa:
     "Modo AD enum activado para $TARGET
      Live feed: logs/livefeed/FECHA_engagement_ad.log
      Seguir en otra terminal: tail -f <ruta>"

  2. Ejecuta el script:
     OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}"
     bash "$OFFSEC_HOME/tools/run-ad-enum.sh" <engagement> <target> [flags]

  3. Fases que ejecuta el script:
     - Fase 1: Verificacion de puertos AD (88, 389, 445, 636, etc.)
     - Fase 2: SMB / NetBIOS enumeration (enum4linux-ng)
     - Fase 3: LDAP dump completo (ldapdomaindump — requiere credenciales)
     - Fase 4: CME / NetExec fingerprint y signing check
     - Fase 5: BloodHound collection (si --bloodhound)
     - Fase 6: Kerberoasting (si --kerberoast)
     - Fase 7: AS-REP Roasting (si --asreproast)

-- Post-ejecución

Cuando el script termine:

  1. Leer y sanitizar resultados antes de analizar:
     python3 "$OFFSEC_HOME/tools/sanitizer.py" <engagement_dir> <archivo>

  2. Para cada hallazgo crítico (hashes Kerberos, usuarios sin preauth, SMB signing off):
     - Generar finding_ad_NNN.md con CVSS 3.1 y técnica MITRE
     - Usar map-mitre.py para el mapping:
       python3 "$OFFSEC_HOME/tools/map-mitre.py" "kerberoasting"
       python3 "$OFFSEC_HOME/tools/map-mitre.py" "active directory enumeration"

  3. Presentar resumen de hallazgos:
     "AD Enumeration completado.
      DC: [token] | Dominio: [token]
      Usuarios encontrados: N
      Kerberoastable accounts: N
      AS-REP Roastable: N
      SMB Signing: [enabled/disabled]
      Attack paths identificados: [lista]"

-- Interpretación de resultados clave

Si SMB Signing = disabled:
  "[CRIT] SMB Signing deshabilitado — vulnerable a NTLM Relay attacks"
  Sugerir: ntlmrelayx.py + responder

Si hay cuentas Kerberoastable:
  "[CRIT] Cuentas con SPN — intentar crackeo offline con hashcat"
  Sugerir: hashcat -m 13100 <hashes> /usr/share/wordlists/rockyou.txt

Si hay cuentas AS-REP Roastable:
  "[CRIT] Cuentas sin pre-autenticacion Kerberos"
  Sugerir: hashcat -m 18200 <hashes> /usr/share/wordlists/rockyou.txt

Si BloodHound data disponible:
  "[FIND] ZIP de BloodHound generado — importar en GUI para visualizar attack paths"
  Mencionar queries útiles: "Shortest Paths to Domain Admin", "Kerberoastable Users"

-- Siguiente paso sugerido

Basado en hallazgos, sugerir:
  - Si hay hashes: /think "tengo hashes Kerberos — cuál es el mejor approach para crack?"
  - Si hay BloodHound data: "Importar ZIP en BloodHound GUI y analizar attack paths"
  - Si SMB signing off: sugerir NTLM relay en siguiente fase de explotación
