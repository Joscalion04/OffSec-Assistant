Integración con Burp Suite Professional API: $ARGUMENTS

Parsea los argumentos:
- SUBCOMANDO = status | scan | list | results | findings
- TARGET_URL = URL a escanear (para subcomando scan)
- SCAN_ID = ID de scan previo (para subcomando results/findings)
- ENGAGEMENT = nombre del engagement (para subcomando findings)

Determina OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}" antes de comenzar.

-- Prerequisitos

Burp Suite Professional debe estar corriendo con la REST API habilitada:
  - Project > Extensions > APIs > Enable REST API
  - Puerto por defecto: 1337
  - API Key: visible en User Options > Suite > REST API

Variables de entorno necesarias (o pasar como flags):
  BURP_HOST (default: 127.0.0.1)
  BURP_PORT (default: 1337)
  BURP_API_KEY (requerida)

-- Subcomandos disponibles

status — Verifica conectividad con Burp:
  python3 "$OFFSEC_HOME/tools/burp-api.py" status

list — Lista todos los scans activos/completados:
  python3 "$OFFSEC_HOME/tools/burp-api.py" list

scan <url> — Inicia un scan activo:
  VERIFICAR PRIMERO que <url> está en scope.md del engagement activo.
  Si no está en scope: "[ABORTANDO] URL no está en scope.md"
  Si está en scope:
    python3 "$OFFSEC_HOME/tools/burp-api.py" scan <url>
  El comando retorna un SCAN_ID para monitorear el progreso.

results <scan_id> — Estado y estadísticas de un scan:
  python3 "$OFFSEC_HOME/tools/burp-api.py" results <scan_id>
  Mostrar progreso, cantidad de requests y distribución de hallazgos por severidad.

findings <scan_id> <engagement> — Exportar hallazgos como findings:
  ENGAGEMENT_DIR=$(ls -d $OFFSEC_HOME/findings/????-??-??_${engagement}* | head -1)
  python3 "$OFFSEC_HOME/tools/burp-api.py" findings <scan_id> "$ENGAGEMENT_DIR"
  Los findings se generan en $ENGAGEMENT_DIR/vulns/finding_burp_*.md

-- Flujo típico de uso

1. Verificar conectividad:
   /burp-scan status

2. Iniciar scan (URL debe estar en scope):
   /burp-scan scan https://target.example.com

3. Monitorear progreso (ejecutar cada N minutos):
   /burp-scan results <scan_id>

4. Cuando el scan completa (status: succeeded), exportar hallazgos:
   /burp-scan findings <scan_id> <engagement>

-- Post-exportación

Cuando los findings estén generados en vulns/finding_burp_*.md:

1. Para cada finding exportado, agregar mapeo MITRE preciso:
   python3 "$OFFSEC_HOME/tools/map-mitre.py" "<nombre_del_issue_burp>"

2. Revisar si las rutas/URLs en los findings tienen datos reales que sanitizar:
   python3 "$OFFSEC_HOME/tools/sanitizer.py" "$ENGAGEMENT_DIR" "$finding_file"

3. Actualizar context.md del engagement con los hallazgos Burp:
   Agregar bajo "Hallazgos web" los issues críticos encontrados.

4. Presentar resumen:
   "Burp scan completado.
    Scan ID: <id>
    Hallazgos exportados: N
    Critical: N | High: N | Medium: N | Low: N
    Findings en: $ENGAGEMENT_DIR/vulns/finding_burp_*.md"

-- Configuración de scan recomendada

Para engagements de black-box/gray-box:
  Configuración: "Crawl and Audit - Fast" (default)

Para engagements más exhaustivos:
  Configuración: "Crawl and Audit - Thorough"
  Advertir: puede tardar varias horas y generar ruido significativo en logs del target.

-- Si Burp no está disponible

Si el status falla o BURP_API_KEY no está seteada:
  "Burp Suite Professional no detectado.
   
   Alternativas disponibles para web scanning:
   - nuclei: /vuln-scan <target> -auto (incluye nuclei)
   - nikto: nikto -h <target> -output $ENGAGEMENT_DIR/vulns/nikto.txt
   - sqlmap: para SQL injection específica"
