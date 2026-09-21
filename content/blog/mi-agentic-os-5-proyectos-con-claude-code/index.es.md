---
title: "Mi Agentic OS: Cómo Gestiono 5 Proyectos Solo con Claude Code"
date: 2026-05-19
description: "Un sistema real donde una persona gestiona 5 negocios mediante skills codificados, arquitectura de agentes IA y un sistema de defensa de 6 capas. Sin equipo. Sin VA. Solo un Agentic OS."
summary: "Gestiono 5 proyectos solo — sin equipo, sin VA. Esta es la arquitectura de agentes IA que lo hace posible: 23 skills, 6 capas de defensa, sesiones paralelas, y un fichero de configuración que lo orquesta todo."
translationKey: "agentic-os"
draft: false
og_image: "/img/og-default.png"
tags: ["ai", "claude-code", "productivity", "solopreneur", "automation"]
---

Gestiono 5 proyectos solo. Sin equipo. Sin asistente virtual. Sin agencia. Solo yo y una arquitectura de agentes IA que llevo meses construyendo.

Los proyectos: un agregador de precios de motos que scrapea 7 fuentes en toda España, una marca personal con blog Hugo, una tienda Shopify, un negocio de templates en Etsy, y una plataforma de matching para riders. Dominios diferentes, stacks diferentes, audiencias diferentes.

El hilo común: todos funcionan a través de un único sistema que llamo mi **Agentic OS**.

Esto no es un pitch de curso. No es un framework teórico. Es lo que uso cada día, y voy a enseñarte exactamente cómo funciona.

## Qué Es un Agentic OS

Un Agentic OS es tu vida y negocio codificados en dominios, skills y automatizaciones — ejecutados por agentes IA que entienden tu contexto sin repetirlo.

Es la capa de sistema operativo entre tú (el que decide) y la ejecución (código, deploys, contenido, research). En vez de cambiar de contexto entre 5 proyectos, el sistema sabe dónde lo dejaste. Conoce la infraestructura, las reglas de seguridad, los targets de deploy, el estado de cada proyecto.

La diferencia clave frente a "usar ChatGPT": **persistencia de estado**. Mi sistema no arranca de cero. Carga contexto, aplica límites de seguridad, y ejecuta workflows multi-paso mediante skills codificados.

## Las 4 Capas

### Capa 1: CLAUDE.md — La Config Maestra

Todo empieza con un solo fichero: `CLAUDE.md`. Es el set de instrucciones que cada sesión de IA carga al arrancar. Contiene:

- **Mapa de proyectos**: 5 proyectos con rutas, estado, descripción y stack técnico
- **Reglas de seguridad**: qué nunca se commitea, qué nunca se referencia, patrones de credenciales bloqueados
- **Infraestructura**: detalles del VPS, config DNS, targets de deploy
- **Herramientas compartidas**: servidores MCP, scrapers, transcriptores
- **Protocolo de sesión**: cómo se comunican los agentes paralelos

```
# Estructura simplificada de CLAUDE.md

## Projects
| Proyecto    | Path                  | Estado  |
|-------------|----------------------|---------|
| MotoRadar   | projects/enduroscout/ | PRIMARY |
| Brand       | projects/personal-brand/ | ACTIVE |
| Vulkaan     | projects/shopify/    | ACTIVE  |
| Etsy        | projects/etsy/       | ACTIVE  |
| Knubby Club | projects/knubby/     | PARKED  |

## Security - MANDATORY
1. Zero huella corporativa
2. Nunca hardcodear credenciales
3. Identidad git separada
4. Todos los secretos en ~/.klaudio-creds.sh

## Skills (23 codificados)
/triage, /deploy, /seo-audit, /deep-research...
```

Este fichero es la fuente única de verdad. Cuando abro una sesión nueva, la IA ya sabe qué proyecto es prioritario, cuál está aparcado, y qué límites no puede cruzar.

### Capa 2: Skills — 23 Operaciones Codificadas

Los skills son workflows reutilizables almacenados como ficheros estructurados. Cada uno tiene un patrón de activación, pasos de ejecución y formato de salida.

Ejemplos de mis 23 skills:

- `/triage` — Recibe una lista de URLs (videos YouTube, artículos, herramientas), extrae contenido, puntúa cada uno sobre 25, y genera markdown estructurado con veredictos BUILD/WATCH/SKIP
- `/deploy <target>` — Un solo comando para desplegar cualquier proyecto al VPS. Gestiona Docker builds, config nginx, SSL, health checks
- `/seo-audit` — Crawlea hasta 500 páginas, delega en 15 sub-agentes especialistas (rastreabilidad, Core Web Vitals, datos estructurados, etc.), genera un health score
- `/deep-research` — Research multi-fuente con gestión de citas, scoring de evidencia, y output PDF con template McKinsey
- `/copywriting` — Generación de copy de marketing usando frameworks probados (PAS, AIDA, BAB) con variantes A/B

El poder está en la **composición**. Puedo decir "triagea estas 12 URLs, y para todo lo que puntúe BUILD, redacta una estrategia de contenido" y encadena skills automáticamente.

### Capa 3: Sistema de Defensa — 6 Capas de Guardias Automáticos

Cuando das acceso real a agentes IA sobre tu infraestructura, necesitas guardrails. Mi sistema de defensa se ejecuta en cada llamada a herramienta:

```
┌─────────────────────────────────────┐
│       LLAMADA A HERRAMIENTA         │
└──────────────────┬──────────────────┘
                   │
         ┌─────────▼─────────┐
         │  PRE-TOOL HOOK    │  Bloquea credenciales,
         │  (enforcer.sh)    │  cruce corporativo,
         │                   │  operaciones destructivas
         └─────────┬─────────┘
                   │ PASS
         ┌─────────▼─────────┐
         │  HERRAMIENTA      │
         │  SE EJECUTA       │
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  POST-TOOL HOOK   │  Logging de auditoría,
         │  (guard.sh)       │  scan de inyección,
         │                   │  detección de leak
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  SUBAGENT GUARD   │  Bloquea sub-agentes
         │                   │  de extraer credenciales,
         │                   │  acceder a paths corp
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  INTEGRITY CHECK  │  Verificación SHA256
         │                   │  de ficheros de defensa
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  ON-STOP HOOK     │  Recordatorio de cambios
         │                   │  sin commit, log violaciones
         └─────────────────────┘
```

No es paranoia — es higiene operacional. El pre-tool hook bloquea 14 patrones de credenciales. El post-tool hook escanea respuestas MCP buscando prompt injection. El integrity check verifica que ningún fichero de defensa ha sido manipulado.

Resultado: 99/100 en mi propio framework de auditoría.

### Capa 4: Session Relay — Comunicación entre Agentes Paralelos

A menudo ejecuto múltiples sesiones de Claude simultáneamente — una en scrapers de MotoRadar, otra en contenido del blog, otra en research SEO.

El problema: están aisladas. No ven el trabajo de las demás.

La solución: un bus de mensajes ligero (`session-relay.py`):

```bash
# Sesión A (motoradar) termina una actualización de scraper:
python3 scripts/session-relay.py send \
  --from motoradar --to all \
  --topic action \
  --body "Scraper mundimoto actualizado - ahora trae 265 listings con provincias"

# Sesion B (brand) comprueba al arrancar:
python3 scripts/session-relay.py check --unread
# > [motoradar→all] action: Scraper mundimoto actualizado...
```

Cada sesión comprueba mensajes no leídos al arrancar. Tras cambios significativos, difunden lo que hicieron. Mi "equipo" — que soy solo yo con sesiones IA paralelas — se mantiene coordinado sin cambiar manualmente de contexto entre terminales.

## Ejemplos Reales

### Triagear 12 URLs en 3 Minutos

Recopilo videos de YouTube, artículos y herramientas durante la semana. Cuando tengo un lote, ejecuto `/triage`:

```
Input:  12 URLs (mix de YouTube, artículos, repos GitHub)
Output: Markdown estructurado con:
        - Resumen de cada pieza
        - Puntuación /25 (relevancia, accionabilidad, calidad)
        - Veredicto: BUILD / WATCH / SKIP
        - Notas de implementación específicas para items BUILD

Tiempo: ~3 minutos para 12 URLs
```

El skill transcribe videos via yt-dlp, obtiene artículos via WebFetch con fallback al VPS, puntúa contra mis prioridades actuales, y genera un fichero de decisión accionable.

Último lote: 12 URLs, 6 items BUILD que alimentaron directamente nuevas funcionalidades.

### Deploys con un Solo Comando

```bash
/deploy motoradar
```

Eso es todo. Por detrás:
1. SSH al VPS
2. Pull del código más reciente
3. Migraciones de base de datos si las hay
4. Restart de contenedores Docker
5. Verificar que nginx sirve
6. Health check de los endpoints API
7. Reportar estado

Sin debuggear Dockerfiles. Sin "espera, ¿en qué servidor era eso?" Sin runbooks de despliegue que seguir manualmente.

### Auditorías SEO Automatizadas

```bash
/seo-audit motoradar.es
```

Crawlea el sitio, identifica problemas en 9 categorías (rastreabilidad, indexabilidad, seguridad, estructura de URLs, móvil, Core Web Vitals, datos estructurados, renderizado JavaScript, IndexNow), genera una lista de acciones priorizadas. Corre en paralelo con hasta 15 sub-agentes especialistas.

Lo ejecuto mensualmente en mis dos sitios. Los problemas se arreglan en la misma sesión.

## Arbitraje de Inteligencia

La tesis detrás de todo esto: **1 persona + arquitectura IA = output de equipo**.

Lo llamo arbitraje de inteligencia. La brecha entre lo que un operador solo puede producir con infraestructura IA adecuada versus lo que la mayoría piensa que requiere un equipo — esa brecha es la oportunidad.

Un setup tradicional para 5 proyectos requeriría 1-2 devs, un redactor, un especialista SEO, alguien de DevOps y un PM para coordinar.

Mi setup elimina el overhead de coordinación. El CLAUDE.md **es** el PM. Los skills **son** los especialistas. El session relay **es** la daily stand-up.

El cuello de botella se desplaza de la ejecución a la toma de decisiones — exactamente donde debería estar un humano.

## Cómo Empezar

No necesitas 23 skills el primer día. Empieza con:

1. **Un fichero CLAUDE.md** que mapee tus proyectos y reglas
2. **Un skill** para tu tarea más repetitiva (deploy, creación de contenido, research)
3. **Un pre-tool hook** que bloquee leaks de credenciales

Después, itera. Cada vez que te encuentres explicando el mismo contexto dos veces, codifícalo. Cada vez que ejecutes un proceso multi-paso manualmente, conviértelo en skill.

El sistema se acumula. El mes 1 tienes 3 skills. El mes 3 tienes 15. Para el mes 6, operas a un nivel que habría requerido un equipo pequeño doce meses atrás.

---

El sistema completo es open source: [github.com/JAvito-GC/klaudio](https://github.com/JAvito-GC/klaudio)

Si estás construyendo algo similar, me gustaría saber de ello. Encuéntrame en [LinkedIn](https://www.linkedin.com/in/javiermoralesgc/) o en [javiermorales.tech](https://javiermorales.tech).

---

**Artículos relacionados:**

- [Harness Engineering: 6 capas de defensa para Claude Code](/es/blog/harness-engineering-6-capas-defensa-claude-code/) — análisis técnico del sistema de defensa mencionado en la Capa 3.
- [Cómo instalé OpenClaw en local gratis](/es/blog/como-instale-openclaw-local-gratis/) — setup del nodo Ubuntu/OpenClaw que forma parte de este Agentic OS.
- [Cómo construí un sistema de guardrails para agentes IA](/es/blog/como-construi-guardrails-para-agentes-ia/) — el proyecto open source de guardrails en detalle.
