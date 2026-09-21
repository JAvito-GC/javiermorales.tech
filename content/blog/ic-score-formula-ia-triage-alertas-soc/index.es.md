---
title: "El IC Score: Una Fórmula con IA para el Triage de Alertas en un SOC"
date: 2026-06-09
description: "Cómo diseñé una fórmula de puntuación ponderada que combina 7 fuentes de señales, criticidad de activos e IA para hacer triage de alertas SOC en menos de 2 minutos con 95% de fidelidad."
summary: "Desglose práctico del IC Score: 7 señales ponderadas, multiplicadores de criticidad de activos y umbrales de decisión que redujeron nuestro tiempo medio de triage de 15 minutos a menos de 2."
translationKey: "ic-score-formula"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "soc", "ai", "detection-engineering", "automation"]
---

## El Problema: El Triage Manual No Escala

Nuestro SOC tenía un problema de escala que no se resolvía contratando más gente.

Cada mañana, la cola acumulaba más de 100 alertas esperando revisión humana. Cada alerta requería entre 15 y 30 minutos de investigación: extraer logs del SIEM, consultar feeds de threat intel, correlacionar con datos de identidad, revisar patrones históricos, evaluar la criticidad del activo. Multiplica eso por el volumen y tienes analistas ahogándose en trabajo repetitivo mientras alertas genuinamente peligrosas quedan enterradas en la pila.

El problema real no era solo la velocidad -- era la **consistencia**. Dos analistas investigando la misma alerta llegaban a conclusiones diferentes según qué fuentes de datos consultaban, qué tan profundo llegaban y cuánta fatiga acumulaban. No había puntuación estructurada, ni metodología repetible, ni criterios claros de escalación.

Necesitaba un sistema que puntuara alertas de forma determinista, usando todas las fuentes de señales disponibles, y que solo escalara las alertas que verdaderamente requerían juicio humano.

## Diseñando el IC Score: Una Fórmula de Puntuación Ponderada

El IC Score (Investigation Confidence Score) es un compuesto ponderado que extrae datos de 7 fuentes de señales, cada una contribuyendo un valor normalizado entre 0 y 1. Los pesos reflejan la fiabilidad y poder predictivo de cada fuente, calibrados durante meses de datos en producción.

### Fuentes de Señales y Pesos

| # | Fuente de Señal | Peso | Qué Mide |
|---|---|---|---|
| 1 | Threat Intelligence de IPs (enriquecimiento SIEM) | 30% | IPs maliciosas conocidas, reputación de ASN, anomalías geográficas |
| 2 | Puntuación de Threat Feeds | 20% | Coincidencias de IOCs contra feeds comerciales y abiertos |
| 3 | Consulta Histórica en Data Lake | 20% | Esta entidad o patrón ha aparecido en incidentes pasados? |
| 4 | Resumen de Triage con IA | 15% | Evaluación de severidad generada por LLM a partir del contexto de la alerta |
| 5 | Contexto del Empleado (consulta de identidad) | 10% | Rol, departamento, nivel de acceso, patrones de actividad recientes |
| 6 | Correlación de Threat Intelligence | 10% | Cruce con campañas activas y TTPs |
| 7 | Análisis de Payload | 5% | Pattern matching sobre el payload real del evento |

Los pesos suman 110% intencionalmente -- esto crea un efecto de techo natural donde una puntuación perfecta en todas las señales se limita a ~100 tras el paso de normalización.

### Multiplicador de Criticidad de Activos

No todos los activos son iguales. Una alerta en un controlador de dominio o una base de datos de producción merece más atención que una en un portátil de desarrollo. El multiplicador de criticidad ajusta la puntuación bruta:

| Nivel del Activo | Multiplicador | Ejemplos |
|---|---|---|
| Crown Jewel | x1.5 | Controladores de dominio, gestión de claves, bases de datos de producción |
| Sensible | x1.2 | APIs internas, pipelines CI/CD, endpoints ejecutivos |
| Normal | x1.0 | Estaciones de trabajo estándar, servicios no sensibles |

### La Fórmula

```python
def calculate_ic_score(signals: dict, asset_tier: str) -> float:
    """
    Calcula el Investigation Confidence Score para una alerta.
    
    signals: dict con claves coincidentes con SIGNAL_WEIGHTS, valores 0.0-1.0
    asset_tier: uno de 'crown_jewel', 'sensitive', 'normal'
    """
    SIGNAL_WEIGHTS = {
        "ip_threat_intel": 0.30,
        "threat_feed_score": 0.20,
        "historical_lookup": 0.20,
        "ai_triage_summary": 0.15,
        "employee_context": 0.10,
        "threat_intel_correlation": 0.10,
        "raw_payload_analysis": 0.05,
    }

    ASSET_MULTIPLIERS = {
        "crown_jewel": 1.5,
        "sensitive": 1.2,
        "normal": 1.0,
    }

    # Suma ponderada de señales normalizadas
    raw_score = sum(
        signals.get(source, 0.0) * weight
        for source, weight in SIGNAL_WEIGHTS.items()
    )

    # Aplicar multiplicador de criticidad del activo
    multiplier = ASSET_MULTIPLIERS.get(asset_tier, 1.0)
    final_score = min(raw_score * multiplier * 100, 100.0)

    return round(final_score, 1)
```

## Umbrales de Decisión

La puntuación sola no significa nada sin límites de acción claros. Tras semanas de ajuste contra datos históricos de incidentes, establecimos cuatro niveles:

| Rango | Acción | Justificación |
|---|---|---|
| 0-29 | **Auto-cierre** | Señales de baja confianza, patrones benignos conocidos, ruido informacional |
| 30-69 | **Reconocer y monitorizar** | Sospechoso pero evidencia insuficiente para escalar. Se crea ticket y se actualiza watchlist |
| 70-84 | **Escalar para revisión humana** | Alta confianza de actividad maliciosa. El analista investiga con contexto completo pre-cargado |
| 85+ | **Elegible para auto-contención** | Amenaza crítica en activo crítico. Respuesta automatizada (aislar host, revocar sesión) con notificación inmediata al analista |

El nivel de auto-contención (85+) es deliberadamente agresivo. Solo se activa cuando múltiples señales de alto peso convergen en un activo crown jewel. En la práctica, se dispara 2-3 veces por semana con una tasa de falsos positivos inferior al 1%.

## Resultados

Después de tres meses en producción:

- **Tiempo medio de triage:** < 2 minutos (antes 15-30 minutos)
- **Fidelidad de señales:** 95% (validada contra revisiones post-incidente de analistas)
- **Tasa de escalación humana:** < 5% del volumen total de alertas
- **Precisión de auto-cierre:** 99.2% (verificada semanalmente por analista rotativo)
- **Capacidad de analistas liberada:** aproximadamente 40 horas/semana redirigidas a threat hunting

La mayor victoria no fue la velocidad -- fue la **consistencia**. Cada alerta ahora recibe la misma profundidad de investigación independientemente del tamaño de la cola, la hora del día o la fatiga del analista.

## Lecciones Aprendidas

**Empieza con umbrales conservadores, ajusta con el tiempo.** Nuestro rango inicial de auto-cierre era 0-19, no 0-29. Lo ampliamos solo tras validar seis semanas de decisiones contra revisión manual. Acelerar la expansión de umbrales es así como te pierdes incidentes reales.

**Incluye siempre un camino de override humano.** Cualquier analista puede sobreescribir manualmente cualquier decisión automatizada. El sistema marca el override, registra el razonamiento y lo retroalimenta a la calibración. En el primer mes, los overrides nos ayudaron a identificar dos fuentes de señales que necesitaban ajustes de peso.

**Registra cada decisión para auditabilidad.** Cada cálculo de IC Score se almacena con su desglose completo de señales, la decisión tomada y un timestamp. Cuando la dirección pregunta "por qué se cerró esta alerta?" -- puedes mostrar exactamente qué señales contribuyeron y qué umbrales aplicaron. Esto es innegociable para compliance y para mejora continua.

**La calibración de pesos nunca termina.** Re-evaluamos los pesos trimestralmente usando una matriz de confusión de alertas puntuadas vs. incidentes confirmados. La señal de triage con IA empezó con un peso del 10% y se ganó su 15% tras demostrar precisión consistente. Trata los pesos como parámetros vivos.

**La fórmula es la parte fácil.** El verdadero reto de ingeniería es construir pipelines de enriquecimiento fiables que alimenten señales normalizadas a la función de puntuación en segundos. Si tu consulta de threat intel tarda 45 segundos, tu objetivo de triage en 2 minutos ya está muerto.

---

El IC Score no reemplaza a analistas cualificados -- es un multiplicador de fuerza. Asegura que la atención humana va donde más importa, y que el 95% de alertas que son ruido se gestionan deterministicamente sin quemar a tu equipo.

---

**Artículos relacionados:**

- [De 8.000 a 3.000 alertas/semana con IA](/es/blog/de-8000-a-3000-alertas-semana-con-ia/) — el sistema completo de triage donde el IC Score es el motor de decisión.
- [14 agentes IA eliminaron nuestro backlog: la arquitectura SOC multi-tier](/es/blog/14-agentes-soc-autonomo-arquitectura/) — la evolución a 14 agentes especializados que usan el IC Score en Tier 1.
- [Detection-as-Code: cómo reduje los falsos positivos un 60%](/es/blog/detection-as-code-60-menos-falsos-positivos/) — reducir ruido antes del triage mejora la señal que llega al IC Score.
