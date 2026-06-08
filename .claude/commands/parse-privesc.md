Parsea el output de linPEAS o winPEAS: $ARGUMENTS

Parsea los argumentos:
- ENGAGEMENT = primer argumento (nombre del engagement)
- OUTPUT_FILE = segundo argumento (ruta al archivo de output de linPEAS/winPEAS)

Determina OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}" antes de comenzar.

-- Pre-flight

1. Verificar que el engagement existe:
   ENGAGEMENT_DIR=$(ls -d $OFFSEC_HOME/findings/????-??-??_${ENGAGEMENT}* 2>/dev/null | head -1)
   Si no existe: "[ERROR] Engagement no encontrado"

2. Verificar que el archivo de output existe:
   Si no existe: "[ERROR] Archivo no encontrado: $OUTPUT_FILE"

-- Ejecución del parser

El archivo de output puede ser raw (con códigos ANSI) o limpio.
El parser detecta automáticamente si es linPEAS o winPEAS.

Paso 1 — Sanitizar el output antes de procesar:
  python3 "$OFFSEC_HOME/tools/sanitizer.py" "$ENGAGEMENT_DIR" "$OUTPUT_FILE" > /tmp/privesc_sanitized.txt

Paso 2 — Ejecutar el parser:
  python3 "$OFFSEC_HOME/tools/parse-privesc.py" "$ENGAGEMENT_DIR" "$OUTPUT_FILE"

Paso 3 — Generar finding automático:
  python3 "$OFFSEC_HOME/tools/parse-privesc.py" "$ENGAGEMENT_DIR" "$OUTPUT_FILE" --finding

El finding se guarda en: $ENGAGEMENT_DIR/post-exploitation/finding_privesc.md

-- Post-parsing

1. Leer el finding generado (ya tiene tokens DLP por construcción):
   cat "$ENGAGEMENT_DIR/post-exploitation/finding_privesc.md"

2. Mapear técnicas MITRE para los vectores encontrados:
   python3 "$OFFSEC_HOME/tools/map-mitre.py" "privilege escalation"
   python3 "$OFFSEC_HOME/tools/map-mitre.py" "suid" (si aplica)
   python3 "$OFFSEC_HOME/tools/map-mitre.py" "sudo" (si aplica)

3. Presentar resumen al operador:
   "linPEAS/winPEAS parseado.
    Herramienta: [linPEAS | winPEAS]
    Severidad estimada: [Critical | High | Medium | Low]
    
    Vectores identificados:
    - SUID binaries: N → verificar en GTFOBins
    - Sudo misconfig: N → explotar con sudo -l
    - Cron jobs: N → verificar permisos de script
    - Credenciales: N → rotar y usar en lateral movement
    - Kernel version: X.X.X → searchsploit linux kernel X.X"

4. Sugerir siguiente paso:
   - Si hay credenciales: "Registrar en dlp-map y probar en otros hosts del scope"
   - Si hay SUID exploitable: "Consultar GTFOBins para vector específico"
   - Si hay kernel exploit: "searchsploit linux kernel <version>"
   - Si hay sudo misconfig: "Explotar con técnica apropiada según binario permitido"

-- Uso directo sin engagement (análisis rápido)

Si se llama solo con un archivo (sin engagement):
  python3 "$OFFSEC_HOME/tools/parse-privesc.py" /tmp "$OUTPUT_FILE"
  El output va a stdout sin generar finding ni aplicar DLP.
