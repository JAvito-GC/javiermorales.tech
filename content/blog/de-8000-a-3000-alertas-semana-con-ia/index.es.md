---
title: "De 8.000 a 3.000 alertas/semana: cómo automaticé el triaje de seguridad con IA"
date: 2026-04-22
draft: false
translationKey: "alert-triage-ai"
description: "Cómo construí un sistema multi-agente con IA que redujo un 65% el ruido de alertas de seguridad, automatizó el 82% de los cierres y convirtió 45 minutos de triaje matutino en 5."
tags: ["seguridad", "ia", "automatización", "soc", "mcp", "agentes"]
categories: ["Ingeniería de Seguridad", "IA"]
author: "Javier Morales"
---

Cada lunes por la mañana, abría el panel de alertas y me encontraba con lo mismo: más de 8.000 alertas acumuladas de la semana anterior. La mayoría eran ruido. Falsos positivos, duplicados, eventos de bajo riesgo que alguien configuró como "críticos" hace tres años y nadie se atrevió a tocar. Sabía cuáles eran basura con solo mirar el título. Pero aun así, había que revisarlas.

Si trabajas en seguridad, conoces esta historia. La fatiga de alertas no es un concepto abstracto --- es la razón por la que los equipos de SOC tienen una rotación brutal y por la que incidentes reales se pierden entre el ruido.

Decidí que era hora de que una IA hiciera lo que yo hacía mentalmente cada mañana: clasificar, correlacionar y cerrar lo obvio. Esto es lo que construí y los resultados que obtuve.

## El problema real: no son las alertas, es el contexto

El volumen bruto de alertas no es el verdadero problema. El problema es que cada alerta requiere **contexto** para tomar una decisión:

- ¿Este usuario tiene historial de comportamiento anómalo?
- ¿Este endpoint ya está en una investigación abierta?
- ¿Este evento ya fue triado la semana pasada con el mismo patrón?
- ¿La IP de origen aparece en nuestras listas de exclusión?

Un analista senior responde estas preguntas en segundos porque tiene **años de contexto** en la cabeza. Un analista junior tarda 5-10 minutos por alerta porque necesita consultar 3-4 plataformas diferentes.

Mi hipótesis: si un agente de IA pudiera acceder a las mismas plataformas y mantener memoria del contexto histórico, podría tomar las mismas decisiones que un analista senior para el 80% de los casos rutinarios.

## La arquitectura: 9 agentes especializados

No construí un mega-prompt que lo hace todo. Construí un sistema de 9 agentes especializados, cada uno con un rol específico, coordinados por un orquestador central.

```
┌─────────────────────────────────────────────────────┐
│                   ORQUESTADOR                       │
│          (enrutamiento + priorización)              │
└──────────┬──────────┬──────────┬────────────────────┘
           │          │          │
    ┌──────▼──┐ ┌─────▼────┐ ┌──▼──────────┐
    │ TRIAJE  │ │ INVEST.  │ │  REPORTING  │
    │         │ │          │ │             │
    │ Clasif. │ │ Enriq.   │ │ Resúmenes  │
    │ Dedup.  │ │ Correl.  │ │ Métricas   │
    │ Scoring │ │ Timeline │ │ Escalación │
    └────┬────┘ └────┬─────┘ └──────┬──────┘
         │           │              │
    ┌────▼───────────▼──────────────▼──────┐
    │         CAPA MCP (6+ conectores)     │
    │                                      │
    │  SIEM ─ Ticketing ─ Identidad ─ EDR │
    │  Threat Intel ─ CMDB ─ Memoria       │
    └──────────────────────────────────────┘
```

### Por qué multi-agente y no un solo prompt

La razón es práctica: un solo prompt con contexto de 6 plataformas, historial de alertas y reglas de decisión explota el context window rápidamente. Además, cada agente puede usar un modelo diferente según la complejidad de su tarea:

- **Agentes de triaje**: modelo rápido y barato (clasificación rutinaria)
- **Agentes de investigación**: modelo potente (razonamiento complejo)
- **Agentes de reporting**: modelo estándar (generación de texto estructurado)

### MCP: el pegamento que lo conecta todo

La pieza clave fue el **Model Context Protocol (MCP)**. En lugar de construir integraciones API custom para cada plataforma, MCP permite que los agentes "hablen" con las herramientas de seguridad de forma estandarizada.

Cada conector MCP expone las capacidades de una plataforma como herramientas que el agente puede invocar:

- **SIEM**: buscar eventos, obtener detalles de alerta, consultar logs
- **Ticketing**: crear/actualizar/cerrar tickets, buscar incidentes previos
- **Identidad**: consultar historial de usuario, verificar permisos, revisar sesiones
- **EDR**: estado de endpoint, procesos, indicadores de compromiso
- **Threat Intel**: reputación de IPs/dominios/hashes
- **CMDB**: propietario del activo, criticidad, entorno

### Memoria persistente: el ingrediente secreto

Uno de los mayores aciertos fue implementar **memoria persistente** entre sesiones. El sistema recuerda:

- Patrones de alertas ya triados y su resolución
- Falsos positivos recurrentes y sus firmas
- Contexto de investigaciones en curso
- Decisiones previas del analista humano (feedback loop)

Esto significa que la segunda vez que aparece un patrón idéntico, el agente no necesita re-investigar desde cero. Simplemente aplica la misma decisión con una referencia al caso anterior.

## Los resultados: números reales

Después de 3 meses de iteración y refinamiento, estos son los números:

| Métrica | Antes | Después | Cambio |
|---------|-------|---------|--------|
| Alertas/semana | 8.000+ | ~3.000 | **-65%** |
| Triaje matutino | 45 min | 5 min | **-89%** |
| Cierres automatizados | 0% | 82%+ | -- |
| Eventos procesados/semana | manual | 200+ | -- |
| Cobertura de automatización | 0% | 78% | -- |

### Desglose del 65% de reducción

No todo es "la IA cerró alertas". La reducción viene de varias fuentes:

1. **Deduplicación inteligente (~25%)**: el sistema agrupa alertas que son variantes del mismo evento. En lugar de 15 alertas por un escaneo de puertos desde la misma IP, ves 1 alerta agrupada con contexto consolidado.

2. **Cierre automático de falsos positivos conocidos (~30%)**: patrones que llevan meses generando ruido y que siempre se cierran sin acción. El sistema los identifica y cierra con documentación.

3. **Enriquecimiento que cambia la prioridad (~10%)**: alertas que parecen críticas pero que, al consultar el contexto (usuario en vacaciones, endpoint en mantenimiento, IP interna conocida), bajan a informativas.

### Lo que NO automaticé

El 22% restante que requiere intervención humana incluye:

- Alertas con indicadores de compromiso nuevos (no vistos previamente)
- Cualquier alerta que implique datos de clientes o PII
- Escalaciones a equipos externos
- Cambios en reglas de detección

Esto es deliberado. La IA no toma decisiones destructivas ni irreversibles.

## 5 lecciones que aprendí construyendo esto

### 1. Empieza en modo solo-lectura

Las primeras 4 semanas, el sistema solo podía **leer y recomendar**. No cerraba nada automáticamente. Cada recomendación se comparaba con la decisión real del analista.

Esto generó dos cosas fundamentales:
- Un dataset de entrenamiento implícito (recomendación vs. decisión real)
- Confianza del equipo (nadie quiere que una IA cierre alertas sin supervisión desde el día 1)

Solo cuando la tasa de acuerdo superó el 95% activé los cierres automáticos para las categorías de menor riesgo.

### 2. La regla 80/20 es brutal en seguridad

El **80% de las alertas siguen 5-6 patrones**. En serio. Los analicé:

1. Escaneos de puertos / reconocimiento desde IPs conocidas
2. Intentos de login fallidos por debajo del umbral de bloqueo
3. Reglas de DLP disparadas por documentos internos legítimos
4. Cambios de configuración programados (mantenimiento)
5. Alertas de red por tráfico a CDNs / servicios cloud legítimos
6. Duplicados de la misma detección en múltiples fuentes

Si puedes automatizar estos 6 patrones, ya has eliminado el 80% del ruido. No necesitas resolver el problema general de "IA que entiende todas las alertas de seguridad".

### 3. Human-in-the-loop no es opcional

Diseñé el sistema con 3 niveles de autonomía:

- **Auto-close**: patrones de bajo riesgo con alta confianza (>95%). Se cierra y se documenta.
- **Auto-enrich + recomendar**: riesgo medio. Se enriquece el contexto, se sugiere una acción, pero un humano aprueba.
- **Solo notificar**: riesgo alto o patrón nuevo. Se escala inmediatamente con todo el contexto recopilado.

El modelo nunca decide sobre lo que no ha visto antes. Eso es trabajo humano.

### 4. Mide todo desde el día 1

Antes de escribir una sola línea de código para los agentes, construí el dashboard de métricas. Cada decisión del sistema se logea con:

- Alerta original (hash + categoría)
- Decisión tomada (cerrar / escalar / enriquecer)
- Confianza del modelo
- Tiempo de procesamiento
- Si un humano la revisó después y qué decidió

Esto no es solo para justificar el proyecto ante gestión. Es para **detectar drift**. Si la tasa de acuerdo con los analistas baja del 90%, algo cambió --- ya sea en las detecciones, en el entorno o en el modelo.

### 5. La ingeniería de detección mejora como efecto secundario

El efecto más inesperado: al tener datos limpios sobre qué alertas son ruido y por qué, las conversaciones sobre **tuning de detecciones** se volvieron mucho más productivas.

Ya no es "creo que esta regla genera muchos falsos positivos". Es "esta regla generó 342 falsos positivos en 30 días, todos del mismo patrón, aquí están los datos". Las decisiones de tuning pasan de ser políticas a ser basadas en datos.

## Qué viene después: el feedback loop

El siguiente paso es cerrar el ciclo: que el sistema no solo trie alertas, sino que **proponga cambios en las reglas de detección** basándose en los patrones de falsos positivos acumulados.

Imagina:

> "La regla X ha generado 1.200 alertas en 90 días. El 98% fueron cerradas como falso positivo por el patrón Y. Recomendación: añadir exclusión para el patrón Y o reclasificar como informativa."

Esto convierte un sistema reactivo (triaje) en uno proactivo (mejora continua de detecciones). Es la diferencia entre apagar fuegos y prevenir incendios.

## Para quién es esto

Si estás en un equipo de seguridad con más alertas de las que puedes procesar (spoiler: casi todos), no necesitas un producto enterprise de "AI SOC". Necesitas:

1. **Acceso API a tus plataformas** (SIEM, ticketing, identidad)
2. **Un LLM con capacidad de tool-use** (MCP o function calling)
3. **Paciencia para el modo solo-lectura** (4-6 semanas mínimo)
4. **Métricas desde el día 1**

El sistema que construí no es un producto. Es una solución específica para un problema específico. Pero la arquitectura --- agentes especializados + MCP + memoria persistente --- es replicable para cualquier flujo de trabajo de operaciones de seguridad.

La pregunta no es si la IA puede hacer triaje de alertas. Ya puede. La pregunta es cuántas horas de tu semana estás dispuesto a seguir gastando en trabajo que una máquina puede hacer igual de bien.

---

*Si estás construyendo algo parecido o tienes preguntas sobre la arquitectura, escríbeme. Siempre es más fácil la segunda vez.*
