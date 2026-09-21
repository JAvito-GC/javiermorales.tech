---
title: "El coste oculto de los agentes en loop — una lectura de seguridad y FinOps"
date: 2026-06-17
description: "Los que te dicen que pongas agentes de IA en loops autónomos tienen tokens ilimitados. Tú no. Aquí tienes cómo leer el hype de los loops con lente de seguridad y de coste — y por qué la habilidad real es saber cuándo NO usar un agente."
summary: "'Loop engineering' es el título de la semana. Pero los ingenieros que lo promueven trabajan en las dispensadoras de tokens y nunca ven la factura. Desmonto el hype desde dos ángulos que el hype se salta —lo que cuesta y lo que le hace a tu modelo de control— y aterrizo en la regla que de verdad importa: el agente ejecuta decisiones, no las toma."
translationKey: "hidden-cost-agent-loops"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai", "finops", "claude-code", "agents"]
---

Hay una frase de Warren Buffett que le va perfecta a esta semana: nunca le preguntes a un barbero si necesitas un corte de pelo. Esta semana, los barberos de la IA decidieron que todos necesitábamos un repaso.

El repaso se llama *loop*. Y antes de que reescribas tu bio de LinkedIn a "Loop Engineer" —un título que tiene unas 72 horas de vida—, conviene leer la tendencia con dos lentes que los que la venden suelen saltarse: lo que cuesta, y lo que le hace a tu modelo de control.

---

## Qué es un loop, en realidad

Un loop es fácil de describir. Le das un objetivo a un agente —"arregla este test que falla", "tría estas alertas", "mantén la build en verde"— y en lugar de devolverte una respuesta, trabaja solo: lo intenta, revisa su propio output y repite hasta que el resultado pasa su propio listón. Puede lanzar subagentes que ejecutan subtareas en paralelo. No vuelves a promptearlo. Lo dejas correr.

El argumento es embriagador, y no es falso. Los ingenieros detrás de los grandes agentes de código describen decenas de estos loops corriendo a la vez: uno vigilando la CI, otro manteniendo los tests verdes, otro resumiendo feedback cada treinta minutos. Los arrancas y te vas. De verdad es un atisbo de cómo se va a hacer mucho trabajo.

Solo hay un detalle que el argumento omite.

---

## Detalle uno: cada iteración lleva un taxímetro encendido

La característica que define al loop —*intenta, falla, corrige, reintenta, hasta que esté perfecto*— es también la que define su coste. Cada iteración es una ida y vuelta a un modelo, y cada ida y vuelta se factura en tokens.

No tengo que teorizar con las cifras, porque hay creadores que han empezado a publicar las suyas. Uno documentó **3.377 $ de consumo de tokens en 28 días en una sola máquina** —frente a una suscripción de 220 $/mes—. En una segunda máquina, **8.560 $ en un mes**. Una sola tarea, un prompt que se abrió en un enjambre de agentes y corrió durante una hora y cuarenta minutos, costó alrededor de **140 $**. Un prompt.

Ahora súmale la economía del modelo. Cuando Anthropic lanzó Claude Fable 5 en junio de 2026, aterrizó como el modelo más capaz disponible —y con un precio de aproximadamente **el doble** por token que el Opus anterior—. Así que el consejo más ruidoso del mes se reduce a esto: *ejecuta la técnica que más iteraciones consume, sobre el modelo que más cuesta por iteración.* Viniendo, en varios casos, de gente cuya empresa les regala los tokens.

Ese es el barbero. Cuando alguien con presupuesto ilimitado de tokens te dice que los loops autónomos son el futuro, está describiendo su realidad, no la tuya. Para ellos, 50.000 $ al mes en tokens es un martes cualquiera. Tú y yo tenemos una cuota que se resetea cada semana y una factura a fin de mes. El consejo no es deshonesto —puede que los loops sean el futuro—, pero el coste se traslada por completo a quien lo sigue.

Esto es un problema de FinOps disfrazado de ingeniería. Y como todo problema de FinOps, la solución no es parar: es **medir antes de escalar**. No puedes razonar sobre un loop cuyo coste no ves. Antes de dejar treinta agentes corriendo toda la noche, tienes que responder a cuatro preguntas aburridas: cuánto gasto sumando todas las herramientas, cuánto me está rindiendo, cuánto vale cada tarea, y qué está corriendo ahora mismo. Si no puedes responderlas de memoria, estás apostando, no haciendo ingeniería.

---

## Detalle dos: un loop es una ampliación de tu superficie de ataque

Aquí está la parte que la conversación sobre el coste se salta, y la que más me importa.

En el momento en que te sacas a ti mismo del loop, suben dos cosas a la vez: tu apalancamiento y tu riesgo. Un sistema que solo corre cuando tú lo disparas es seguro de una forma aburrida: no pasa nada sin ti. Un sistema que se dispara solo, mientras duermes o estás en una reunión, es apalancamiento real. También es un proceso ejecutándose sin ningún humano que lea el output antes de que llegue a un cliente, recupere los datos equivocados o mande el mensaje equivocado a la lista equivocada.

Un loop autónomo es, desde la óptica de seguridad, un proceso desatendido con credenciales, acceso a red y capacidad de actuar. Tenemos una disciplina entera para eso, y nada de ella dice "déjalo correr y reza". Dice: mínimo privilegio, radio de explosión acotado, observabilidad y un botón de parada. Un loop que puede reintentar infinitamente necesita un techo de presupuesto igual que una cuenta de servicio necesita un límite de permisos: no porque esperes un abuso, sino porque el modo de fallo de *sin límite* es ilimitado.

Por eso mi propia automatización es deliberadamente aburrida. Los scrapers que hay detrás de un agregador de precios que llevo en solitario corren en crons fijos con topes duros, no en agentes razonando sobre cuándo dispararse. Son deterministas por diseño. Cuando algo sí necesita criterio, hay un humano en el loop por defecto, y se retira solo después de que el camino esté probado a fondo —no antes—.

---

## La regla que sobrevive al hype: máquina expendedora vs máquina tragaperras

El encuadre más útil que he visto sobre esto corta directo a través del ruido. Piensa en cada tarea como una elección entre una máquina expendedora y una tragaperras.

Una **máquina expendedora** es determinista. Mismo input, mismo output, siempre. Metes la moneda, pulsas E4, sale una Coca-Cola. Un flujo simple de `si pasa esto, entonces aquello` —recupera la facturación de la semana pasada, publícala en un canal— es una expendedora. Barata, predecible, prácticamente nunca se rompe, y no usa IA en absoluto.

Una **tragaperras** no es determinista. Tiras de la palanca y sale algo distinto cada vez. Eso es un agente de IA. Potente cuando el input es caótico y la tarea de verdad necesita razonar —leer correos no estructurados y redactar respuestas a medida—, pero cuesta más, falla de formas más raras, y cada tirada es, en pequeño, una apuesta.

```
┌────────────────────────────────────────────────┐
│  EXPENDEDORA  (workflow, sin IA)                │
│  determinista · barata · no se rompe            │
│  → triggers fijos, datos estructurados, si/ent. │
├────────────────────────────────────────────────┤
│  TRAGAPERRAS  (agente de IA / loop)             │
│  no determinista · cara · falla raro            │
│  → input caótico, razonamiento real, generación │
└────────────────────────────────────────────────┘
```

La habilidad que el ciclo de hype no te va a vender es saber cuál de las dos necesita de verdad una tarea. En un mundo donde todos gritan *IA, IA, IA*, la persona que sabe dar un paso atrás y decir "aquí no hace falta un agente —un script de diez líneas hace esto más barato, más rápido y con menos riesgo" destaca mucho más que quien mete un agente en cada tarea. Esa lectura demuestra que entiendes el problema, no solo la moda.

---

## Entonces, ¿deberías usar loops?

Sí —con la disciplina que los animadores se saltan—. Lee los artículos, adapta los patrones, deja correr tus agentes de noche si se ganan el sueldo. Pero ponles un techo de tokens igual que le pondrías un límite de permisos a una cuenta de servicio. Instrumenta el gasto antes de escalarlo. Y mantén la única línea que no se dobla:

**Deja que el agente del loop ejecute decisiones. No dejes que las tome.** El criterio no se delega. Los ingenieros que corren treinta agentes con el presupuesto de tokens de otro pueden permitirse estrellar el coche prestado las veces que quieran —no es suyo—. El tuyo sí. Condúcelo así.

---

## Llévate el framework listo para producción

Si estás metiendo agentes autónomos en flujos de trabajo reales, el trabajo de poner límites es el trabajo. Mi kit lo cubre: plantillas de modelo de amenazas, 12 playbooks de respuesta a incidentes para fallos de agentes de IA, mapeo de cumplimiento SOC 2 e ISO 27001, y una rúbrica de puntuación de postura de seguridad.

**[AI Agent Defense Kit](https://javiermoralesecurity.gumroad.com/l/ai-defense-kit)** — 49 $

---

*Para un tratamiento más profundo de las arquitecturas de defensa para sistemas de IA autónomos —mínimo privilegio, control del radio de explosión, aplicación en runtime y monitorización continua—, consulta mi libro [Securing Autonomous AI](/books/).*
