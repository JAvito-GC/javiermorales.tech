---
title: "Tu lista de bloqueo hace match dentro de las palabras"
date: 2026-09-09
description: "Un término de bloqueo de tres letras que filtraba scooters borró en silencio todos los anuncios legítimos que mencionaban una pieza 'reforzada' — porque hacía match como substring, dentro de una palabra. Por qué los filtros de exclusión fallan en silencio, y el arreglo de un carácter que los detection engineers seguimos olvidando."
summary: "Perdí datos reales durante semanas por un término de bloqueo de tres letras que coincidía dentro de una palabra inocente. Los filtros de exclusión no dan error cuando se equivocan: simplemente quitan cosas, y 'cero resultados' es idéntico a 'no hay tales datos'. Una historia sobre matching por substring, límites de palabra, y por qué el filtro más peligroso es el que nunca ves dispararse."
translationKey: "blocklist-substring"
draft: false
og_image: "/img/og-default.png"
tags: ["seguridad", "detection-engineering", "calidad-de-datos", "falsos-positivos", "regex"]
---

Imagina un portero con una lista de nombres vetados. La lista dice "Rob". Así que le niega la entrada a Rob — y también a Roberto, a Robin y a la señora cuya acreditación pone "Problema resuelto". Técnicamente está haciendo su trabajo. Le dijeron que bloqueara "Rob", y todos esos nombres *contienen* "Rob". La lista nunca dijo *solo nombres completos*, así que él nunca lo supuso.

La mayoría de las listas de bloqueo son ese portero.

---

## Las tres letras que borraron mis datos

Tengo un proyecto paralelo que scrapea anuncios de segunda mano y clasifica cada uno en una categoría. En algún punto del pipeline hay un filtro de exclusión: una lista de palabras que significan "esto no es el tipo de vehículo que quiero". Scooters, por ejemplo. Una entrada de esa lista era `forza` — Honda fabrica un scooter que se llama Forza, y yo no quería scooters.

Durante semanas, una categoría que yo *sabía* que tenía stock aparecía casi vacía. Sin error. Sin caída. Sin nada en rojo. El scraper corría, el pipeline estaba en verde, la base de datos respondía cada consulta en milisegundos. Solo que, calladita, guardaba una fracción de los anuncios que debería.

El filtro hacía match de `forza` como substring. Y "reforzado" lleva esas letras dentro: re‑**forza**‑do. Cada anuncio que presumía de un basculante *reforzado*, una maneta *reforzada*, un lo-que-fuera *reforzado*, cargaba las letras f‑o‑r‑z‑a en la barriga de una palabra inocente. El portero los echó a todos. Anuncios reales, comunes y deseables, borrados en la puerta porque su descripción presumía de una pieza reforzada.

El arreglo era un solo concepto: límites de palabra. `\bforza\b` en vez de `forza`. Hacer match de la palabra, no de las letras. Es el tipo de cambio que se hace en treinta segundos — después de costarte tres semanas de datos que faltaban.

---

## Por qué nunca lo viste dispararse

Aquí está la parte que debería inquietarte, porque en realidad no va de un scraper.

Un filtro de exclusión falla en la única dirección que no puedes ver. Cuando *incluye* algo mal, puedes encontrar la fila mala — está en tu tabla, visible y auditable. Cuando *excluye* algo mal, no hay nada que encontrar. La prueba es la ausencia de prueba. "Cero resultados" y "lo filtré todo correctamente" producen exactamente la misma salida: nada.

Así que el fallo es silencioso por construcción. No salta ninguna excepción — el filtro hizo justo lo que escribiste; solo que *significaba* algo que tú no querías. Ningún conteo parece mal — no tienes una referencia de cuántos deberían estar ahí. El único síntoma es un número un pelín más bajo de lo que tu instinto esperaba, y los instintos no avisan a nadie.

Una caída es ruidosa. Un número equivocado es callado. Un número *ausente* es silencioso. Los sistemas no mueren en rojo; mueren en verde, sosteniendo una base de datos que está, con toda confianza, incompleta.

Es la imagen especular de aquel fallo del *health check* que se queda en verde: allí un filtro dejaba **entrar** lo que no debía; aquí deja **fuera** lo que sí debía. El mismo silencio, en dirección contraria.

---

## Los detection engineers hacemos esto sin parar

Si escribes reglas de detección, ya has sentido el escalofrío, porque esto es un martes cualquiera en el SOC.

- Bloqueas un binario malicioso llamado `psexec`. Tu match por `contains` suprime también la telemetría de `psexecsvc` que necesitabas — y cualquier cosa que un fabricante haya tenido a bien llamar `mypsexec_wrapper`.
- Pones `corp.com` en la allowlist para cortar ruido. Tu match por substring ahora también confía en `corp.com.evil.ru` y en `notcorp.com`.
- Filtras un hostname ruidoso, `scan01`. Se come en silencio `scan01`, `scan012`, `descan01-legacy` y el único host que importaba.

Cada uno de estos es el bug de Forza con placa de seguridad: una primitiva de matching operando sobre *substrings* cuando tú querías *tokens*. Y en detección la dirección del fallo es peor. Que mi scraper tire anuncios me cuesta datos. Que tu filtro de SIEM tire eventos te cuesta la alerta que te contrataron para cazar. La regla dice "sana". Los eventos por segundo se ven normales. La cobertura ha desaparecido en silencio, y al panel le da igual.

---

## Los hábitos que lo cazan

Tres, baratos, por orden de valor.

**Ancla tus matches.** Límites de palabra, igualdad de token completo, `startswith`/`endswith` cuando de verdad quieres decir el principio o el final. El `in` y el `contains` a pelo casi nunca son lo que quieres sobre texto humano. Si tu librería te deja hacer match contra una lista de *tokens* en vez de contra un churro de caracteres, hazlo.

**Instrumenta tus exclusiones.** Este no lo hace nadie. Todo filtro que quita cosas debería contar lo que quita y, de vez en cuando, muestrearlo. Una lista de bloqueo que de repente tira el 40% donde antes tiraba el 4% te está intentando decir algo — y la única forma de oírlo es haber estado contando desde el principio. Los filtros silenciosos no deberían existir. Haz que dejen rastro.

**Testea el filtro contra lo que debe *conservar*.** Todo el mundo comprueba que la lista de bloqueo bloquea lo malo. Casi nadie escribe el test inverso: un fixture de entradas legítimas, que deben sobrevivir, que el filtro procesa y debe dejar pasar intactas. Ese único fichero — *"estos son reales y no deben excluirse jamás"* — habría cazado `forza` contra *reforzado* en la primera pasada, en lo que tardas en guardarlo.

---

## El resumen incómodo

La monitorización de disponibilidad responde *¿está levantado?* La corrección responde *¿es correcta la respuesta?* Los filtros de exclusión abren una tercera pregunta, más taimada que las dos: *¿lo que falta se supone que debe faltar?* — y casi nada de lo que tienes la está vigilando.

El filtro más peligroso de tu sistema no es el que lanza errores. Es el que, calladito, con toda confianza y correcto-según-su-propio-código, quita cosas que necesitabas y lo llama una ejecución limpia.

Tres letras. Dentro de una palabra. Durante tres semanas.

Ancla tus matches. Cuenta lo que tiras. Y escribe el test que demuestra que lo bueno sobrevive.
