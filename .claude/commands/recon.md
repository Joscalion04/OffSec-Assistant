Ejecuta reconocimiento sobre: $ARGUMENTS

Parsea los argumentos:
- TARGET = primer argumento (IP o dominio)
- AUTO_MODE = true si se incluye "-auto", false si no

Si AUTO_MODE es false:
  Ejecuta reconocimiento interactivo preguntando antes de cada fase.
  Muestra resultados parciales y espera confirmación para continuar.

Si AUTO_MODE es true:
  1. Verifica que TARGET está en scope.md del engagement activo.
     Si no está, detente con: "⛔ Target no encontrado en scope.md — abortando"
  2. Identifica el nombre del engagement activo (carpeta más reciente en findings/)
  3. Informa al usuario:
     "🚀 Modo autónomo activado para $TARGET
      Live feed en terminal + archivo: logs/livefeed/FECHA_engagement_recon.log
      Para seguir en otra terminal: tail -f logs/livefeed/FECHA_engagement_recon.log"
  4. Ejecuta el script:
     bash /home/joseph/Documents/OffSec/OffSec-Assistant/tools/run-recon.sh <engagement> $TARGET
  5. Cuando el script termine, lee los resultados y actualiza context.md del engagement
  6. Presenta un resumen de hallazgos y sugiere el próximo comando
