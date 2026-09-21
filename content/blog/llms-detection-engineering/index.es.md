---
title: "LLMs en Detection Engineering: Dónde Aceleran y Dónde Mienten"
date: 2026-08-10
description: "Un flujo de trabajo real para usar LLMs en detection engineering —triaje, generación y refinamiento de reglas— sin degradar la calidad. Con la parte incómoda: dónde el modelo miente y cómo verificarlo."
summary: "Cómo un ingeniero solo usa LLMs para acelerar detection engineering sin bajar el listón: qué delegar, qué no, y cómo verificar cada salida antes de que toque producción."
translationKey: "llms-detection-engineering-donde-aceleran"
og_image: "/img/og-default.png"
draft: false
tags: ["Detection Engineering", "LLM", "AI-Driven Security Operations", "SIEM", "Security"]
---

Hay dos formas de equivocarse con los LLMs en detection engineering. La primera es no usarlos: seguir escribiendo cada regla a mano mientras el backlog crece más rápido de lo que despliegas. La segunda es peor: dejar que el modelo escriba detecciones y confiar en ellas porque "compilan" y "suenan bien".

Llevo meses usando LLMs a diario en un flujo de detección real, como ingeniero solo. La tesis es simple: **una persona con un LLM bien gobernado rinde como un equipo pequeño.** Pero solo si tratas al modelo como un becario rápido y confiado, no como un experto. Este post es el manual concreto: qué delego, qué no, y cómo verifico cada salida antes de que toque producción.

## Dónde el LLM acelera de verdad

**Triaje de la primera pasada.** El trabajo más caro de un detection engineer no es escribir reglas, es leer alertas. Un LLM con contexto suficiente —el evento crudo, el runbook, el histórico del activo— resume una alerta y propone hipótesis en segundos. No decide. Ordena. Yo paso de "50 alertas sin contexto" a "50 alertas con un resumen de dos líneas y una hipótesis clasificada por probabilidad". El tiempo hasta la primera decisión humana se desploma.

**Traducción entre dialectos de detección.** Tengo una lógica en Sigma y la necesito en el DSL del SIEM. O al revés. El LLM hace el 80% del trabajo mecánico de traducción de sintaxis. Lo que antes eran 20 minutos de consultar documentación son dos de revisión.

**El primer borrador de una regla.** Le describo el comportamiento —"acceso a Secrets Manager desde una IP nueva seguido de exfiltración a bucket externo en menos de cinco minutos"— y me devuelve un esqueleto: campos, ventana temporal, condiciones de correlación. Nunca es la versión final. Pero partir de un borrador estructurado en vez de una página en blanco cambia el ritmo del día.

**Generación de casos de prueba negativos.** Aquí el LLM brilla de forma poco intuitiva: es buenísimo inventando el tráfico benigno que hará saltar tu regla mal escrita. "Dame diez patrones legítimos que dispararían esta detección." La mitad son ruido; la otra mitad son falsos positivos que no había considerado. Eso vale oro.

## Dónde es peligroso confiar en él

**Umbrales y líneas base.** El LLM no conoce tu entorno. Cuando le pides "un umbral razonable de intentos de login fallidos", inventa un número que suena sensato —"cinco en diez minutos"— sin ninguna base en tu telemetría real. Ese número es una alucinación con formato de dato. Los umbrales salen de tus percentiles, no de la intuición estadística de un modelo entrenado con internet.

**Nombres de campos y semántica de logs.** Los modelos rellenan huecos con confianza. Te inventarán un campo `sourceIPAddress` que en tu esquema real se llama `src_ip`, o asumirán que un campo existe en un log donde no está. La regla parece correcta, compila en el linter, y no dispara nunca en producción. Este es el fallo silencioso más caro: **una detección que existe en el papel y no en la realidad.**

**Cobertura y sensación de completitud.** Si le preguntas "¿cubre esto la técnica X?", el LLM tiende a decir que sí. Es complaciente por diseño. Confundir su seguridad con cobertura real de amenazas es cómo acabas con un mapa ATT&CK lleno de casillas verdes y un adversario paseándose por los huecos.

**Lógica de correlación temporal.** En cuanto la detección implica secuencia y ventanas —"A, luego B, pero no C en medio, dentro de N minutos"—, la tasa de errores sutiles se dispara. Operadores de ventana mal puestos, condiciones que se solapan, `AND` donde iba `OR`. Compila. Está mal.

## El flujo que uso: el LLM propone, la telemetría dispone

La regla de oro: **el LLM genera, los datos verifican, el humano firma.** Ningún artefacto pasa a producción sin cruzar las tres puertas.

1. **Genera con contexto, no a ciegas.** Le doy el esquema real de mis logs, un par de reglas existentes como estilo, y el runbook. Contexto de más, no de menos. Un LLM sin tu esquema es un generador de plausibilidad.

2. **Verifica contra datos reales, siempre.** Toda regla candidata se ejecuta primero en modo *dry-run* contra 30-90 días de telemetría histórica antes de armarse. Si el LLM dice "esto detectará la amenaza y casi no dará falsos positivos" y el histórico devuelve 400 hits diarios, el modelo mentía. Los datos no. Este paso conecta directo con el programa de [detection-as-code que redujo mis falsos positivos un 60%](/blog/detection-as-code-60-menos-falsos-positivos/): sin testing contra datos, la velocidad del LLM solo acelera la generación de ruido.

3. **Revisa el diff, no la explicación.** Leo la lógica que escribió, no el párrafo con el que la justifica. La prosa del modelo es siempre convincente; la lógica es lo que se ejecuta. Reviso especialmente nombres de campos, operadores temporales y umbrales —los tres focos de alucinación.

4. **Versiona y atribuye.** Cada regla generada o modificada por LLM va marcada en el control de versiones. Si dentro de tres meses una detección se comporta raro, quiero saber si nació de un humano o de un borrador de modelo sin revisar a fondo.

## La parte incómoda

El LLM no te hace mejor detection engineer. Te hace *más rápido* en lo que ya sabes evaluar. Si no sabes leer una regla y oler que el umbral es inventado o que el campo no existe, el modelo solo acelera tus errores y te da la falsa sensación de cobertura. La productividad no viene de delegar el criterio —viene de delegar la mecánica y quedarte con el criterio.

El arbitraje de inteligencia es real: una persona con este flujo cierra en una tarde lo que antes era una semana. Pero el multiplicador se aplica sobre tu criterio, no lo sustituye. Multiplica por cero y te quedas en cero, más rápido.

Empieza pequeño. Un LLM para triaje de primera pasada y traducción de sintaxis, con verificación obligatoria contra datos, es una victoria segura hoy. Delegar el criterio de qué detectar y con qué umbral no lo será nunca.
