Genera el briefing de inicio de día para todos los engagements activos.

Determina OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}" antes de comenzar.

-- Paso 1: Descubrir engagements activos

Ejecuta:
  ls -dt $OFFSEC_HOME/findings/????-??-??_* 2>/dev/null

Un engagement se considera activo si tiene scope.md y context.md.
Si no hay engagements, responde:
  "No hay engagements activos. Para iniciar uno: /new-engagement <nombre>"
y detente.

-- Paso 2: Para cada engagement activo, recopilar estado

Por cada directorio encontrado:

  a) Leer context.md (ya debe estar con tokens DLP — leer directo):
     Extraer: fase actual, progreso %, pendientes, última actualización

  b) Leer scope.md para obtener:
     - Nombre del cliente / organización (usa token ORG-NNN si aparece)
     - Deadline declarado
     - Tipo de prueba (black-box, gray-box, white-box)

  c) Leer el log de sesión más reciente:
     ls -t $OFFSEC_HOME/logs/session_*.log 2>/dev/null | head -1
     Si existe, sanitizar antes de leer:
       python3 "$OFFSEC_HOME/tools/sanitizer.py" <engagement_dir> <log_file> | tail -30
     Extraer: último comando ejecutado, último hallazgo registrado.

  d) Calcular días restantes hasta deadline:
     deadline_epoch=$(date -d "$DEADLINE" +%s 2>/dev/null)
     today_epoch=$(date +%s)
     days_left=$(( (deadline_epoch - today_epoch) / 86400 ))

-- Paso 3: Construir el briefing

Formato de salida:

---
## OffSec Brief — $(date +%Y-%m-%d)

### Engagements activos: X

---
### [NOMBRE ENGAGEMENT]
- Tipo: [black-box | gray-box | white-box]
- Fase: [fase actual] | Progreso: [X%]
- Deadline: YYYY-MM-DD ([N dias restantes])
- Ultimo trabajo: [resumen de 1-2 lineas de la ultima sesion]
- Pendientes declarados en context.md:
  - [ ] item 1
  - [ ] item 2
- [ALERTA] DEADLINE EN [N] DIAS  ← solo si dias_left <= 3
- [ALERTA] SIN ACTIVIDAD RECIENTE ← solo si ultima actualizacion > 48h

---
### Foco recomendado para hoy

[Identifica el engagement con mas urgencia: deadline proximo, fase critica pendiente
o hallazgo sin documentar. Una sola recomendacion concreta con justificacion de 2-3 lineas.]

Comando sugerido: /[comando] [argumento]
---

-- Notas de comportamiento

- Si hay un solo engagement activo, el foco recomendado va directo sin sección separada.
- Si hay más de 3 engagements activos, advertir sobre carga operativa.
- No mostrar IPs, hostnames ni datos del cliente reales — solo tokens DLP.
- Si context.md tiene datos crudos (IPs sin tokenizar), advertir:
  "[ATENCION] context.md contiene datos sin sanitizar. Ejecutar:
   python3 $OFFSEC_HOME/tools/sanitizer.py <dir> <dir>/context.md"
