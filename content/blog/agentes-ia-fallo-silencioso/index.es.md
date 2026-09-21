---
title: "Hace un mes escribí que los health checks mienten. Esta semana me mintió el mío"
date: 2026-07-27
description: "Escribí que un panel en verde no demuestra que un sistema haga su trabajo. Luego descubrí que dos de mis propios agentes llevaban semanas fallando en silencio, y ninguno me avisó. Un post-mortem sobre fail-open, fail-closed, y por qué predicar algo no te vacuna contra ello."
summary: "En «Tu health check te está mintiendo» defendí que disponibilidad y corrección son preguntas distintas. Un mes después me tocó comerme mis palabras: dos agentes míos degradaron y murieron en silencio durante semanas. Esta es la parte que aquel post no contaba —cómo se siente estar del lado ciego— y la distinción que aprendí a golpes: fail-open contra fail-closed."
translationKey: "agentes-fallo-silencioso"
draft: false
og_image: "/img/og-default.png"
tags: ["detection-engineering", "ai-security", "observability", "automation"]
---

Hace un mes publiqué [un post sobre por qué los health checks mienten](/blog/health-check-lies/): que un `200 OK` te dice que el servicio está vivo, no que el dato que sirve sea verdad, y que el verde es el color más peligroso de un panel. Lo escribí con la seguridad del que ve el error desde fuera.

Esta semana me tocó verlo desde dentro. Dos de mis propios agentes llevaban semanas fallando, y ninguno me avisó. Escribir sobre un fallo no te vacuna contra él —resulta que te lo pone más en evidencia—, así que aquí está la parte que aquel post no contaba: cómo se siente estar del lado ciego, y una distinción que entonces no hice y ahora no se me olvida.

## El síntoma

Tengo dos agentes pequeños en un servidor de casa. Uno resume cada mañana las noticias de seguridad y me las manda por Telegram. El otro genera borradores de artículos a partir de un calendario. Los dos hablan con un LLM vía API, con la clave guardada —creía yo— en un fichero de credenciales.

Estaba cambiando el modelo por uno más barato cuando lancé el agente de digest para probar. Funcionó: mensaje en el Telegram, titulares ordenados, "digest enviado" en el log. Verde.

Salvo que el resumen inteligente —el que elige las 3 noticias que importan y las analiza— no estaba. Solo los titulares crudos. El agente había estado enviando algo que *parecía* un digest durante semanas, y el panel de mi cabeza seguía en verde porque el mensaje llegaba puntual cada mañana. Exactamente lo que había descrito en junio, ocurriéndome a mí sin que lo viera.

## La causa raíz: la clave que nunca estuvo

El fichero de credenciales del que leían los scripts no contenía la clave de la API. Nunca la tuvo. Vivía en otro sitio, y en algún refactor los scripts se quedaron leyendo del fichero equivocado. Cargaban la clave como cadena vacía, llamaban a la API con `Authorization: Bearer ` en blanco, y recibían un **HTTP 401**.

Un bug de config de manual. Lo interesante no es el bug. Es que mis dos agentes reaccionaron al *mismo* 401 de dos formas opuestas —y una era mucho peor que la otra—.

## Fail-open contra fail-closed

Aquí está la distinción que en el post de los health checks no llegué a nombrar, y que es la que de verdad importa.

**El agente de digest fallaba open.** Tenía un `try/except` alrededor de la llamada. Al llegar el 401, capturaba la excepción, escribía un discreto "resumen fallido" en un log que nadie lee, y **seguía adelante** mandando el digest con solo titulares. Desde fuera, todo normal. La degradación era invisible.

**El agente de blog fallaba closed.** Sin manejo de errores. El 401 lo tumbaba entero. El cron lo ejecutaba, petaba, y el error se perdía porque nadie miraba la salida del cron.

Uno degradaba en silencio. El otro moría en silencio. Y si tengo que elegir cuál me da más miedo, elijo el primero sin dudar. Un sistema que se cae acabas viéndolo: algo deja de llegar, alguien se queja. Un sistema que **sigue entregando una versión degradada de sí mismo** puede durar meses, porque produce justo lo suficiente para no levantar sospechas. Es el «panel verde sobre un campo podrido» de mi post anterior, pero esta vez el campo era mío.

La diferencia entre los dos no fue el diseño. Fue la suerte. Ninguno de los dos estaba pensado para fallar de una forma segura: uno se calló por un `try/except` puesto sin pensar, el otro gritó al vacío por no tener ninguno. El fail-closed silencioso no es mejor que el fail-open por diseño —es fail-open con menos suerte—. Lo seguro habría sido que cualquiera de los dos me avisara. Ninguno lo hacía.

## Lo que cambié

En el post de junio propuse la cura en abstracto: aserciones baratas que comprueben que el dato significa lo que dice. Esta semana me tocó escribirlas de verdad, sobre mi propio código:

- **Moví la clave** al sitio del que los scripts leen, y verifiqué —cargándola y midiendo su longitud— que ambos la ven. Verificar, no suponer.
- **Maté el fail-open del digest.** Si el resumen no se genera, ya no manda titulares disfrazados de análisis: manda un aviso explícito de que falló. Prefiero un error ruidoso a un éxito falso.
- **Añadí una aserción de contenido, no de estado.** El agente comprueba que la respuesta del LLM existe y tiene forma de resumen antes de darla por buena. La segunda pregunta que predico: no «¿terminó?», sino «¿hizo lo que debía?».

Y una guinda que confirma la moraleja: el modelo barato al que iba a cambiar resultó ser un modelo de razonamiento que, con el límite de tokens del digest, devolvía la respuesta *vacía* con un `200 OK` impecable. Sin la aserción de contenido, habría «arreglado» el agente dejándolo igual de roto, esta vez con la bendición de un código de estado correcto. El 200 mintiendo, otra vez, justo mientras arreglaba las mentiras.

## La lección que me llevo

Escribí hace un mes que el verde es una afirmación, no un destino, y que hay que obligarlo a demostrarse. Lo creía. No lo estaba haciendo en mi propia casa. La distancia entre saber una cosa y aplicártela es más ancha de lo que a ninguno nos gusta admitir, y se cruza a base de tropezar con lo que ya habías escrito.

La cobertura que no has medido es un supuesto, no un hecho —lo firmo hoy con más razón que en junio—. Y el fail-open es cómodo justo porque nunca te despierta de noche. Lo que no te despierta cuando debería es lo que peor te va a salir.
