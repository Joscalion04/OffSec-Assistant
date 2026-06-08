Muestra cómo seguir el live feed de la ejecución autónoma actual.

Determina OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}" y busca el archivo de livefeed
más reciente en $OFFSEC_HOME/logs/livefeed/. Luego muestra:

"Para seguir el live feed en tiempo real, abre otra terminal y ejecuta:

  tail -f $OFFSEC_HOME/logs/livefeed/<archivo_mas_reciente>.log

O para ver todos los livefeeds disponibles:
  ls -lt $OFFSEC_HOME/logs/livefeed/

Leyenda de prefijos:
  [START]   — comando iniciado
  [DONE]    — comando completado sin errores
  [FIND]    — hallazgo menor o advertencia
  [CRIT]    — hallazgo critico — atención inmediata
  [THINK]   — decision tomada por el agente
  [SKIP]    — herramienta no disponible, paso omitido
  [PHASE]   — inicio de nueva fase
  [PLAN]    — plan de ejecucion
  [CONF]    — requiere confirmacion del operador
  [SUM]     — resumen final"
