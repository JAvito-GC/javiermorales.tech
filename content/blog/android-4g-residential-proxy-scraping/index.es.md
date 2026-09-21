---
title: "La reputación de IP es una señal de detección frágil — lo que aprendí construyendo un proxy residencial 4G"
date: 2026-07-10
description: "La reputación de IP es una de las señales más baratas de un WAF, y una de las más frágiles. Construí un proxy residencial con un móvil Android viejo para ver la superficie de detección desde el otro lado. Esto es lo que le enseña a un defensor sobre dónde se rompe la detección por IP y por qué ganan las señales de comportamiento."
summary: "La mayoría de los WAF se apoyan mucho en la reputación de IP para separar humanos de bots. Construir el lado de la evasión —un móvil Android viejo como proxy residencial 4G— me mostró exactamente dónde se derrumba esa señal, y por qué el comportamiento de tasa y secuencia sobrevive a cualquier lista de IPs. Un post-mortem de detection engineering, con el stack completo incluido."
translationKey: "android-4g-proxy"
draft: false
og_image: "/img/og-default.png"
tags: ["detection-engineering", "security", "waf", "networking", "threat-detection"]
---

Me dedico a construir detección. La forma más rápida que conozco de entender cómo falla una señal es ponerme al otro lado e intentar batirla, así que cuando un WAF comercial bloqueó una tarea de recolección de datos mía en minutos, lo traté como un ejercicio de detection engineering: *¿qué señal me pilló, y cómo de frágil es?*

La respuesta fue la reputación de IP, y resultó ser mucho más frágil de lo que sugiere su protagonismo en la mayoría de los rulesets de WAF. Una IP de datacenter le pegó al WAF unas cuantas veces y recibió un challenge de JavaScript, después un bloqueo duro. Rotar por más IPs de datacenter no me sirvió de nada: todas estaban en el mismo cubo de reputación del que el WAF ya desconfiaba. Eso es la reputación de IP funcionando exactamente como se diseñó.

Luego moví el mismo tráfico detrás de una IP residencial, y la señal se derrumbó. No porque yo fuera listo, sino porque la señal es gruesa. Este post es ese experimento: construí la vía de evasión (un móvil Android viejo como proxy residencial 4G), observé qué detecciones aguantaron y cuáles no, y saqué la lección para cualquiera que *construya* lógica de WAF en vez de esquivarla. El stack completo está incluido y —la parte que la mayoría de artículos se saltan— todo lo que se rompe.

**Por qué debería importarle a un defensor:** si un móvil de sobra neutraliza tu capa de reputación de IP, esa capa es un badén, no un muro. Lo que de verdad aguantó fue la detección por comportamiento —tasa y secuencia de peticiones— y ahí es donde debe ir el presupuesto de detección.

## Por qué una IP de móvil es distinta

El trabajo de un WAF es separar humanos de bots, y la reputación de IP es una de sus señales más baratas. Los rangos de datacenter (AWS, GCP, OVH, DigitalOcean) se fingerprintean trivialmente y viven en un cubo permanente de "culpable hasta que se demuestre lo contrario". Un solo barrido agresivo desde uno de ellos dispara el challenge.

Las IPs de operador móvil son lo contrario. Miles de humanos reales las comparten detrás de CGNAT, así que bloquear en bloque un rango móvil significa bloquear clientes reales, algo que ningún operador de WAF quiere hacer. La IP que tu móvil recibe en 4G es indistinguible de la que usa un comprador real navegando en el autobús, porque *es* ese tipo de IP.

Ese es todo el insight, y corta por los dos lados. Como defensor, significa que la reputación de IP es estructuralmente incapaz de distinguir un proxy residencial de un cliente real: el coste en falsos positivos de bloquear un rango móvil es demasiado alto para pagarlo. Cualquier estrategia de detección que se apoye sobre todo en la reputación de IP está defendiendo una puerta que no cierra con llave. El resto es fontanería, pero ten presente ese modo de fallo, porque la solución en el lado defensivo sale de ahí.

## El stack

El objetivo: que un contenedor en mi VPS haga peticiones HTTP salientes que salgan por la conexión 4G del móvil, sin que el móvil necesite IP pública ni un puerto de entrada abierto.

```
[ contenedor en VPS ] → [ bridge socat ] → [ túnel SSH inverso ] → [ Android/Termux ] → [ 4G / operador ] → internet
```

**1. Termux en el móvil.** [Termux](https://termux.dev/) te da un userland Linux real en Android. Instala `openssh` y `autossh`. Sin root.

**2. Un túnel inverso, móvil → servidor.** El móvil no puede aceptar conexiones entrantes (CGNAT, sin IP pública), así que es *él* quien marca hacia el servidor y abre un túnel inverso. El lado servidor del túnel se convierte en un puerto local que reenvía de vuelta a través del móvil:

```bash
# en el móvil (Termux)
autossh -M 0 -N \
  -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" \
  -R 2222:localhost:8080 \
  tunneluser@tu-servidor
```

Aquí el móvil corre un pequeño proxy HTTP local en `:8080` (vale cualquier proxy SOCKS/HTTP ligero en Termux) y lo expone en el servidor como `localhost:2222`. `autossh` relanza el túnel cuando se cae, que lo hará.

**3. Un bridge socat hacia la red del contenedor.** Mi scraper corre en un contenedor, así que `localhost:2222` en el host no es directamente alcanzable desde dentro. Un servicio `socat` de una línea puentea el puerto del túnel (host-local) a la dirección de gateway del contenedor:

```ini
# /etc/systemd/system/proxy-bridge.service
[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:8888,bind=172.18.0.1,fork,reuseaddr TCP:127.0.0.1:2222
Restart=always
```

Ahora el contenedor llega al proxy del móvil en `172.18.0.1:8888`, y el scraper solo tiene que fijar eso como su proxy HTTP.

**4. La parte que de verdad importa: el goteo.** Una buena IP residencial es necesaria, pero no suficiente. Si le lanzas un barrido completo del catálogo —cientos de páginas seguidas— sigues pareciendo un bot y disparas la detección por comportamiento, por muy buena que sea la reputación de la IP. La solución es dejar de agrupar.

En vez de una tirada grande, programo bocados pequeños: un puñado de páginas cada 15 minutos, repartidas a lo largo del día.

```cron
7,22,37,52 * * * * /ruta/scrape_una_porcion.sh
```

Cuatro porciones a la hora, cada una haciendo poco trabajo. A lo largo de un día eso suma cobertura completa, pero la tasa de peticiones desde cualquier IP concreta se queda en el suelo de ruido de una navegación humana normal. Este único cambio hizo más por la fiabilidad que todos los trucos de falsear cabeceras juntos.

**5. Repliégate ante tus propios bloqueos.** El scraper mantiene un pequeño fichero de estado con un contador `consecutive_blocks`. Tres bloqueos seguidos y se queda dormido una hora en vez de seguir estrellándose contra el muro y agravar la penalización. Cuando el túnel se cae (se caerá), las peticiones fallan rápido, el contador sube y la cosa se echa a dormir sola en vez de quemar buena voluntad.

## Todo lo que se rompe

A los posts de scraping les encanta parar en la parte ingeniosa. Aquí va el impuesto de mantenimiento que nadie menciona.

- **El túnel se cae constantemente.** El móvil se duerme, Android mata el proceso en segundo plano para ahorrar batería, el operador renegocia la conexión, el traspaso Wi-Fi/4G. `autossh` gestiona la mayoría de los relanzamientos, pero la gestión agresiva de batería de Android acabará matando el propio Termux. Necesitas el móvil enchufado, la optimización de batería desactivada para Termux y un wake-lock retenido. Y aun así, cuenta con un paso manual de "dale una patada".
- **El auto-recuperado es obligatorio, no opcional.** Un watchdog en el servidor que comprueba si el puerto del túnel está vivo y si el proxy realmente sale a internet (haz curl a un endpoint que te devuelva tu IP, a través del proxy) es la diferencia entre "resistente" y "muerto en silencio durante tres días". Pregúntame cómo lo sé.
- **No escala.** Es una IP. Es genial para recolección de bajo volumen y respetuosa. Si necesitas throughput de verdad, vuelves al pool de proxies: esta técnica es un bisturí, no una manguera.
- **Los contadores de estado mienten tras una caída.** Cuando el túnel estaba caído, cada petición fallida parecía un "bloqueo" y llevó el contador de repliegue al máximo, así que el scraper se quedó dormido mucho después de que el túnel volviera. Distingue "me han bloqueado" de "no tenía ruta". Al principio no lo hice, y perdí un día de recolección con un scraper enfurruñado por un problema de red que ya se había resuelto.

## La parte que hay que pensar: ética y legalidad

Una IP residencial hace que *parezcas* un visitante normal. Precisamente por eso deberías exigirte un estándar más alto, no más bajo, porque las barreras técnicas que normalmente te frenarían han desaparecido.

- Respeta `robots.txt` y los términos de servicio. "Puedo" no es "debo".
- Scrapea solo datos visibles públicamente. Nunca nada detrás de autenticación, nunca nada personal más allá de lo que ya es público.
- Auto-limítate muy por debajo de lo que el sitio aguanta: el goteo no es solo anti-detección, es cortesía básica para no degradar el servicio de nadie.
- Conoce tu jurisdicción. La ley sobre scraping de datos públicos no está asentada y varía muchísimo entre países.

El enfoque de goteo alinea bien los incentivos aquí: lo educado (pocas peticiones, bien espaciadas) y lo eficaz (mantenerse bajo los umbrales de detección) resultan ser lo mismo.

## Qué le enseña esto a un defensor

Construí el lado ofensivo, pero el beneficio es defensivo. Tres lecciones que me llevo de vuelta a cómo escribo detección:

- **La reputación de IP es un filtro, no un control.** Descarta barato a la mayoría de bajo esfuerzo (barridos crudos desde datacenter), y eso vale la pena tenerlo. Pero trátala como el primer cedazo grueso, nunca como lo único que se interpone entre tú y un actor motivado. Un móvil la derrota. Presupuesta en consecuencia.
- **La tasa y la secuencia son las señales que sobrevivieron.** El goteo es lo que de verdad me mantuvo bajo el radar, mucho después de que la IP pareciera limpia. Es la imagen reflejada de la verdad defensiva: la detección por comportamiento —peticiones por identidad a lo largo del tiempo, forma del patrón de acceso— sobrevive a cualquier lista de permitir/denegar, porque se fija en *qué hace* el cliente, no en *de dónde viene*. Ahí es donde el detection engineering se gana el sueldo.
- **Una buena señal se degrada con elegancia; una frágil falla en silencio.** La reputación de IP da un veredicto binario y sin regusto: una vez la pasas, no le dice nada al defensor. La puntuación por comportamiento acumula evidencia y puede pillar al mismo actor en la segunda, tercera, décima desviación. Prefiere señales que sigan hablando.

El resumen incómodo: lo educado (pocas peticiones, bien espaciadas) y lo evasivo resultan ser idénticos, y por eso justamente las anomalías de volumen y cadencia son las detecciones en las que merece la pena invertir. Un atacante que tiene que comportarse como un usuario normal para seguir oculto ya ha renunciado a casi toda su ventaja.

Si quieres reproducir el montaje para probar tus propias detecciones contra él: enchufa el móvil, desactiva la optimización de batería y escribe el watchdog *primero*. El tú del futuro, mirando tres días de datos vacíos, te lo agradecerá.
