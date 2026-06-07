Inicializa un nuevo engagement de pentesting llamado: $ARGUMENTS

Pasos a ejecutar:

1. Define variables:
   - ENGAGEMENT_NAME="$ARGUMENTS" (sin espacios, usar guiones)
   - ENGAGEMENT_DATE=$(date +%Y-%m-%d)
   - ENGAGEMENT_DIR="/home/joseph/Documents/OffSec/OffSec-Assistant/findings/${ENGAGEMENT_DATE}_${ENGAGEMENT_NAME}"

2. Crea estructura de carpetas:
   mkdir -p $ENGAGEMENT_DIR/{recon,vulns,exploitation,post-exploitation,evidence,notes}
   mkdir -p $ENGAGEMENT_DIR/evidence/{screenshots,captures,files}

3. Copia plantillas:
   - templates/scope.md → $ENGAGEMENT_DIR/scope.md
   - templates/finding.md → $ENGAGEMENT_DIR/finding_template.md
   - templates/context.md → $ENGAGEMENT_DIR/context.md

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
   echo "*.pcap\n*.cap\nevidence/files/*\n*.log" > .gitignore
   git add .
   git commit -m "chore: init engagement $ENGAGEMENT_NAME"

7. Muestra estructura creada con: find $ENGAGEMENT_DIR -type f | sort

8. Mensaje final:
   "✅ Engagement '$ENGAGEMENT_NAME' inicializado.
   
   Próximos pasos:
   1. Edita scope.md y completa los targets autorizados
   2. Ejecuta /check-tools para verificar herramientas disponibles
   3. Cuando el scope esté listo, ejecuta /recon <target>"
