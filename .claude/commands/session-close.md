Cierra la sesión de trabajo activa. Argumento opcional: nombre del engagement.

Determina OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}" antes de comenzar.

-- Paso 1: Identificar engagement a cerrar

Si se especificó $ARGUMENTS:
  ENGAGEMENT_DIR=$(ls -d $OFFSEC_HOME/findings/????-??-??_$ARGUMENTS* 2>/dev/null | head -1)
  Si no se encuentra: "[ERROR] Engagement '$ARGUMENTS' no encontrado en findings/"

Si no se especificó argumento:
  Listar todos los engagements con actividad hoy:
    ls -dt $OFFSEC_HOME/findings/????-??-??_* 2>/dev/null
  Si hay más de uno, preguntar cuál cerrar.
  Si hay exactamente uno, proceder con ese.

-- Paso 2: Recopilar actividad de la sesión

  a) Leer context.md del engagement para saber el estado actual.
     (No sanitizar — context.md ya usa tokens DLP)

  b) Leer el log de sesión de hoy:
     LOG_FILE="$OFFSEC_HOME/logs/session_$(date +%Y-%m-%d).log"
     Si existe:
       python3 "$OFFSEC_HOME/tools/sanitizer.py" "$ENGAGEMENT_DIR" "$LOG_FILE"
     Si no existe: advertir que el logger puede no estar configurado como hook.

  c) Listar findings del engagement que no tengan sección de remediación:
     grep -l "PENDIENTE" $ENGAGEMENT_DIR/finding_*.md 2>/dev/null

-- Paso 3: Generar resumen de sesión

Construir y mostrar:

---
## Resumen de sesion — $(date +%Y-%m-%d) — [NOMBRE ENGAGEMENT]

- Duracion estimada: [derivado de primer y ultimo timestamp del log]
- Fase trabajada: [de context.md]
- Progreso: [X% anterior] → [X% actual estimado]
- Comandos ejecutados: [contar entradas CMD del log]
- Hallazgos documentados hoy: [contar finding_*.md modificados hoy]
- Findings incompletos: [lista finding_*.md con PENDIENTE, si hay]

Resumen de actividad:
  [2-4 lineas describiendo qué se hizo: herramientas corridas, vectores probados, hallazgos clave]

Pendientes para proxima sesion:
  - [ ] [derivado de context.md + hallazgos sin remediacion]
  - [ ] [siguiente paso logico de la fase actual]
---

-- Paso 4: Actualizar context.md

Editar $ENGAGEMENT_DIR/context.md:
  - Actualizar campo "Ultima actualizacion" con fecha y hora actual
  - Mover items completados de "Pendientes" a "Completado en esta sesion"
  - Agregar nuevos pendientes identificados en el resumen
  - Actualizar "Progreso general" si corresponde

-- Paso 5: Commit de cierre de sesión

  cd "$ENGAGEMENT_DIR"
  git add .
  git commit -m "session: $(date +%Y-%m-%d) — [resumen de una línea de lo trabajado]"

Si el commit falla porque no hay cambios: indicar "Sin cambios para commitear".
Si git no está inicializado: advertir y no intentar commit.

-- Paso 6: Confirmación final

Mostrar:

"Sesion cerrada correctamente.

Engagement: [nombre]
Commit: [hash corto del commit]
Proxima sesion recomendada: [UN paso concreto y específico]
Comando sugerido: /[comando] [argumento]"
