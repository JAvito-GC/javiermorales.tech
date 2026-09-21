---
title: "Cómo Construí un SOC Autónomo con MCP + Claude"
date: 2026-04-22
description: "Arquitectura de una plataforma de operaciones de seguridad autónoma que integra SIEM, identidad, cloud y ticketing mediante Model Context Protocol y agentes IA especializados."
tags: ["MCP", "Claude API", "Security", "AI Agents"]
og_image: "/img/og-soc.png"
translationKey: "autonomous-soc"
---

Un SOC (Security Operations Center) típico tiene un problema fundamental: **demasiadas alertas, demasiado poco contexto, y demasiado poco tiempo.**

Un analista recibe una alerta. Abre el SIEM. Busca los logs. Cambia a la consola de identidad. Verifica el usuario. Abre el ticketing. Comprueba si hay incidentes previos. Vuelve al SIEM. Todo manual, todo lento, todo repetitivo.

Este artículo explica cómo construí una plataforma que automatiza ese flujo completo.

## La Arquitectura: MCP como Columna Vertebral

Model Context Protocol (MCP) es el estándar que permite a un modelo de lenguaje conectarse con herramientas externas de forma estructurada. En vez de darle al modelo acceso directo a APIs, MCP define un protocolo limpio:

```
    ┌─────────────────────────────────────────────┐
    │              Claude (LLM)                    │
    │   Razonamiento + Decision + Respuesta       │
    └──────────────────┬──────────────────────────┘
                       │ MCP Protocol
    ┌──────────────────▼──────────────────────────┐
    │              MCP Servers                      │
    ├──────────┬───────────┬──────────┬───────────┤
    │  SIEM    │ Identity  │  Cloud   │ Ticketing │
    │  Server  │  Server   │  Server  │  Server   │
    └──────────┴───────────┴──────────┴───────────┘
         │          │           │           │
    ┌────▼───┐ ┌────▼───┐ ┌────▼───┐ ┌────▼────┐
    │ Panther│ │  Okta  │ │  AWS   │ │  Jira   │
    │        │ │        │ │        │ │         │
    └────────┘ └────────┘ └────────┘ └─────────┘
```

### Por qué MCP y No Llamadas API Directas?

1. **Separación de concerns**: el modelo razona, los servidores MCP ejecutan
2. **Seguridad**: cada servidor tiene permisos mínimos y auditoría independiente
3. **Modularidad**: añadir una nueva fuente es crear un nuevo servidor, no reescribir el agente
4. **Estándar abierto**: cualquier modelo compatible con MCP puede usar los mismos servidores

## Los Agentes: Especialización por Nivel

No uso un agente genérico para todo. Cada nivel de investigación tiene su propio agente especializado:

### Agente de Triaje (Tier 1)

El primer respondedor. Recibe la alerta y hace la evaluación inicial:

```
Alerta entrante
    │
    ▼
┌─────────────────────────┐
│   Agente de Triaje      │
│                         │
│ 1. Parsear alerta       │
│ 2. Enriquecer contexto  │
│    - Usuario (Identity) │
│    - Cuenta (Cloud)     │
│    - Historial (SIEM)   │
│ 3. Clasificar           │
│    - FP / TP / Unknown  │
│ 4. Decidir              │
│    - Cerrar             │
│    - Escalar            │
│    - Investigar mas     │
└─────────────────────────┘
```

Este agente maneja el 70-80% de las alertas. La mayoría son falsos positivos que se cierran con contexto suficiente: "Es Terraform haciendo lo que hace Terraform."

### Agente de Investigación (Tier 2)

Cuando el triaje necesita ir más profundo:

- Correlación temporal: qué más pasó en esa cuenta en las últimas 24 horas?
- Análisis de comportamiento: es este patrón normal para este usuario?
- Expansión de indicadores: hay otros usuarios o cuentas afectados?
- Búsqueda en vulnerabilidades: tiene esta cuenta exposiciones conocidas?

### Agente Forense (Tier 3)

Para incidentes confirmados:

- Timeline completo de la cadena de ataque
- Mapeo a MITRE ATT&CK
- Recomendaciones de contención
- Borrador de reporte de incidente

## Integraciones: 6+ Plataformas

Cada plataforma tiene su servidor MCP dedicado:

| Plataforma | Función | Operaciones |
|-----------|---------|-------------|
| SIEM | Detección y logs | Buscar alertas, consultar logs, obtener contexto |
| Identity Provider | Gestión de identidad | Info usuario, MFA status, sesiones activas |
| Cloud APIs | Infraestructura | Estado de recursos, configuración, permisos |
| Ticketing | Gestión de incidentes | Crear tickets, buscar precedentes, actualizar estado |
| Collaboration | Comunicación | Notificaciones, escalación, aprobaciones |
| Vulnerability Scanner | Postura de seguridad | Vulnerabilidades por asset, CVEs activos |
| Endpoint Management | Dispositivos | Estado del dispositivo, software instalado |

## El Flujo Completo

Un ejemplo real (anonimizado):

```
09:15 — Alerta: "Unusual API call from new IP in production account"

09:15 — Agente Triaje:
        → SIEM: obtener detalles de la alerta
        → Identity: verificar usuario — humano, ingeniero DevOps
        → Cloud: verificar la cuenta — produccion
        → SIEM: buscar actividad previa del usuario — primera vez desde esta IP
        → Clasificación: NEEDS_INVESTIGATION

09:16 — Agente Investigación:
        → SIEM: actividad completa del usuario últimas 48h
        → Identity: cambios recientes en el usuario (nuevo dispositivo?)
        → Cloud: qué recursos tocó desde esta IP?
        → Vulnerability: la cuenta tiene exposiciones?
        → Conclusión: Usuario en VPN nueva (oficina remota nueva).
           Patrón consistente con su rol. No indicadores maliciosos.
        → Acción: Cerrar como FP, actualizar baseline de IPs

09:17 — Total: 2 minutos automatizados vs 45 minutos manuales
```

## Resultados

| Métrica | Manual | Con IA | Mejora |
|---------|--------|--------|--------|
| Tiempo medio de triaje | 45 min | 5 min | 9x |
| Cobertura automatizada | — | 78% | De alertas resueltas sin humano |
| Workflows creados | — | 15+ | Reutilizables |
| Ahorro semanal | — | 7+ horas | Tiempo de analista |

## Arquitectura Defensiva

Un agente IA con acceso a 6+ plataformas de seguridad es un target de alto valor. La seguridad del propio sistema es crítica:

### Capas de Defensa

1. **Verificación de integridad**: SHA256 checksums de todos los archivos de configuración del agente
2. **Escaneo de prompt injection**: todas las respuestas de MCP se escanean antes de procesarse
3. **Permisos mínimos**: cada servidor MCP tiene solo las operaciones que necesita, nada más
4. **Auditoría**: cada llamada a herramienta se registra con timestamp, parámetros y resultado
5. **Guardrails**: reglas que bloquean operaciones destructivas o acceso fuera de scope

### Monitoreo del Agente

El propio agente está monitorizado:

- Watchdog que verifica que el agente responde
- Alertas si el agente toma decisiones fuera del patrón normal
- Rate limiting en llamadas a APIs externas
- Fallback manual documentado para cada flujo automatizado

## Lecciones Aprendidas

1. **Empieza por el triaje, no por la investigación.** El 80% del valor está en clasificar rápidamente lo que es ruido
2. **MCP > llamadas API directas.** La estandarización permite iterar rápido y mantener seguridad
3. **Agentes especializados > agente genérico.** Un agente que hace todo no hace nada bien
4. **El fallback manual es obligatorio.** Cada flujo automatizado necesita un procedimiento documentado para cuando el agente falle
5. **Asegura al asegurador.** Si tu agente de seguridad no está protegido, has creado un nuevo vector de ataque

---

*Este artículo refleja patrones generales de automatización de SOC con IA. Los detalles son genéricos y no representan la arquitectura de ninguna organización concreta.*

---

**Artículos relacionados:**

- [De 8.000 a 3.000 alertas/semana con IA](/es/blog/de-8000-a-3000-alertas-semana-con-ia/) — los resultados concretos de automatizar el triage con este tipo de arquitectura.
- [14 agentes IA eliminaron nuestro backlog: la arquitectura SOC multi-tier](/es/blog/14-agentes-soc-autonomo-arquitectura/) — la evolución de esta arquitectura a 14 agentes especializados en 5 niveles.
- [Guardrails para agentes de seguridad IA en producción](/es/blog/guardrails-agentes-seguridad-produccion/) — cómo asegurar agentes que tienen acceso privilegiado a tu infraestructura.
