---
title: "Cómo detectar cuando tu agente de IA se sale del guion"
date: 2026-08-10
description: "No confíes en que el agente se porte bien: instruméntalo. Qué señales capturar, qué logs importan y qué detecciones escribir para pillar prompt injection, abuso de herramientas y exfiltración vía MCP."
summary: "La conversación sobre seguridad de agentes se ha quedado en 'ten cuidado con la trifecta letal'. Bien, ya la tienes. ¿Y ahora cómo la detectas en producción? Este post baja al terreno de detection engineering: las cuatro señales que hay que instrumentar en un agente autónomo, el log que casi nadie captura, y detecciones concretas que puedes escribir hoy."
translationKey: "detecting-rogue-ai-agents"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai-agents", "detection-engineering", "prompt-injection", "mcp", "appsec"]
---

Casi todo lo que se escribe sobre seguridad de agentes de IA se queda en la fase de amenaza: la trifecta letal, la inyección de prompts, el agente con shell que lee tu correo. Diagnóstico correcto y repetido hasta el aburrimiento. Pero hay una pregunta que casi nadie contesta, y es la única que importa cuando el agente ya está en producción: **¿cómo te enteras de que ha pasado?**

Un agente autónomo no es un usuario ni es un servicio. Es un actor no determinista con credenciales, que toma decisiones a partir de texto que no controlas y ejecuta acciones con herramientas reales. Desde detection engineering eso tiene una traducción incómoda: no puedes prevenir todo lo que hará, así que tienes que **instrumentarlo como instrumentarías a un insider con acceso privilegiado**. No confías en que se porte bien. Le pones telemetría y escribes detecciones contra ella.

Este post es esa parte. Qué señales capturar, qué logs importan, y qué detecciones concretas escribir.

---

## El error de base: tratar la salida del modelo como el evento de seguridad

El instinto es poner el foco en el prompt y en la respuesta del LLM. Es el sitio equivocado. El texto que genera el modelo no le hace daño a nadie: lo que hace daño es la **acción**. La llamada a la herramienta. El `GET` a un dominio raro. El `read_file` sobre `~/.ssh/id_rsa`. El `POST` a un webhook que nadie dio de alta.

Regla de detección número uno, y de la que cuelga todo lo demás:

> El evento de seguridad no es lo que el agente *dice*. Es lo que el agente *hace* con una herramienta.

Eso te dice dónde poner los sensores: en la capa de tool-calling, no en la de generación de tokens. Si tu única telemetría es "el prompt y la respuesta", estás mirando la sombra en vez del objeto.

---

## Las cuatro señales que hay que instrumentar

Para cada invocación de herramienta —cada tool call, cada llamada MCP— captura como mínimo:

1. **Identidad de la herramienta y argumentos completos.** Nombre de la tool, servidor MCP de origen, y los parámetros sin truncar. El argumento es donde vive el ataque (`{"path": "../../etc/shadow"}`).
2. **Procedencia de la decisión.** ¿Qué disparó esta llamada? ¿La instrucción del sistema, la petición del usuario, o **contenido recuperado** (una página web, un email, un documento RAG)? Esta es la señal que casi nadie captura y es la más valiosa. Una tool call cuyo origen causal es texto no confiable es tu principal indicador de inyección de prompts.
3. **Resultado y tamaño.** Código de salida, bytes devueltos, filas leídas. La exfiltración se ve en el volumen antes que en el contenido.
4. **Secuencia y temporalidad.** El orden de las llamadas y el delta de tiempo. Los agentes tienen "firmas" de comportamiento; una desviación de secuencia es señal.

Si tu framework de agentes no te da la señal 2, envuélvela tú. No hace falta nada exótico: un wrapper alrededor del dispatcher de herramientas que anote el origen de contexto de cada llamada y emita un evento estructurado. Stdlib y un logger JSON bastan. Ese log es tu fuente de detección; trátalo como tratarías EDR o CloudTrail, no como un `print` de debug.

Ejemplo de evento mínimo que deberías estar emitiendo por cada tool call:

```json
{
  "ts": "2026-08-10T09:14:22Z",
  "agent_id": "triage-bot-3",
  "tool": "http_get",
  "mcp_server": "web-fetch",
  "args": {"url": "https://pastebin.example/raw/xY3"},
  "trigger_source": "retrieved_content",
  "context_ref": "email_id:44812",
  "bytes_out": 0,
  "bytes_in": 1840,
  "session_id": "s-9f2c"
}
```

Con eso ya puedes escribir detecciones de verdad.

---

## Detecciones concretas que puedes escribir hoy

No teoría. Reglas.

**1. Tool call originada en contenido no confiable que toca una herramienta sensible.**
La joya de la corona. Si `trigger_source` es `retrieved_content` o `tool_result` (no `user` ni `system`) **y** la herramienta invocada está en tu lista sensible (envío de email, HTTP saliente, ejecución de comandos, escritura en filesystem), alerta. Este patrón —"un email me dijo que llamara a la API de pagos"— es la inyección de prompts materializándose en acción. Es la detección de mayor señal y menor ruido que vas a escribir.

**2. Desviación del catálogo de herramientas.**
Cada agente tiene un scope: un triage bot lee alertas y consulta la CMDB, no ejecuta `curl`. Modela el conjunto esperado de herramientas por rol de agente (una allowlist, literal) y alerta cuando invoca algo fuera de él. No es machine learning: es un `set` y una comparación. El agente que "descubre" una herramienta que nunca usa es tu equivalente a un proceso que de repente hace LDAP recon.

**3. Traversal y acceso a secretos en argumentos.**
Regex sobre los argumentos de las tools de filesystem: `..`, rutas absolutas a `/etc`, `.ssh`, `.env`, `credentials`, `id_rsa`. Trivial, alto valor. El agente legítimo trabaja en su directorio de tarea; el que va a por `~/.aws/credentials` no.

**4. Fan-out de exfiltración.**
Correlaciona por `session_id`: una lectura grande (`bytes_in` alto de un `read_file` o una query) seguida en la misma sesión de una salida de red (`bytes_out` a un destino externo). Datos que entran, datos que salen, poco tiempo entre medias. Es la firma de exfiltración clásica, solo que el "malware" es un agente confundido por un prompt.

**5. Destinos de red fuera de allowlist.**
Los agentes deberían hablar con un conjunto conocido de dominios. Cualquier `http_get`/`http_post` a un destino fuera de la allowlist es alerta, especialmente si además la señal 1 aplica. Pastebins, webhooks efímeros, IPs crudas: prioridad alta.

**6. Bucle o repetición anómala.**
Un agente que llama a la misma herramienta N veces con argumentos que varían por incrementos suele estar haciendo enumeración o brute force —o simplemente atascado quemando tu factura. Ambos merecen un evento.

---

## El detalle que lo hace real: correlaciona por sesión, no por evento

Ninguna de estas señales aislada te da la película. La inyección de prompts no es un evento, es una **cadena causal**: contenido no confiable entra → el modelo lo trata como instrucción → invoca una herramienta sensible → exfiltra. Si tu telemetría no lleva un `session_id` y un `context_ref` que te permitan reconstruir esa cadena, tienes eventos sueltos y ninguna historia. La diferencia entre una alerta accionable y un lago de ruido es exactamente esa capacidad de correlación. Es lo mismo que en un SOC de toda la vida: el valor está en el enlace, no en la línea de log suelta.

---

## Dónde encaja esto

Un agente autónomo con herramientas es, en términos de detección, un endpoint privilegiado que ejecuta código en tu nombre a partir de input que no controlas. Trátalo así: telemetría en la capa de acción, detecciones sobre procedencia y scope, correlación por sesión. Nada de esto requiere un producto nuevo. Requiere decidir que el comportamiento del agente es un dominio de detección de primera clase y no un `print` en la consola.

Este post baja al terreno lo que en [la trifecta letal del agente de PewDiePie](/blog/pewdiepie-odysseus-agente-email-trifecta-letal/) quedaba como amenaza: allí el problema, aquí las detecciones. Si estás montando esto para agentes propios y quieres el kit de detecciones, playbooks de respuesta y el modelo de amenazas completo, lo he empaquetado en [Blindar Agentes IA y el AI Agent Defense Kit](/books/). Pero con las seis reglas de arriba y un log de tool calls decente ya cubres el 80% del riesgo real. Empieza por instrumentar la señal de procedencia. Es la que nadie captura y la que más te va a salvar.
