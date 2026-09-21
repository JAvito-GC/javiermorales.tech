---
title: "Tu bypass 'imposible' tiene fecha de caducidad"
date: 2026-06-30
description: "Hace tres semanas cerré un caso: un geo-filtro imposible de saltar, punto. Hoy el mismo filtro me ha entregado todo lo que había dado por perdido. No cambié una línea de código. Lo que cambió fue la infraestructura de debajo, y esa es la parte que casi ningún análisis tiene en cuenta."
summary: "Un geo-filtro que había documentado como 'imposible de saltar, caso cerrado' se volvió trivial sin que yo tocara nada, porque una variable que trataba como constante no lo era. Esto es una nota de campo sobre hacer ingeniería inversa al geo-filtro de un marketplace en tiempo real, los tres detalles no documentados que deciden si respeta tus coordenadas o las ignora en silencio, y la lección de fondo: todo bypass que escribes tiene caducidad, porque la infraestructura del otro lado se mueve mientras tus notas siguen quietas."
translationKey: "impossible-bypass-expiry"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "reverse-engineering", "scraping", "apis", "geo-fencing"]
---

Hace tres semanas escribí una frase de la que estaba seguro: *"No hay forma de capturar esta región sin una IP de salida ubicada ahí. Caso cerrado."*

Estaba haciendo ingeniería inversa al geo-filtro de un marketplace español de anuncios clasificados, de esos donde la gente vende motos de segunda mano. Necesitaba anuncios de una región insular concreta, y el sitio sencillamente no me los daba. Probé todo lo que prueba una persona razonable, documenté el callejón sin salida y pasé página. Los casos se cierran por buenos motivos.

Hoy ese mismo filtro me ha entregado exactamente lo que había dado por perdido. No cambié nada en mi código. Y ese hueco —entre "imposible" y "trivial", sin una sola edición de por medio— es de lo que va este post.

---

## La premisa que traté como constante

La cosa con un caso cerrado es que se apoya en suposiciones que dejas de cuestionar. La mía era la IP de salida.

El marketplace geo-filtra el tráfico anónimo por la **IP que ve**, no por las coordenadas que le mandas. Eso lo había verificado. Así que mi conclusión salía limpia: mis peticiones salían por un proxy móvil cuyo CGNAT geolocalizaba en la capital, a cientos de kilómetros de la región que quería. Manda la latitud y longitud que te dé la gana: la IP dice capital, así que te dan la capital. No hay bypass. Listo.

La lógica era impecable. La premisa estaba podrida.

Porque "la IP de salida geolocaliza en la capital" no es una ley de la física. Es un hecho sobre la configuración de NAT de un operador en un día concreto. Y los operadores cambian. En algún momento de esas tres semanas, el tráfico del proxy empezó a salir por un operador distinto, y la IP de ese operador geolocalizaba *en la región exacta que yo había descartado.* Mi "imposible" era una foto fija de una infraestructura que no es mía, y la infraestructura se movió.

Esta es la trampa, y merece nombrarse con precisión: **había archivado una variable del entorno bajo la etiqueta "constante".** Todo lo que venía después era razonamiento correcto construido sobre un hecho con fecha de caducidad que nunca comprobé.

---

## Lo que de verdad cuesta "verificar, no asumir"

Lo primero que hice hoy no fue escribir código. Fue ejecutar un comando: *¿dónde geolocaliza mi IP de salida ahora mismo?* Dos segundos. La respuesta reescribió una conclusión que mantuve durante tres semanas.

Quiero detenerme aquí, porque "verifica siempre" es de esos consejos que suenan gratis y no lo son. Verificar es barato. *Saber qué hay que re-verificar* es la parte cara. Yo re-testeo mi propio código constantemente. Nunca se me había ocurrido re-testear la geolocalización de una IP que no controlo, porque mentalmente la había ascendido de "dependencia externa" a "hecho zanjado". Ese ascenso es el bug de verdad. El código estaba bien. El modelo mental tenía la caché sucia.

Si operas cualquier cosa que depende del comportamiento de un tercero —una API, un proxy, un rate limiter, un clasificador aguas arriba— haz una lista de las cosas que has decidido que son estables. Esa lista es tu verdadera superficie de ataque. No el código. Las suposiciones.

---

## Los tres detalles que lo deciden todo

Con la IP ya correcta, todavía tenía que conseguir que el filtro respetara mis coordenadas. El camino ingenuo —lanzar un navegador headless contra la página de búsqueda— seguía devolviendo la región equivocada, porque ese camino pega contra un endpoint que filtra por IP e *ignora por completo las coordenadas de la URL.* Bien para la región que ahora coincidía con mi IP; inútil para la de al lado.

Así que me fui a la API de búsqueda directa del marketplace. Esa sí respeta las coordenadas, pero solo si aciertas exactamente con tres detalles no documentados. Cada uno, por su cuenta, rompe el geo-filtro en silencio y te entrega resultados nacionales que *parecen* plausibles. Encontré los tres de la única manera en que se encuentran estas cosas: ejecutando la petición, mirando fijamente los códigos postales que volvían y preguntándome por qué estaban mal.

**1. El orden anula la distancia, sin avisar.** Añade `order_by=newest` y la API ordena los resultados a nivel nacional y tira el filtro de distancia por la borda. Con mis coordenadas objetivo *más* newest: 40 resultados, cero de la región. La misma petición *sin* newest: 5 resultados, todos en la región correcta. El parámetro de orden no estaba ordenando, estaba anulando el geo-filtro. Nada en la respuesta te lo dice. Los 40 resultados equivocados llegan con un 200 OK y plena confianza.

**2. Un precio mínimo devuelve cero.** La API acepta un parámetro `min_price`. Mándalo, y el endpoint devuelve cero ítems: ni error, ni aviso, solo una lista vacía idéntica a "no hay stock aquí". El filtro espera un *rango* de precio; un mínimo a secas envenena toda la consulta. Moví el filtrado de precio a mi propio código y los anuncios volvieron.

**3. La forma de la keyword cambia la pesca.** Buscar `moto+trail` devolvía la cuarta parte de lo que devolvía `trail` a secas. La API hace match de frases multi-palabra mucho más estricto que de tokens sueltos. La consulta "más específica" era la peor consulta.

Ninguno lanza excepción. Ninguno deja log. Cada uno devuelve un resultado limpio, poblado y *equivocado* que vas a aceptar a menos que compruebes el único campo que importa: en mi caso, el código postal de cada ítem que volvía.

---

## El patrón, dicho a las claras

Quita las motos y el marketplace y esto es lo que queda, y generaliza mucho más allá del scraping:

- **Un bypass es una relación, no un hecho.** Describe cómo se comporta tu sistema contra el sistema de otro *en un momento concreto*. El otro lado no te debe un changelog. Los operadores re-NATean, las APIs reordenan, los clasificadores se reentrenan. El día que escribes "imposible", arranca un cronómetro.
- **"Cerrado" es el estado más peligroso que puede tener un hallazgo.** Un problema abierto se reexamina. Uno cerrado se cita. Mi nota de hace tres semanas no solo estaba caducada: me estaba apartando activamente de volver a comprobarla, porque ya la había "resuelto". El coste de un caso cerrado en falso es todo lo que dejas de hacer por culpa de él.
- **Un 200 OK no es una respuesta correcta.** Los tres detalles devolvían éxito. El éxito es la ausencia de un error, no la presencia de la verdad. Lo único que me marcó la diferencia fue validar el contenido real contra lo que decía ser: los códigos postales, no la línea de estado.

Reabrí el caso, migré las consultas de la región a la API directa con los tres detalles bien puestos, y los anuncios que había declarado inalcanzables empezaron a fluir. El arreglo me llevó una tarde. Darme cuenta de que el arreglo era *posible* me llevó un `curl` contra una suposición que había dejado de cuestionar hacía tres semanas.

Esa es la disciplina que merece la pena mantener: no "verifica todo", que es agotador y vago, sino **mantén una lista escrita de lo que has decidido que es constante, y ponle fecha de caducidad a cada línea.** Esos son los hechos que se pudrirán en silencio mientras construyes encima de ellos, y son justo los que nadie vuelve a comprobar, precisamente porque ya están archivados como "hecho".
