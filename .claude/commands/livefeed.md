Muestra cómo seguir el live feed de la ejecución autónoma actual.

Busca el archivo de livefeed más reciente en logs/livefeed/ y muestra:

"📡 Para seguir el live feed en tiempo real, abre otra terminal y ejecuta:

  tail -f /home/joseph/Documents/OffSec/OffSec-Assistant/logs/livefeed/<archivo_mas_reciente>.log

O para ver todos los livefeeds disponibles:
  ls -lt /home/joseph/Documents/OffSec/OffSec-Assistant/logs/livefeed/

Leyenda de iconos:
  🔍 START    — comando iniciado
  ✅ DONE     — comando completado sin errores
  ⚠️  FIND     — hallazgo menor o advertencia
  🔴 CRITICAL — hallazgo crítico — atención inmediata
  🧠 THINK    — decisión tomada por el agente
  ⏭️  SKIP     — herramienta no disponible, paso omitido
  📍 PHASE    — inicio de nueva fase
  📋 PLAN     — plan de ejecución
  🛑 CONFIRM  — requiere confirmación del operador
  📊 SUMMARY  — resumen final"
