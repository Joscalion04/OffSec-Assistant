Genera el reporte final de pentest para el engagement: $ARGUMENTS

Determina OFFSEC_HOME="${OFFSEC_HOME:-$(pwd)}" antes de comenzar.

-- Paso 1: Localizar el engagement

  ENGAGEMENT_DIR=$(ls -d $OFFSEC_HOME/findings/????-??-??_$ARGUMENTS* 2>/dev/null | head -1)
  Si no se encuentra: listar todos los disponibles en findings/ y pedir al operador que especifique.

-- Paso 2: Recopilar evidencia (protocolo DLP)

Leer los siguientes archivos SIEMPRE sanitizados:

  a) scope.md — metodología, tipo de prueba, periodo de evaluación
     (context.md y finding_*.md ya usan tokens, leer directo)

  b) context.md — resumen de fases completadas, vectores evaluados

  c) Todos los findings documentados:
     ls $ENGAGEMENT_DIR/finding_*.md 2>/dev/null
     Para cada uno leer directo (ya tienen tokens DLP)

  d) Si existen outputs de herramientas en recon/ o vulns/ que aún no estén en findings:
     Sanitizar antes de leer:
       python3 "$OFFSEC_HOME/tools/sanitizer.py" "$ENGAGEMENT_DIR" <archivo>

-- Paso 3: Validar y calcular CVSS 3.1 de cada hallazgo

Para cada finding, verificar los campos CVSS:

  a) Campos que DEBEN existir y estar completos:
     - CVSS Score: número entre 0.0 y 10.0
     - CVSS Vector: string con formato CVSS:3.1/AV:.../...

  b) Clasificar el estado de cada finding:
     - COMPLETO:   tiene Score + Vector válidos
     - ESTIMADO:   tiene Score pero no Vector (ej. exportados desde Burp)
     - INCOMPLETO: falta Score o Vector
     - SIN CVSS:   no tiene ningún dato CVSS

  c) Para findings INCOMPLETOS o SIN CVSS:
     - Intentar calcular el vector basándose en descripción e impacto declarado
     - Si se puede calcular, marcarlo como [CALCULADO] en el reporte
     - Si no hay suficiente información, marcarlo como [PENDIENTE-CVSS]

  d) Si hay findings [PENDIENTE-CVSS]: mostrar advertencia al final del reporte:
     "[ATENCION] N finding(s) sin CVSS completo — revisar antes de entregar al cliente"

  e) Si el operador pasó --draft como argumento:
     - Generar el reporte igual, marcando findings incompletos con [DRAFT]
     - No bloquear la generación por CVSS faltante

Clasificar por severidad:
  - Critical: CVSS 9.0 - 10.0
  - High:     CVSS 7.0 - 8.9
  - Medium:   CVSS 4.0 - 6.9
  - Low:      CVSS 2.0 - 3.9
  - Info:     CVSS 0.0 - 1.9

-- Paso 4: Generar el reporte

REPORT_FILE="$OFFSEC_HOME/reports/${ARGUMENTS}_report_$(date +%Y-%m-%d).md"

Estructura del reporte:

---
# Reporte de Seguridad Ofensiva
## [Nombre del Engagement]
**Fecha:** $(date +%Y-%m-%d)
**Tipo de prueba:** [black-box | gray-box | white-box]
**Periodo de evaluacion:** [desde] — [hasta]
**Clasificacion:** CONFIDENCIAL

---
## 1. Resumen Ejecutivo

[2-3 parrafos sin terminologia tecnica, para gerencia no tecnica:]
- Proposito del engagement
- Conclusion principal (ej: "Se identificaron N vulnerabilidades criticas que permiten...")
- Impacto de negocio en términos de riesgo (no de CVEs)
- Recomendacion prioritaria

**Distribucion de hallazgos:**
| Severidad | Cantidad |
|-----------|----------|
| Critical  | N        |
| High      | N        |
| Medium    | N        |
| Low       | N        |
| Info      | N        |
| **Total** | **N**    |

---
## 2. Alcance y Metodologia

**Targets evaluados:**
[Listar con tokens DLP: TGT-001, HST-001, etc.]

**Metodologia:** [OWASP / PTES / NIST / custom]
**Herramientas principales:** [lista de herramientas usadas]

---
## 3. Hallazgos

[Por cada finding, en orden descendente de severidad:]

### [FIND-NNN] [Titulo del hallazgo]

**Severidad:** [Critical | High | Medium | Low | Info]
**CVSS 3.1:** [score] — [vector string]
**Categoria:** [SQLi | XSS | RCE | LPE | MisConfig | etc.]
**MITRE ATT&CK:** [Tecnica/Sub-tecnica si aplica]

**Descripcion:**
[Que es la vulnerabilidad y donde se encuentra, con tokens DLP]

**Evidencia:**
[Comandos ejecutados, outputs relevantes sanitizados, capturas referenciadas]

**Impacto:**
[Que puede hacer un atacante si explota esto]

**Remediacion:**
[Pasos concretos para mitigar, con referencias a CVEs o CWEs si aplica]

**Referencias:**
- CWE-NNN
- CVE-YYYY-NNNNN (si aplica)

---

[Repetir seccion por cada finding]

---
## 4. Conclusiones y Recomendaciones Generales

[3-5 puntos de mejora sistémica que no corresponden a un finding específico:]
- Postura general de seguridad
- Priorización recomendada para remediaciones
- Roadmap sugerido (inmediato / 30 dias / 90 dias)

---
## 5. Metodologia Detallada

**Fases ejecutadas:**
- [ ] Reconocimiento pasivo
- [ ] Reconocimiento activo
- [ ] Escaneo de vulnerabilidades
- [ ] Explotacion
- [ ] Post-explotacion
- [ ] Documentacion

**Limitaciones del engagement:**
[Restricciones de tiempo, acceso, o scope que puedan afectar la completitud]

---
*Reporte generado el $(date +%Y-%m-%d) | OffSec Assistant*
*Este documento es CONFIDENCIAL — distribucion restringida segun contrato*
---

-- Paso 5: Guardar y confirmar

Guardar el reporte en $REPORT_FILE

Luego mostrar:
"Reporte generado: $REPORT_FILE
Hallazgos incluidos: N (C: N | H: N | M: N | L: N | I: N)

[RECORDATORIO DLP] Antes de entregar al cliente:
  - Restaurar tokens a valores reales consultando dlp-map.json
  - Revisar que no queden tokens TGT-NNN visibles en la version final
  - Validar que evidencias adjuntas no contienen datos de terceros no autorizados"

-- Paso 6: Commit del reporte

  cd "$OFFSEC_HOME"
  git add reports/
  git commit -m "report: $(date +%Y-%m-%d) — reporte final $ARGUMENTS"
