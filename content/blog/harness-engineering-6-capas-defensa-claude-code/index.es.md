---
title: "Harness Engineering: 6 Capas de Defensa que Construí para Claude Code"
date: 2026-05-12
description: "Harness Engineering es la disciplina de construir todo lo que rodea a un modelo de IA. Construí un sistema de 6 capas de defensa para agentes Claude Code — hooks, guards, integrity checks — con 99/100 en seguridad. Esta es la arquitectura."
summary: "El modelo no es el producto. El harness lo es. Comparto el sistema de 6 capas de defensa que construí alrededor de Claude Code para gestionar 5 proyectos sin una sola fuga de credenciales."
translationKey: "harness-engineering"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai", "claude-code", "harness-engineering", "devtools"]
---

En abril de 2026, Andrej Karpathy dio una charla en Sequoia donde introdujo un concepto que resonó con todos los que construimos sistemas de IA en producción: **el harness importa más que el modelo**.

Su fórmula es directa:

```
Agent = Model + Harness
```

El modelo es commodity. GPT-4, Claude, Gemini -- todos convergen. Lo que diferencia un agente útil de uno peligroso es el **harness**: las restricciones, sensores, bucles de feedback e infraestructura que envuelven al modelo y convierten capacidad bruta en comportamiento controlado.

Llevo seis meses construyendo exactamente esto. No en teoría -- en un sistema en producción que gestiona 5 proyectos, ejecuta scrapers, despliega código y maneja credenciales. El sistema puntúa 99/100 en auditorías de seguridad con cero fugas de credenciales en miles de interacciones.

Esta es la arquitectura.

---

## Qué Es Harness Engineering

Harness Engineering es la disciplina de construir todo lo que NO es el modelo pero hace que el modelo sea útil, seguro y controlable:

- Cómo restringes el comportamiento del agente
- Cómo detectas cuando algo va mal
- Cómo retroalimentas contexto al sistema
- Cómo aíslas los entornos de ejecución
- Cómo codificas expertise en patrones reutilizables

El modelo elige el siguiente token. El harness decide qué puede ver, tocar y romper.

---

## Patrón 1: Restricciones (La Config Reactiva)

Todo sistema en producción tiene un fichero de configuración. En Claude Code es `CLAUDE.md`. La clave: **cada línea debe venir de un incidente real**.

Mi `CLAUDE.md` no es una lista de deseos. Es un documento de tejido cicatricial. Cada regla existe porque el agente la violó al menos una vez:

```markdown
# Security - MANDATORY
1. Zero work footprint. Never reference employer names or work directories.
2. Never hardcode credentials. All secrets in ~/.klaudio-creds.sh
3. Never commit secrets. Pre-commit hook rejects credential patterns.
4. Separate git identity. Verify git config user.email before every commit.
5. No work MCP servers. This project uses its own MCP config.
```

No es documentación. Es una capa de restricción. El agente lo lee al inicio de cada sesión y lo trata como ley. Cuando aparece un nuevo modo de fallo, añades una línea. La config crece reactivamente, codificando memoria operacional.

---

## Patrón 2: Sensores (Hooks Pre/Post)

Las restricciones solas no bastan. Los LLMs son probabilísticos -- van a violar reglas. Necesitas sensores que detecten violaciones en tiempo real.

Implementé dos capas de hooks:

**Hook pre-herramienta** -- se ejecuta antes de cada llamada:
```bash
# Bloquea patrones de credenciales en escritura de ficheros
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
    SCAN_MSG=$(echo "$INPUT_JSON" | python3 "$KLAUDIO_DIR/guardrails/scan_content.py")
    if [ "$SCAN_RC" -eq 2 ]; then
        echo "BLOCKED: Credential in Write/Edit content" >&2
        exit 2
    fi
fi
```

**Hook post-herramienta** -- se ejecuta después de cada llamada:
```bash
# Escaneo de prompt injection en contenido externo
if echo "$TOOL_NAME" | grep -qiE 'mcp__|firecrawl|youtube'; then
    echo "$RESULT_TEXT" | python3 "$SANITIZE" --mode scan
fi
```

El pre-hook impide que el agente escriba credenciales en ficheros o ejecute comandos peligrosos. El post-hook escanea todo el contenido externo (scrapes web, transcripciones, resultados de MCP) buscando patrones de prompt injection antes de que el agente los procese.

---

## Patrón 3: Skills Codificadas

Un LLM generalista es exactamente eso: generalista. Para convertirlo en especialista, codificas conocimiento de dominio en ficheros de skill estructurados.

Tengo 23 skills instaladas. Cada una es un fichero markdown con:
- Condiciones de activación (cuándo se lanza)
- Metodología paso a paso
- Material de referencia
- Criterios de evaluación

El agente no reinventa una auditoría SEO cada vez. Carga la skill, sigue el procedimiento y produce resultados consistentes. Las skills son la diferencia entre "asistente IA" y "especialista IA."

---

## Patrón 4: Bucles de Feedback

Un agente sin feedback se degrada. Se desvía de las restricciones, acumula errores y pierde contexto. Necesitas mecanismos que cierren el bucle.

**Verificación de integridad** -- SHA256 de los ficheros de defensa al inicio de sesión:
```bash
while IFS= read -r line; do
    expected_hash=$(echo "$line" | awk '{print $1}')
    file_path=$(echo "$line" | awk '{print $2}')
    actual_hash=$(shasum -a 256 "$file_path" | awk '{print $1}')
    if [ "$expected_hash" != "$actual_hash" ]; then
        FAILURES="${FAILURES}  TAMPERED: ${file_path}\n"
    fi
done < "$CHECKSUM_FILE"
```

**Hook de parada** -- recuerda al agente trabajo sin commitear y registra violaciones:
```bash
if [ -n "$(git status --porcelain)" ]; then
    echo "Uncommitted changes in Klaudio. Commit if work is complete."
fi
```

**Session relay** -- un bus de mensajes entre sesiones paralelas de agentes. Cuando un agente descubre algo, los demás se enteran en su siguiente sesión.

---

## Patrón 5: Aislamiento de Infraestructura

El modelo corre en local. Pero la ejecución ocurre en otro sitio.

Mi regla es absoluta: **cero ejecución de código en la máquina de desarrollo**. Todos los scrapers, contenedores Docker y despliegues corren en un VPS. La máquina local es solo código. Esto significa que un agente comprometido no puede acceder a credenciales locales, claves SSH ni infraestructura de trabajo.

```markdown
# De CLAUDE.md
- Code only on MacBook. All execution on VPS. Never run project code locally.
```

Esto es defensa en profundidad. Aunque el agente bypaseara todos los hooks, no puede alcanzar datos de producción desde el entorno de desarrollo.

---

## Patrón 6: Ficheros de Descubrimiento (Agent Cards)

Cuando ejecutas múltiples agentes en múltiples proyectos, necesitan descubrir las capacidades de los demás. Uso:

- Ficheros `AGENTS.md` que describen qué hace cada agente
- Config MCP (`.claude/mcp.json`) para descubrimiento de herramientas
- Agent cards en `.agents/` con definiciones de rol y límites

Es el equivalente a un service mesh para agentes IA. Sin esto, los agentes duplican trabajo, entran en conflicto o ignoran herramientas disponibles.

---

## Resultados

Seis meses de harness engineering, medidos:

- **99/100 en auditoría de seguridad** (script custom de 8 checks)
- **Cero fugas de credenciales** en miles de interacciones
- **5 proyectos gestionados** por una sola persona con agentes IA
- **6 capas de defensa** que operan independientemente (defensa en profundidad)
- **3,000+ listings activos** scrapeados y mantenidos sin intervención manual

El modelo no produjo estos resultados. El harness lo hizo.

---

## Conclusión

Si construyes con agentes IA, deja de optimizar prompts y empieza a hacer ingeniería de tu harness. El modelo es commodity. Tu ventaja competitiva es el sistema que lo rodea.

El sistema completo de defensa es open source: [github.com/JAvito-GC/claude-guardrails](https://github.com/JAvito-GC/claude-guardrails)

Construye el tuyo. Cada sistema necesita un harness diferente. Pero los patrones -- restricciones, sensores, skills, bucles de feedback, aislamiento, descubrimiento -- son universales.

---

**Artículos relacionados:**

- [Mi Agentic OS: cómo gestiono 5 proyectos solo con Claude Code](/es/blog/mi-agentic-os-5-proyectos-con-claude-code/) — el sistema completo donde estas 6 capas de defensa se aplican en producción.
- [Cómo construí un sistema de guardrails para agentes IA](/es/blog/como-construi-guardrails-para-agentes-ia/) — la implementación open source del framework de guardrails en detalle.
- [Guardrails para agentes de seguridad IA en producción](/es/blog/guardrails-agentes-seguridad-produccion/) — aplicación específica de guardrails a agentes con acceso privilegiado en un SOC.
