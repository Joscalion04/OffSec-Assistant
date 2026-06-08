Genera un briefing de inicio de día para todos los engagements activos.

Pasos:
1. Lista todos los directorios en findings/ que tengan un scope.md
2. Para cada engagement, lee:
   - scope.md (fechas, cliente, tipo de prueba)
   - context.md (fase actual, progreso, pendientes)
   - El log de sesión más reciente en logs/
3. Construye el briefing con este formato:

---
## OffSec Brief — [FECHA HOY]

### Engagements activos: X

---
### [NOMBRE ENGAGEMENT]
- **Cliente:** X | **Deadline:** YYYY-MM-DD ([N] días restantes)
- **Fase:** X | **Progreso:** X%
- **Último trabajo:** [resumen de última sesión]
- **Pendientes de hoy:**
  - [ ] tarea 1
  - [ ] tarea 2
- **Alerta:** [!] DEADLINE PROXIMO (si el deadline es en menos de 3 días)

---
### Foco recomendado para hoy
[Un solo engagement o tarea específica, con justificación]

4. Si no hay engagements activos, indica cómo crear uno con /new-engagement
