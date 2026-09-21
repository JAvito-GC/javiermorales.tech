---
title: "Tu health check te está mintiendo"
date: 2026-06-25
lastmod: 2026-09-01
description: "Un 200 OK te dice que el servicio está vivo. No te dice nada sobre si el dato que hay dentro es verdad. Así es como un panel de monitorización puede seguir en verde mientras tu producto se pudre en silencio — y el hábito barato que lo caza."
summary: "Disponibilidad y corrección son dos preguntas distintas, y casi toda la monitorización solo responde la primera. Te enseño cómo un sistema puede pasar todos los health checks mientras sirve datos rotundamente falsos, por qué el verde es el color más peligroso de un panel, y la consulta que convierte a un mentiroso en testigo."
translationKey: "health-check-lies"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "monitoring", "data-quality", "detection-engineering", "observability"]
---

Hay un dicho viejo de pilotos: los instrumentos no mienten, pero solo te cuentan aquello para lo que fueron diseñados. Un altímetro marcará tan tranquilo 900 metros mientras vuelas de frente contra una montaña, porque medir la montaña nunca fue su trabajo.

Casi toda nuestra monitorización es un altímetro. Mide lo que no importa, con una confianza absoluta.

---

## Dos preguntas, una sola respuesta

Todo health check responde una pregunta: *¿está el servicio vivo?* Hace ping a un endpoint, recibe un `200 OK`, pinta el panel de verde y se vuelve a dormir. Esto es genuinamente útil. Cuando la máquina se cae, quieres enterarte en segundos, no cuando te escribe un cliente.

Pero "¿está el servicio vivo?" no es la pregunta que de verdad le importa a tus usuarios. A ellos les importa *¿es correcta la respuesta?* Y esas dos preguntas no tienen casi nada que ver entre sí.

Un servicio puede estar vivo y sirviendo basura. Una base de datos puede responder en 4 milisegundos con un número rotunda y precisamente equivocado. La capa HTTP no tiene ninguna opinión sobre si los bytes que devuelve son verdad. Solo sabe que los devolvió.

Ahí está el hueco por donde los productos mueren en silencio. No en un crash — un crash es ruidoso, un crash te despierta a las 3 de la mañana, un crash se arregla. Mueren en el verde. Mueren mientras todas las gráficas dicen que todo va bien.

---

## Un panel verde sobre un campo podrido

Déjame hacerlo concreto con un patrón que me encuentro una y otra vez, anonimizado.

Imagina un sistema que ingiere texto del mundo real, sucio — anuncios, tickets, mensajes de soporte, lo que sea — y clasifica cada elemento en una categoría limpia de una tabla de referencia. Para clasificar usa *fuzzy matching*: coge la entrada sucia, busca la entrada más parecida en la tabla por similitud de texto, y la asigna.

El fuzzy matching es maravilloso hasta que deja de serlo. Tiene un modo de fallo que ningún health check del mundo va a cazar: siempre devuelve *algo*. Pídele que empareje una cadena que no tiene buena respuesta, y no dará error. No devolverá null. Te entregará la opción menos mala con cara de póker y una puntuación de similitud que parece plausible.

Así que una entrada que debería clasificarse como "Tipo 700" — una variante moderna y distinta — acaba emparejada con la cadena más cercana de la tabla, que resulta ser "Tipo 600", una más antigua que comparte casi todo el nombre. El match puntúa alto. El registro se escribe. El endpoint devuelve `200 OK`. El panel sigue verde.

Y ahora tu producto está mintiendo. No cayéndose — mintiendo. Le muestra al usuario una categoría, una métrica, una recomendación construida sobre una etiqueta que es sencillamente falsa. Hasta el agregado parece razonable: las estadísticas de "Tipo 600" salen plausibles, porque las cosas que se esconden bajo esa etiqueta son objetos reales con valores reales. El número es internamente coherente y externamente falso. Ese es el peor tipo de error, porque nada en él dispara una alarma.

He visto un sistema funcionar semanas en exactamente ese estado, con todos los checks pasando, mientras una parte considerable de sus registros principales apuntaba a la cosa equivocada. La monitorización no estaba rota. Estaba respondiendo a la perfección la pregunta para la que fue diseñada — *¿está el servicio vivo?* — Sí. El servicio estaba vivo. El servicio estuvo vivo todo el rato que estuvo equivocado.

---

## Por qué el verde es el color más peligroso

La razón por la que esto es peligroso, y no solo molesto, es psicológica. Un panel rojo crea urgencia. Un panel verde crea *confianza* — y la confianza es justo lo que no quieres apuntando a un sistema que no has verificado de verdad.

El verde le dice al ingeniero de guardia que se relaje. El verde le dice al product manager que el dato está bien, que lance la feature. El verde te dice a ti, tres semanas después cuando un usuario por fin se queja, que sospeches primero del usuario, porque mira — está todo verde. El panel se convierte en una coartada. Convierte un problema de calidad de dato en "será cosa tuya".

La gente de seguridad lo reconocerá al instante, porque es el mismo fallo que un SIEM que ingiere logs pero parsea la mitad en los campos equivocados. El pipeline está "sano". Los eventos por segundo parecen normales. Y tus detecciones están ciegas en silencio, porque el campo que dice `user` en realidad guarda un hostname, y nada comprueba que el contenido signifique lo que el esquema afirma. La disponibilidad está en verde. La corrección está ardiendo. Nadie mira la corrección.

---

## La misma trampa, por el otro lado: cuando el check falla en abierto

La historia del fuzzy match es un check que sigue verde mientras el *dato* se pudre. Pero exactamente la misma clase de fallo puede golpear al propio transporte del check — y caí de lleno en ello la mañana que escribí esto.

Volví de unos días fuera y corrí mi health check de infra antes de tocar nada. Me dijo que mis dos sitios en producción estaban caídos:

```
✗ HTTP: motoradar.es → 000
✗ HTTP: javiermorales.tech → 000
```

No estaban caídos. Los dos habían estado sirviendo tráfico todo el tiempo. Corrí curl a mano con el desglose de tiempos, y los números contaron la historia real:

```
$ curl -w "code %{http_code} | connect %{time_connect}s | tls %{time_appconnect}s\n" https://motoradar.es
curl: (35) Recv failure: Connection reset by peer
code 000 | connect 0.068s | tls 0.000s
```

El TCP conectó en 68ms — *algo* en el camino aceptó la conexión — pero el TLS nunca completó (`time_appconnect` es `0.000`) y curl salió con código **35**, un reset a mitad del handshake. Un control rápido lo zanjó: `curl https://www.cloudflare.com` reseteaba igual. El problema no eran mis sitios, era mi propia salida a internet — un middlebox de inspección TLS en el camino estaba matando el HTTPS saliente. La prueba: el mismo check corrido desde el propio servidor devolvía `200` en ambos.

El check medía *mi capacidad de alcanzar el sitio desde esta máquina concreta* y lo reportaba como *la disponibilidad del sitio*. Son preguntas distintas — la misma separación disponibilidad-vs-corrección de antes, solo que una capa más abajo. Mi caso falló *en cerrado* (un falso rojo — molesto pero seguro), pero cambia un detalle y la misma señal te da un falso verde: un timeout tratado como "asumir que está arriba", un reset del lado del origen mientras tu máquina de monitorización tiene la salida limpia. Y el falso verde es el que no investigas.

La lección se generaliza en una regla: **nunca te fíes de un proxy en lugar de la cosa misma. Ejerce el comportamiento real y lee el resultado real.**

| Señal-proxy (puede fallar en abierto) | Ejerce el comportamiento |
|---|---|
| `200 OK` | Descarga la página y comprueba que el *contenido* esperado está en el cuerpo |
| Servicio `active` | Confirma que produjo su *output* esperado este ciclo |
| Un timestamp reciente | Confirma que llegó un registro genuinamente *nuevo*, no un toque batch |
| Puerto abierto | Habla el protocolo real y lee la respuesta |
| "La build está en verde" | Corre el camino de código y comprueba qué *devuelve* |

---

## El arreglo es un hábito, no una herramienta

La buena noticia es que la cura es barata. No es una plataforma nueva. No es un proveedor. Es una *segunda pregunta*, hecha de forma programada, en el mismo aliento que la primera.

Después de "¿está vivo?", añade: **"¿sigue el dato significando lo que dice significar?"**

En la práctica eso es un puñado de aserciones baratas corriendo al lado de tu check de uptime:

- **Coherencia entre campos.** Si un registro está etiquetado como "Tipo 600", ¿contiene el texto original del que salió realmente un "600"? Cuando la etiqueta y la evidencia no coinciden, eso es una bandera — no hace falta revisión humana para levantarla, solo para resolverla. En el caso del fuzzy match, esta única comprobación habría cazado casi todos los registros malos, porque la respuesta correcta estuvo todo el tiempo ahí, en el texto original.
- **Cordura de la distribución.** ¿Triplicó una categoría su número de filas de la noche a la mañana? ¿Incluyó de repente un rango de precios valores físicamente imposibles para ese objeto? Los outliers en los extremos suelen ser la señal de que algo aguas arriba empezó a etiquetar mal.
- **La trampa del "valor imposible".** Elige las cosas que nunca deberían pasar — un producto de 1985 con precio de uno de 2025, o un campo que de repente está vacío en casi todas las filas nuevas cuando antes venía relleno — y alerta sobre ellas directamente. Son mucho más honestas que un ping de uptime.
- **Estrés concurrente, no petición única.** Un health check que lanza una petición y recibe un `200` te dice que el camino feliz funciona para un usuario. Lanza veinte a la vez y descubres si funciona en las condiciones que tus usuarios crean de verdad.

Nada de esto es exótico. La razón por la que no se construye no es la dificultad — es que la primera pregunta es *fácil y se siente completa*. Un tick verde es satisfactorio. Escribir la aserción que dice "y, por cierto, demuestra que el dato no es basura" exige admitir que vivo y correcto son cosas distintas, y que solo has estado midiendo una de ellas.

---

## Mide la montaña

El altímetro no está equivocado. Solo responde una pregunta más pequeña que la que te mata. Añadir un único instrumento que mire *hacia delante, al terreno* — y no hacia abajo, al número — es la diferencia entre un vuelo con confianza y un agujero con confianza en el suelo.

Así que la próxima vez que un panel te diga que todo va bien, hazle la pregunta que no fue diseñado para responder. Saca un registro al azar y comprueba que su etiqueta coincide con su evidencia. Cuenta las cosas que deberían ser imposibles. Si el sistema está sano, has gastado cinco minutos en confirmarlo con honestidad. Si no lo está, acabas de enterarte antes que tus usuarios — que, al final, es el único tipo de monitorización que merece el nombre.

El verde no es un destino. Es una afirmación. Oblígale a demostrarse.
