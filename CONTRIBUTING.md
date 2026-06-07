# Guía de Contribución

Gracias por tu interés en contribuir a OffSec Assistant. Esta guía define el
proceso completo para que tus aportes sean claros, revisables y mantenibles.

---

## Código de Conducta

Al contribuir a este proyecto aceptas que:

1. **Todo uso debe ser ético y autorizado.** No se aceptan contribuciones que
   sirvan para evadir el gate de scope, automatizar ataques no autorizados, o
   eliminar confirmaciones obligatorias en `/exploit`.
2. El debate técnico es bienvenido. Los ataques personales, no.
3. Las contribuciones deben respetar la [Licencia](LICENSE) del proyecto.

---

## ¿Cómo contribuir?

### 1. Fork y entorno local

```bash
# 1. Haz fork en GitHub y clona tu fork
git clone https://github.com/<tu-usuario>/OffSec-Assistant.git
cd OffSec-Assistant

# 2. Agrega el upstream como remoto
git remote add upstream https://github.com/Joscalion04/OffSec-Assistant.git

# 3. Mantén tu fork actualizado antes de trabajar
git fetch upstream
git checkout main
git merge upstream/main
```

### 2. Crea una rama de trabajo

```bash
git checkout -b <tipo>/<descripcion-corta>
```

Ver sección **Estrategia de ramas** para los tipos permitidos.

### 3. Desarrolla tu cambio

- Sigue los estándares de código descritos abajo.
- Escribe mensajes de commit según la sección **Formato de commits**.
- Mantén el scope del cambio acotado: un PR = una cosa.

### 4. Abre un Pull Request

- Apunta tu PR a la rama `develop` (no a `main` directamente).
- Usa la plantilla de PR disponible en `.github/pull_request_template.md`.
- Asegúrate de que tu branch esté actualizado con `upstream/develop` antes de abrir el PR.

---

## Estrategia de ramas

| Rama | Propósito |
|------|-----------|
| `main` | Código estable y publicado. Solo recibe merges desde `develop` vía release. |
| `develop` | Rama de integración. Todos los PRs apuntan aquí. |
| `feature/<nombre>` | Nuevas funcionalidades o comandos. |
| `fix/<nombre>` | Corrección de bugs. |
| `docs/<nombre>` | Cambios en documentación únicamente. |
| `chore/<nombre>` | Tareas de mantenimiento (dependencias, CI, estructura). |
| `refactor/<nombre>` | Reestructuración sin cambio de comportamiento. |

**Regla:** Nunca hagas push directo a `main`. Los mantenedores son los únicos que
fusionan `develop` → `main` en releases.

---

## Formato de commits

Este proyecto usa [Conventional Commits](https://www.conventionalcommits.org/).

### Estructura

```
<tipo>(<scope opcional>): <descripción en presente, minúsculas>

[cuerpo opcional — explica el POR QUÉ, no el qué]

[footer opcional — Breaking changes o referencias]
```

### Tipos permitidos

| Tipo | Cuándo usarlo |
|------|--------------|
| `feat` | Nueva funcionalidad o nuevo comando |
| `fix` | Corrección de un bug |
| `docs` | Solo cambios en documentación |
| `chore` | Mantenimiento, dependencias, estructura de archivos |
| `refactor` | Reestructuración sin cambio de comportamiento |
| `test` | Agregar o modificar tests |
| `recon` | Cambios específicos a la fase de reconocimiento |
| `vuln` | Cambios específicos al vuln-scan |
| `exploit` | Cambios específicos a la fase de explotación |
| `report` | Cambios al sistema de reportes |
| `agent` | Cambios a agentes (decision-advisor, doc-writer, etc.) |
| `template` | Cambios a plantillas de findings/context/scope |

### Scopes opcionales

`commands`, `agents`, `tools`, `templates`, `docs`, `ci`

### Ejemplos válidos

```bash
feat(commands): agregar soporte para flag --output en /recon
fix(agents): corregir doc-writer que no escribía el CVSS score correctamente
docs(readme): actualizar sección de instalación con requisitos de Claude Code
chore(gitignore): excluir archivos .pcap de capturas de red
refactor(tools): simplificar lógica de auto-runner.sh
agent(decision-advisor): mejorar razonamiento para casos de privilege escalation
template(finding): agregar campo de EPSS score junto al CVSS
```

### Breaking changes

Si tu cambio rompe compatibilidad con versiones anteriores, agrega `BREAKING CHANGE:`
en el footer:

```
feat(commands): cambiar estructura de scope.md

BREAKING CHANGE: scope.md ahora requiere campo `authorization_date`.
Los engagements existentes deben agregar este campo manualmente.
```

---

## Estándares de código

### Archivos `.md` de comandos (`.claude/commands/`)

- Instrucciones claras en lenguaje imperativo.
- Incluye ejemplos de uso.
- No elimines la verificación de `scope.md` en comandos activos.
- Toda nueva fase activa debe requerir confirmación antes de ejecutar.

### Scripts de shell (`tools/`)

- Bash estricto: `set -euo pipefail`.
- Variables entre comillas para evitar word splitting.
- Sin dependencias implícitas — documenta qué herramientas se necesitan.

### Plantillas (`templates/`)

- Mantén los campos de metadata completos (ID, fecha, CVSS, CVE, CWE).
- Los campos opcionales van marcados con `(si aplica)`.

---

## Proceso de revisión de PRs

1. El autor abre el PR con la plantilla completa.
2. Un mantenedor realiza code review en ≤ 5 días hábiles.
3. El autor responde o aplica el feedback.
4. Con al menos 1 aprobación y sin conflictos, el mantenedor hace merge.
5. El merge a `main` ocurre solo en releases, agrupando los cambios en `develop`.

### Criterios de rechazo automático

- El PR agrega funcionalidad que evade restricciones éticas (scope gate, confirmación de exploit).
- El PR no incluye descripción del cambio.
- El PR modifica la LICENSE para debilitar las cláusulas de uso ético.

---

## Reportar un bug

Usa la plantilla de issue `Bug Report` en GitHub Issues. Incluye:
- Versión del proyecto (`git log --oneline -1`)
- Pasos exactos para reproducir
- Comportamiento esperado vs. comportamiento observado
- Output relevante (sanitizado — sin IPs ni datos de clientes reales)

## Proponer una funcionalidad

Usa la plantilla `Feature Request`. Describe el caso de uso concreto antes de
proponer la solución técnica.
