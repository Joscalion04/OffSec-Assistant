Genera el briefing de inicio de día para todos los engagements activos.

Determina OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}" antes de comenzar.

-- Paso 1: Verificar estado del entorno y descubrir engagements activos

Ejecuta en orden:

  a) Verificar que el directorio base existe:
     ls "$OFFSEC_HOME/findings" 2>/dev/null

     Si findings/ no existe, mostrar:
     ---
     ## OffSec Brief — [fecha]
     ### Estado: Instalación limpia detectada

     No existe el directorio `findings/`. El entorno aún no tiene engagements.

     **Para comenzar:**
     1. Crear un nuevo engagement: `/new-engagement <nombre>`
     2. Editar `findings/<fecha>_<nombre>/scope.md` con los targets autorizados
     3. Iniciar reconocimiento: `/recon <target>`

     Herramientas disponibles: `/check-tools`
     ---
     y detente.

  b) Listar todos los directorios de engagement:
     ls -dt $OFFSEC_HOME/findings/????-??-??_* 2>/dev/null

     Si el directorio está vacío (ningún resultado), mostrar:
     ---
     ## OffSec Brief — [fecha]
     ### Estado: Sin engagements

     El directorio `findings/` existe pero no contiene engagements.

     **Para comenzar:**
     1. Crear un nuevo engagement: `/new-engagement <nombre>`
     2. Editar el `scope.md` generado con los targets autorizados
     3. Iniciar reconocimiento: `/recon <target>`
     ---
     y detente.

  c) Filtrar engagements activos — un engagement es activo si tiene AMBOS:
     - scope.md
     - context.md

     Si ningún engagement tiene ambos archivos, mostrar:
     ---
     ## OffSec Brief — [fecha]
     ### Estado: Engagements incompletos

     Se encontraron [N] directorio(s) pero ninguno tiene scope.md + context.md completos.

     Directorios encontrados:
     - [lista de dirs con qué archivo les falta]

     **Acciones sugeridas:**
     - Si acabas de crear un engagement: editá `scope.md` y ejecutá `/recon <target>`
     - Si el context.md no existe todavía: el primer `/recon` lo genera automáticamente
     ---
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
