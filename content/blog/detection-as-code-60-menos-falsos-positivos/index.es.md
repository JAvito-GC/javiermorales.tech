---
title: "Detection-as-Code: Cómo Reduje los Falsos Positivos un 60%"
date: 2026-04-22
description: "Un programa sistemático de reducción de ruido en un entorno AWS multi-cuenta con cientos de detecciones SIEM, testing unitario y despliegue automatizado."
tags: ["Detection Engineering", "SIEM", "AWS", "Security"]
og_image: "/img/og-detection.png"
translationKey: "detection-as-code"
---

Cuando heredas una plataforma de detección con cientos de reglas en un entorno AWS multi-cuenta, el primer instinto es añadir más. Más reglas, más cobertura, más alertas.

El problema: **más alertas no significa más seguridad.** Significa más ruido, más fatiga de analista, y más alertas reales enterradas entre falsos positivos.

Este artículo explica cómo lideré un programa sistemático para reducir el volumen de falsos positivos un 60% sin sacrificar cobertura real.

## El Problema: Muerte por Alertas

El estado inicial:

- **Cientos de detecciones** en producción cubriendo cloud, identidad, SaaS y endpoint
- **Entorno multi-cuenta AWS** con docenas de cuentas, cada una con su propio patrón de comportamiento
- **Volumen de alertas insostenible**: el equipo de seguridad no podía distinguir lo crítico del ruido
- **Sin testing**: las reglas se desplegaban directamente, sin validación

```
                    ANTES
    ┌──────────────────────────┐
    │   CloudTrail  GuardDuty  │
    │   Identity    SaaS Logs  │
    │   Endpoint    VPC Flow   │
    └────────────┬─────────────┘
                 │
          ┌──────▼──────┐
          │    SIEM     │
          │ (cientos de │
          │  reglas)    │
          └──────┬──────┘
                 │
    ┌────────────▼────────────┐
    │   AVALANCHA DE ALERTAS  │
    │   (60% falsos positivos)│
    └─────────────────────────┘
```

## Paso 1: Audit de Telemetría

Antes de tocar una sola regla, hice un **audit completo de las fuentes de telemetría**. Descubrí:

- **Fuentes stale**: log sources críticos que llevaban meses sin enviar datos. Nadie se había dado cuenta porque no había monitorización del estado de las fuentes
- **Routing roto**: una porción significativa de detecciones no estaba llegando al equipo de seguridad por un fallo silencioso en la configuración de routing

El audit reveló que el problema no era solo las reglas — era la infraestructura debajo de ellas.

## Paso 2: Detection-as-Code

Cada detección se trata como código:

### Estructura de una Detección

```python
# detection: iam_role_creation_unusual_hours
# severity: medium
# tactic: persistence

def rule(event):
    return (
        event.get("eventName") == "CreateRole"
        and not is_known_automation(event)
        and is_outside_business_hours(event)
        and not is_infrastructure_role(event)
    )

def title(event):
    return f"IAM Role created outside business hours by {event.deep_get('userIdentity', 'arn')}"

def alert_context(event):
    return {
        "account": event.get("recipientAccountId"),
        "region": event.get("awsRegion"),
        "role_name": event.deep_get("requestParameters", "roleName"),
        "user": event.deep_get("userIdentity", "arn"),
    }
```

### Testing Unitario

Cada regla tiene tests con datos positivos y negativos:

```python
def test_rule_fires_on_manual_creation():
    event = create_event(
        eventName="CreateRole",
        hour=3,  # 3 AM
        user="arn:aws:iam::123:user/human"
    )
    assert rule(event) is True

def test_rule_ignores_terraform():
    event = create_event(
        eventName="CreateRole",
        hour=3,
        user="arn:aws:iam::123:role/terraform"
    )
    assert rule(event) is False
```

### Despliegue Automatizado

```
    ┌─────────┐    ┌──────────┐    ┌──────────┐
    │  Git    │───▶│  CI/CD   │───▶│  SIEM    │
    │  Push   │    │  Tests   │    │  Deploy  │
    └─────────┘    └──────────┘    └──────────┘
         │              │               │
    Detección     Unit tests      Regla activa
    como código   + linting       en producción
```

## Paso 3: Programa de Reducción de Ruido

La reducción sistemática siguió tres estrategias:

### 1. Infrastructure Role Baselining

La fuente #1 de falsos positivos: **roles de infraestructura haciendo cosas normales**.

Terraform, CI/CD, Lambda functions — todos generan eventos que parecen sospechosos pero son operación normal. Creé un sistema de baselining:

- Catálogo de roles de infraestructura por cuenta
- Patrón de comportamiento normal por rol
- Supresión dinámica: si el comportamiento encaja en el baseline, no alerta

### 2. Enriquecimiento Contextual

Cada alerta se enriquece con contexto antes de llegar al analista:

- **Identidad**: es un humano, servicio, o automatización?
- **Cuenta**: es producción, staging, o sandbox?
- **Historial**: esta actividad ha ocurrido antes?
- **Horario**: está dentro del horario laboral del equipo responsable?

### 3. Output Routing Optimization

No todas las alertas necesitan el mismo destino:

| Severidad | Destino | Tiempo de Respuesta |
|-----------|---------|-------------------|
| Critical  | PagerDuty + Slack | Inmediato |
| High      | Slack canal seguridad | < 1 hora |
| Medium    | Ticket automático | < 24 horas |
| Low/Info  | Dashboard solo | Revisión semanal |

## Paso 4: Optimización del Data Lake

El rendimiento de las consultas era otro cuello de botella. Logré una **mejora de rendimiento de más del 90%** en queries del SIEM:

- Re-arquitectura de infraestructura legacy de EC2 a Lambda event-driven
- Corrección de un bug crítico de pérdida de datos en el pipeline
- Optimización de particionado y compresión

## Resultados

Después de 6 meses de programa sistemático:

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Falsos positivos | Baseline | -60% | Reducción |
| Query performance | Baseline | +90% | Velocidad |
| Cobertura | X reglas | >X reglas | Más detecciones |
| Testing | 0% | 100% reglas | Unit tests |
| Fuentes stale | Desconocido | 0 | Monitorizadas |

## Lecciones

1. **Menos ruido > más reglas.** Una detección que genera 100 falsos positivos es peor que no tener detección — crea fatiga de alerta
2. **Audit tus fuentes primero.** Si tus logs están stale o tus alertas no llegan, da igual lo buenas que sean las reglas
3. **Trata las detecciones como código.** Testing, code review, CI/CD. Si no tiene tests, no se despliega
4. **El contexto es todo.** La misma acción puede ser un ataque o una operación normal. Sin contexto, es ruido
5. **Mide el ruido, no solo la cobertura.** Las métricas de cobertura solas incentivan más reglas, no mejores reglas

---

*Este artículo refleja patrones generales de detection engineering. Los detalles específicos de implementación son genéricos y no representan la arquitectura de ninguna organización concreta.*

---

**Artículos relacionados:**

- [De 8.000 a 3.000 alertas/semana con IA](/es/blog/de-8000-a-3000-alertas-semana-con-ia/) — el siguiente paso lógico: una vez reduces falsos positivos, automatizas el triage del volumen restante.
- [El IC Score: fórmula con IA para triage de alertas SOC](/es/blog/ic-score-formula-ia-triage-alertas-soc/) — la fórmula de scoring que complementa detecciones bien calibradas.
