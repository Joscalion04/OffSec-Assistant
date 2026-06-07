Cierra la sesión de trabajo del engagement: $ARGUMENTS

Si no se especifica engagement, pregunta cuál cerrar o si cerrar todos los activos.

Pasos:
1. Lee el context.md del engagement para saber qué se hizo hoy
2. Lee los logs de hoy en logs/session_YYYY-MM-DD.log
3. Genera un resumen de sesión:

## 📋 Resumen de sesión — [FECHA] — [ENGAGEMENT]
- **Duración estimada:** [basado en timestamps del log]
- **Fase trabajada:** X
- **Comandos ejecutados:** N
- **Hallazgos documentados:** N
- **Hallazgos pendientes de documentar:** [lista si hay outputs sin documentar]
- **Resumen de actividad:** [párrafo breve]
- **Pendientes para próxima sesión:**
  - [ ] item 1
  - [ ] item 2

4. Actualiza context.md:
   - Mueve pendientes completados
   - Agrega nuevos pendientes identificados
   - Actualiza "Última actualización"

5. Hace commit en git del engagement:
   cd findings/[engagement] && git add . && git commit -m "session: [FECHA] — [resumen en una línea]"

6. Confirma: "✅ Sesión cerrada. Próxima sesión recomendada: [próximo paso concreto]"
