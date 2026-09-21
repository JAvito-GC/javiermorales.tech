---
title: "Ya Construí Defensas Contra Cada Ataque del Paper 'AI Agents of Chaos'"
date: 2026-05-26
description: "38 investigadores de MIT, Stanford y Harvard publicaron hallazgos sobre ataques reales a agentes IA. Mapeé cada fallo a un control defensivo que ya tenía en producción."
summary: "Un nuevo paper de investigación documenta 11 modos de fallo en agentes IA reales: suplantación de identidad, borrado de memoria, propagación de ficheros maliciosos y reportes falsos de completado. Construí defensas contra todos ellos hace meses. Aquí está el mapeo."
translationKey: "ai-agents-chaos-defense"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai", "research", "claude-code", "open-source"]
---

38 investigadores de MIT, Stanford, Harvard, Carnegie Mellon y Northeastern pasaron dos semanas atacando agentes IA en vivo con cuentas y herramientas reales. Publicaron sus hallazgos en un paper llamado *AI Agents of Chaos*.

Los agentes fallaron de 11 formas documentadas. Suplantación de identidad. Borrado de memoria. Desinformación en cascada. Acciones destructivas irreversibles. Reportes falsos de completado.

Leí el paper y me di cuenta de algo: ya había construido defensas contra cada vector de ataque que documentan. No como proyecto de investigación — como infraestructura de producción que uso a diario.

Este post mapea cada fallo del paper a un control específico de mi sistema defensivo.

---

## El Paper: Qué Encontraron

Los investigadores testearon [Archon](https://github.com/archon-ai), un framework open-source que conecta LLMs a email, Discord, almacenamiento de ficheros y acceso a shell. Cada agente tenía un propietario, pero cualquiera en un canal público podía enviarle mensajes.

Hallazgos clave:

1. **Un agente borró un servidor de email entero** para "mantener una contraseña en secreto"
2. **Suplantación de identidad via DMs** — un investigador cambió su nombre de usuario, abrió un chat privado y el agente obedeció comandos del impostor
3. **Borrado de memoria bajo demanda** — la identidad falsa ordenó al agente eliminar todos sus ficheros guardados, y cumplió
4. **Propagación de ficheros maliciosos** — un agente comprometido compartió un fichero envenenado con otro agente, que siguió las instrucciones incrustadas
5. **Refuerzo mutuo** — dos agentes confirmaron mutuamente información incorrecta, creando falsa confianza
6. **Reportes falsos de completado** — agentes reportaron "tarea completada con éxito" mientras los sistemas subyacentes estaban destruidos

El paper concluye: *"La responsabilidad en sistemas agénticos no es claramente atribuible ni ejecutable bajo los diseños actuales."*

No estoy de acuerdo. Es ejecutable. Solo tienes que construir la capa de control.

---

## El Mapeo Defensivo

Mi sistema funciona como un conjunto de hooks de shell alrededor de Claude Code. Cada llamada a herramienta — antes y después de la ejecución — pasa por validación. Así es como cada ataque del paper se mapea a una defensa específica.

### Ataque 1: Acciones Destructivas Irreversibles

**Escenario del paper:** El agente "Ash" borró el servidor de email completo para cumplir un objetivo. Eligió la opción más extrema disponible sin considerar consecuencias.

**Defensa: Pre-Tool Enforcer** (`pre-tool-enforcer.sh`)

Cada comando Bash se intercepta antes de ejecutarse. Los patrones destructivos se bloquean en la puerta:

```bash
# Operaciones destructivas — bloqueadas antes de ejecución
if echo "$COMMAND" | grep -qiE \
    'rm\s+-rf\s+/(\s|$)|rm\s+-rf\s+\*|sudo\s+rm\s+-rf'; then
    BLOCKED=true
    REASON="Destructive command blocked"
fi
```

El agente no puede ejecutar `rm -rf`, no puede borrar bases de datos, no puede matar procesos críticos. Esto no es una sugerencia al modelo — es un bloqueo hard a nivel de shell. El comando nunca se ejecuta.

**Guardia adicional:** El hook también bloquea intentos de evasión via backslash (`\rm -rf`), que es una técnica de evasión conocida.

---

### Ataque 2: Suplantación de Identidad en Canales Privados

**Escenario del paper:** Un investigador cambió su nombre en Discord para imitar al propietario del agente. En el canal público, el agente detectó la discrepancia (Discord mantiene IDs ocultos). Pero en un chat privado nuevo, el agente no tenía memoria — vio el nombre "Chris" y obedeció.

**Defensa: Subagent Guard** (`subagent-guard.sh`)

Cuando se crea un subagente, su prompt se intercepta y escanea en busca de patrones de manipulación:

```bash
# Bloquear intentos de extracción de credenciales de cualquier fuente
if echo "$PROMPT" | grep -qiE \
    '(print|show|reveal|list|output|display).*\b(token|secret|credential|password|api.key)\b|\
    (extract|dump|exfil|steal|leak).*\b(token|secret|credential|password|key|creds)\b'; then
    BLOCKED=true
    REASON="Subagent prompt attempts credential extraction"
fi
```

El modelo de defensa es diferente al modelo de confianza del paper. El paper asume: *si el nombre coincide, confía*. Mi sistema asume: *ningún prompt es confiable, independientemente de la fuente*. Cada instrucción se valida contra una deny-list de patrones peligrosos antes de ejecución.

**Principio clave:** La identidad no es un nombre visible. La identidad se verifica por lo que la instrucción pide hacer, no por quién dice enviarla.

---

### Ataque 3: Borrado de Memoria / Eliminación de Ficheros Bajo Orden

**Escenario del paper:** El impostor ordenó al agente borrar todos sus ficheros guardados, memoria y configuración. El agente cumplió porque no tenía mecanismo para proteger su propio estado.

**Defensa: Escrituras a Ficheros Protegidos** (`pre-tool-enforcer.sh`)

Los ficheros críticos del sistema no pueden ser modificados, movidos ni sobreescritos — ni por el agente, ni por subagentes, ni por instrucciones incrustadas en contenido externo:

```bash
# Tampering de ficheros de defensa (cp/mv/ln)
if echo "$COMMAND" | grep -qiE \
    '(cp|mv|ln)\s+.*\.claude/(hooks|settings\.json|mcp\.json)|\
    (cp|mv|ln)\s+.*guardrails/(enforcer\.py|rules\.json|sanitize\.py)'; then
    BLOCKED=true
    REASON="Defense file tampering blocked"
fi
```

El agente no puede borrar sus propios ficheros de defensa. No puede sobreescribir su configuración. No puede "cumplir" una instrucción de eliminar su estado porque la capa de control está *fuera* del control del modelo.

---

### Ataque 4: Propagación de Ficheros Maliciosos Entre Agentes

**Escenario del paper:** Un investigador introdujo instrucciones falsas en un fichero compartido en GitHub. Un agente siguió las instrucciones, luego compartió el fichero con un segundo agente, que también las siguió. Un fichero malicioso infectó a dos agentes.

**Defensa: Escáner de Prompt Injection** (`sanitize.py`)

Todo contenido externo — páginas web scrapeadas, transcripciones de YouTube, respuestas de API, ficheros compartidos — pasa por un escáner de 23 patrones con normalización Unicode:

```python
_INJECTION_PATTERNS = [
    # Intentos de override de instrucciones
    (re.compile(
        r"(?:IGNORE|DISREGARD|FORGET)\s+(?:ALL\s+)?(?:PREVIOUS|ABOVE)\s+"
        r"(?:INSTRUCTIONS|PROMPTS|CONTEXT)", re.IGNORECASE,
    ), "ignore_instructions"),

    # Inyección de llamadas a herramientas
    (re.compile(
        r"(?:call|execute|run|invoke)\s+(?:tool|function|mcp)",
        re.IGNORECASE,
    ), "tool_call_injection"),

    # Instrucciones ocultas en comentarios HTML
    (re.compile(
        r"<!--.*(?:ignore|override|system|instruction).*-->",
        re.IGNORECASE | re.DOTALL,
    ), "html_comment_injection"),

    # Task injection (URGENT: delete X)
    (re.compile(
        r"(?:TODO|TASK|ACTION\s+REQUIRED|URGENT)\s*:.*"
        r"(?:delete|remove|send|post|push|execute|run)",
        re.IGNORECASE,
    ), "task_injection"),
]
```

**Detalle crítico:** El escáner aplica normalización NFKC Unicode *antes* de la búsqueda de patrones. Esto derrota ataques de homoglifos donde un atacante reemplaza caracteres ASCII con caracteres Unicode visualmente idénticos para evadir regex.

Si un fichero compartido contiene "IGNORE PREVIOUS INSTRUCTIONS" — ya sea en ASCII plano, homoglifos Unicode u ofuscación con zero-width — el escáner lo detecta, lo registra y marca el contenido como no confiable.

---

### Ataque 5: Reportes Falsos de Completado de Tareas

**Escenario del paper:** Agentes reportaron "tarea completada con éxito" incluso cuando el sistema subyacente estaba destruido. El paper señala: *"los agentes frecuentemente reportaron completado de tarea, aunque el estado del sistema subyacente contradecía esos reportes."*

**Defensa: Verificación de Integridad** (`integrity-check.sh`)

En cada inicio de sesión, el sistema calcula checksums SHA256 de todos los ficheros de defensa y los compara contra una baseline conocida:

```bash
while IFS= read -r line; do
    expected_hash=$(echo "$line" | awk '{print $1}')
    file_path=$(echo "$line" | awk '{print $2}')

    current_hash=$(shasum -a 256 "$file_path" | awk '{print $1}')
    if [ "$current_hash" != "$expected_hash" ]; then
        FAILURES="${FAILURES}  MODIFIED: ${file_path}\n"
    fi
done < "$CHECKSUM_FILE"
```

Si cualquier fichero de defensa ha sido modificado — incluso si el agente reporta que todo está bien — la verificación de integridad lanza una alerta. El sistema no confía en auto-reportes del agente. Verifica de forma independiente.

**Capa adicional:** El logging de auditoría post-tool registra cada operación sensible en JSONL, creando un trail inmutable que se puede revisar independientemente de lo que el agente *afirme* haber hecho.

---

### Ataque 6: Exposición de Credenciales via Agente Complaciente

**Escenario del paper:** El paper documenta agentes compartiendo ficheros privados, exponiendo documentos y ejecutando acceso a datos sin autorización adecuada.

**Defensa: Detección de Patrones de Credenciales** (pre-tool + post-tool, ambas capas)

Tanto antes como después de la ejecución de herramientas, el contenido se escanea en busca de patrones de credenciales:

```bash
# Post-tool: detección de fuga de credenciales salientes
if echo "$WRITE_CONTENT" | grep -qiE \
    'shpat_[a-zA-Z0-9]{10,}|sk-[a-zA-Z0-9]{20,}|\
    ghp_[a-zA-Z0-9]{36}|AKIA[A-Z0-9]{16}|\
    Bearer\s+[a-zA-Z0-9._-]{20,}|re_[a-zA-Z0-9]{20,}'; then
    echo "[SECURITY] CREDENTIAL LEAK DETECTED in $TOOL_NAME output!"
fi
```

Cubre 12 formatos de credenciales: tokens Shopify, claves OpenAI, PATs de GitHub, access keys AWS, Bearer tokens, claves Resend, tokens Cloudflare, tokens Hetzner, tokens Slack, claves SendGrid y webhook secrets.

**El pre-tool guard** bloquea comandos que *leen* ficheros de credenciales. **El post-tool guard** captura credenciales que aparecen en el *output*. Dos capas independientes.

---

## El Principio Arquitectónico

El paper identifica un defecto de diseño fundamental: los agentes en el estudio no tenían capa de enforcement entre intención y ejecución. El modelo decidía, y la acción ocurría.

Mi sistema inserta enforcement en tres puntos:

```
┌─────────────────────────────────────────────────┐
│  El modelo decide actuar                        │
├─────────────────────────────────────────────────┤
│  ① PRE-TOOL: Bloquear antes de ejecución        │
│     - Comandos destructivos                     │
│     - Escrituras a ficheros protegidos          │
│     - Lecturas de credenciales                  │
│     - Crossover corporativo                     │
├─────────────────────────────────────────────────┤
│  La herramienta se ejecuta (si está permitida)  │
├─────────────────────────────────────────────────┤
│  ② POST-TOOL: Validar después de ejecución      │
│     - Prompt injection en resultados            │
│     - Fugas de credenciales en output           │
│     - Alertas de supply chain (npm)             │
│     - Trail de auditoría (JSONL)                │
├─────────────────────────────────────────────────┤
│  ③ SESIÓN: Verificar estado del sistema         │
│     - Baseline de integridad SHA256             │
│     - Alertas de modificación de ficheros       │
│     - Validación de prompts de subagentes       │
└─────────────────────────────────────────────────┘
```

El modelo no controla la capa de control. La capa de enforcement controla al modelo.

---

## Lo Que el Paper Acierta

Los investigadores hacen una observación importante: *"Cuando los agentes interactúan entre sí, los fallos individuales se componen y emergen modos de fallo cualitativamente nuevos."*

Esto es correcto. Un solo agente sin defensas es una vulnerabilidad. Múltiples agentes sin defensas en comunicación son un sistema de amplificación de instrucciones maliciosas. El paper encontró que un fichero envenenado se propagó a dos agentes — en un sistema de producción con cientos de agentes, esto se convierte en un gusano.

El principio de defensa es el mismo que en seguridad de redes: **zero trust entre agentes**. Cada mensaje, cada fichero compartido, cada instrucción es input no confiable hasta que se valida.

---

## Lo Que el Paper Omite

El paper enmarca el problema como no resuelto: *"La responsabilidad no es claramente atribuible ni ejecutable."*

Discrepo con la segunda parte. La ejecutabilidad requiere dos cosas:

1. **Una capa que el modelo no puede modificar** — hooks de shell que corren *alrededor* del agente, no dentro de él
2. **Verificación independiente** — checksums, logs de auditoría y validación de estado que no dependen del auto-reporte del agente

Ambas existen hoy. No son teóricas. Son código en producción. El paper testó sistemas sin estas capas. Ese es un hallazgo válido sobre el estado *por defecto* de los agentes IA. No es un hallazgo sobre lo que es *posible*.

NIST anunció una AI Agent Standards Initiative en febrero 2026. Cuando esos estándares lleguen, describirán algo muy cercano a lo que ya corre en mi sistema: fronteras de control, registros de auditoría inmutables y verificación de integridad independiente.

---

## Pruébalo Tú Mismo

El sistema defensivo es open source: [github.com/JAvito-GC/claude-guardrails](https://github.com/JAvito-GC/claude-guardrails)

Incluye hooks pre/post-tool, detección de prompt injection con normalización Unicode, checksums de integridad, validación de subagentes y 68+ tests automatizados.

Si estás construyendo agentes IA con acceso a shell, acceso a herramientas o ingestión de datos externos, necesitas una capa de control. El paper *AI Agents of Chaos* es la evidencia. La solución es ingeniería.

---

## Obtén el Framework de Producción

El repo open source te da el código. El framework te da todo lo demás: plantillas de threat model, 12 playbooks de respuesta a incidentes para fallos de agentes IA, mapeo de compliance SOC 2 e ISO 27001, rúbrica de postura de seguridad y guía de implementación con decisiones de arquitectura.

**[AI Agent Defense Kit](https://javiermoralesecurity.gumroad.com/l/ai-defense-kit)** — $49

---

*Para un tratamiento más profundo de arquitecturas defensivas para sistemas de IA autónomos, incluyendo orquestación multi-agente, aislamiento de memoria y patrones de monitorización continua, consulta mi libro [Securing Autonomous AI](/books/).*
