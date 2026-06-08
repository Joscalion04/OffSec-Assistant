Inicializa un nuevo engagement de pentesting llamado: $ARGUMENTS

Pasos a ejecutar:

1. Define variables:
   - ENGAGEMENT_NAME="$ARGUMENTS" (sin espacios, usar guiones)
   - ENGAGEMENT_DATE=$(date +%Y-%m-%d)
   - OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}"
   - ENGAGEMENT_DIR="$OFFSEC_HOME/findings/${ENGAGEMENT_DATE}_${ENGAGEMENT_NAME}"

2. Crea estructura de carpetas:
   mkdir -p $ENGAGEMENT_DIR/{recon,vulns,exploitation,post-exploitation,evidence,notes}
   mkdir -p $ENGAGEMENT_DIR/evidence/{screenshots,captures,files}

3. Copia plantillas:
   - $OFFSEC_HOME/templates/scope.md → $ENGAGEMENT_DIR/scope.md
   - $OFFSEC_HOME/templates/finding.md → $ENGAGEMENT_DIR/finding_template.md
   - $OFFSEC_HOME/templates/context.md → $ENGAGEMENT_DIR/context.md

4. Personaliza context.md recién copiado:
   - Reemplaza [NOMBRE_ENGAGEMENT] con $ENGAGEMENT_NAME
   - Establece "Fase actual: Reconocimiento"
   - Establece "Última actualización" con fecha y hora actual
   - Establece "Progreso general: 0%"

5. Crea notes/session_log.md con header:
   # Session Log — $ENGAGEMENT_NAME
   ## [FECHA] — Sesión 1: Inicio del engagement

6. Inicializa git:
   cd $ENGAGEMENT_DIR
   git init
   echo "*.pcap\n*.cap\nevidence/files/*\n*.log\ndlp-map.json" > .gitignore
   git add .
   git commit -m "chore: init engagement $ENGAGEMENT_NAME"

7. Inicializa el mapa DLP (ejecutar DESPUÉS de que el operador complete scope.md):
   Nota: este paso se realiza cuando scope.md ya tenga los targets reales.
   El operador debe editar scope.md primero y luego ejecutar:
   python3 "$OFFSEC_HOME/tools/sanitizer.py" "$ENGAGEMENT_DIR" --init
   Esto registra todos los IPs, hostnames y email del cliente en el mapa DLP
   para que el agente nunca los vea en formato crudo.

8. Muestra estructura creada con: find $ENGAGEMENT_DIR -type f | sort

9. Mensaje final:
   "Engagement '$ENGAGEMENT_NAME' inicializado.

   Proximos pasos:
   1. Edita scope.md con los targets autorizados (OBLIGATORIO antes de cualquier scan)
   2. Ejecuta el init del mapa DLP para proteger datos del cliente:
      python3 $OFFSEC_HOME/tools/sanitizer.py $ENGAGEMENT_DIR --init
   3. Ejecuta /check-tools para verificar herramientas disponibles
   4. Cuando el scope este listo: /recon <target>"
