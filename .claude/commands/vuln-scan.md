Ejecuta análisis de vulnerabilidades sobre: $ARGUMENTS

Parsea los argumentos:
- TARGET = primer argumento
- AUTO_MODE = true si se incluye "-auto", false si no

Si AUTO_MODE es false:
  Analiza resultados de recon existentes y pregunta antes de ejecutar cada herramienta.

Si AUTO_MODE es true:
  1. Verifica que TARGET está en scope.md del engagement activo
  2. Verifica que existe recon previo en findings/<engagement>/recon/
     Si no hay recon: "[!] No hay recon previo — ejecutar /recon $TARGET -auto primero?"
  3. Informa:
     "Modo autónomo activado para vuln-scan en $TARGET
      Live feed: logs/livefeed/FECHA_engagement_vulnscan.log
      Seguir en otra terminal: tail -f <ruta>"
  4. Ejecuta:
     OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}"
     bash "$OFFSEC_HOME/tools/run-vuln-scan.sh" <engagement> $TARGET
  5. Al terminar, parsea los resultados, pre-llena findings usando el agente doc-writer
  6. Presenta hallazgos ordenados por severidad y sugiere próximos pasos
