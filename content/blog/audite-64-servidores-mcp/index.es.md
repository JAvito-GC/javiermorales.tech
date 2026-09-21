---
title: "Audité 64 servidores MCP públicos con un linter que escribí. 63 salieron limpios"
date: 2026-07-27
description: "Escribí un linter de seguridad para servidores MCP y agentes IA, y lo corrí contra 64 repos públicos —AWS, Stripe, Google, Sentry, Prisma—. El resultado dice más sobre el estado real de la seguridad de agentes, y sobre los falsos positivos, que cualquier titular alarmista. Es gratis y open source."
summary: "Un scanner estático (Python, cero dependencias, cero red) que audita configuraciones de servidores MCP y agentes contra el OWASP Agentic Top 10, con guía de detección para cada hallazgo. Lo validé contra 64 repos MCP públicos: 63 sin hallazgos serios. Este post cuenta qué encontré, por qué la mayoría del ruido inicial eran falsos positivos, y qué aprendí afinándolos — la parte honesta que los lanzamientos de herramientas se saltan."
translationKey: "agent-audit-kit-launch"
draft: false
og_image: "/img/og-default.png"
tags: ["detection-engineering", "ai-security", "mcp", "owasp", "open-source"]
---

Hay mucho escrito sobre asegurar agentes IA, y casi todo es abstracto: marcos de gobernanza, checklists, el EU AI Act. Poco de eso te dice, mirando tu `mcp.json` concreto, qué está mal y cómo detectarlo cuando alguien lo explote.

Así que escribí el linter que me faltaba. Y en lugar de lanzarlo con un titular alarmista, hice algo más útil y más incómodo: lo corrí contra **64 servidores MCP públicos** —de AWS, Stripe, Google, Sentry, Prisma, Neon, Grafana, Cloudflare y más— y me obligué a verificar cada hallazgo a mano. Lo que aprendí afinándolo es la mitad del valor de este post.

## El hueco: prevención sí, detección no

Las herramientas que existen —y hay buenas, de Trail of Bits a la propia Anthropic— se centran en *prevenir*: aquí está el fallo, arréglalo. Es correcto e insuficiente. En seguridad de verdad no siempre puedes arreglar hoy: el fallo vive en una dependencia, en un agente que no controlas, o en una decisión de producto ajena. La pregunta que queda es: *si no puedo arreglarlo ya, ¿cómo detecto que lo están abusando?*

Esa es la pregunta que hago para vivir como ingeniero de detección, y la que ninguna herramienta de agentes respondía. Así que la metí en el linter: **cada hallazgo trae su guía de detección** —los logs y señales para cazar el abuso en producción— con reglas Sigma listas para las clases más graves.

## Qué encontré en 64 repos: menos de lo que esperas, y esa es la historia

**63 de 64 salieron sin hallazgos serios.** Uno solo tenía un fallo real de peso, del que hablo abajo.

Ese resultado no es decepcionante — es la lección. Cuando corrí la primera versión del scanner, me devolvió 15 "hallazgos", incluidos varios críticos. Me habría bastado para un post alarmista tipo "encontré fallos críticos en servidores MCP de grandes empresas". Habría sido deshonesto. Al verificarlos uno a uno, la mayoría eran **falsos positivos**:

- Un comando `remove` marcado como "acción destructiva sin confirmación"… que tenía un flag `--yes` precisamente porque por defecto **pide confirmación**.
- Un `logger.remove()` (configuración de logging) confundido con una operación destructiva.
- Un sandbox de código *deliberadamente* read-only marcado como "agencia excesiva" — justo lo contrario.
- Código HTTP normal (`getProxyAgent()`, `userAgent()`) clasificado como "agente IA" porque mi detector matcheaba `Agent(` como subcadena.

Cada falso positivo era una lección sobre mi propia herramienta. Un scanner que grita "crítico" sobre código sano no es riguroso, es ruido — y en seguridad el ruido mata la confianza más rápido que un fallo perdido. Pasé la mayor parte del trabajo no *encontrando* fallos, sino **enseñando al scanner a callarse cuando no hay fallo.** El resultado: de 15 hallazgos ruidosos a 2 verificados, con 63 de 64 repos limpios.

## El único fallo real, y por qué es instructivo

El hallazgo que sí resistió la verificación: un agente de investigación que recibe una URL del usuario, hace `WebFetch` de esa web, y **mete el contenido crudo directamente en el prompt** —"extrae qué hace esta empresa, cómo fluye el dinero…"— sin ninguna defensa de inyección declarada.

Es una superficie de prompt injection de manual: contenido web no confiable → contexto del modelo, sin sanitización ni delimitadores. No es un bug de código con parche obvio; es una decisión de diseño con un riesgo que conviene mirar. Y es exactamente el tipo de patrón que un auditor de agentes debe señalar: no un `eval()` evidente, sino la cañería por la que entra texto que nadie controla.

## Honestidad sobre lo que el scanner NO hace

Aquí está la parte que la mayoría de lanzamientos omiten. Un scanner estático es **preciso** en lo declarativo: secretos hardcodeados en `mcp.json`, agentes "de solo lectura" con herramientas de escritura, dependencias sin fijar, descripciones de herramientas envenenadas. Ahí no falla.

Pero prompt injection y exfiltración dependen del **flujo de datos** —¿el input viene de una fuente no confiable?— y eso el análisis estático no puede probarlo. Así que esas comprobaciones son *best-effort*: cuando la señal es débil, el scanner emite un aviso informativo, no un hallazgo con peso. Prefiero una herramienta que admita sus límites a una que finja una precisión que no tiene. Esa honestidad *es* la característica.

## Es gratis, y por qué

El core es open source, licencia MIT: **[github.com/JAvito-GC/agent-audit-kit](https://github.com/JAvito-GC/agent-audit-kit)**. Sin registro, clónalo y córrelo. Corre donde corra Python 3.8+, sin dependencias, sin red, sin telemetría — tus configuraciones nunca salen de tu máquina.

Es gratis a propósito. El mercado de tooling de seguridad de agentes ya es open source; competir vendiendo un scanner contra herramientas gratis y bien mantenidas es perder el tiempo. Lo que aporto no es el software: es el ángulo de detección y el criterio de haber verificado esto a mano contra 64 repos reales.

## Cómo empezar

```bash
git clone https://github.com/JAvito-GC/agent-audit-kit
cd agent-audit-kit
python3 scanner/agent_audit.py /ruta/a/tus/agentes --lang es --json \
  | python3 scanner/report.py --auditor "Tu Nombre" > report.html
```

Apúntalo a tus agentes. Y si te devuelve un falso positivo, dímelo — sé bien lo que cuesta cazarlos.
