---
title: "El 26% de las skills de agentes IA son vulnerables. Audité las mías."
date: 2026-06-16
description: "Una investigación de NVIDIA encontró que el 26% de las skills de agentes contienen vulnerabilidades. Escaneé mis 29 skills de Claude Code con la misma taxonomía — y encontré algo más interesante que un resultado limpio."
summary: "Un estudio de 42.447 skills de agentes encontró un 26,1% vulnerables y un 5,2% probablemente maliciosas. Pasé mis 29 skills por la taxonomía de SkillSpector. Salieron limpias — pero la auditoría destapó tres huecos reales en mi modelo de defensa, y el arreglo se convirtió en una herramienta nueva."
translationKey: "skillspector-audit"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai", "research", "claude-code", "open-source"]
---

Intenté escanear mis propias skills de agente buscando un patrón `curl | bash`. Mi propio hook de seguridad bloqueó el comando antes de que pudiera ejecutarse.

```
BLOCKED: Pipe-to-shell execution blocked
```

Era el dueño. Estaba lanzando un `grep` de solo lectura. Y aun así la capa de control me paró — porque el patrón coincidía, y a esa capa le da igual quién seas. Ahí está la tesis entera de este post resumida en un accidente: los controles que importan son los que el operador no puede esquivar con labia. Ni siquiera el operador.

Te cuento por qué estaba haciendo ese `grep`.

---

## El número

NVIDIA publicó [SkillSpector](https://github.com/nvidia/skillspector), un escáner open-source que examina las skills de un agente IA *antes* de instalarlas. Viene con una taxonomía de 64 patrones de vulnerabilidad repartidos en 16 categorías — inyección de prompts, exfiltración de datos, escalada de privilegios, cadena de suministro, envenenamiento de herramientas MCP y más.

El número que me hizo parar venía de la investigación detrás — un estudio titulado *Agent Skills in the Wild* (Liu et al., 2026) que analizó **42.447 skills** de los principales marketplaces:

- **26,1%** contienen al menos una vulnerabilidad
- **5,2%** muestran intención probablemente maliciosa
- Las skills con scripts ejecutables son **2,12 veces** más propensas a ser vulnerables

Una "skill" es simplemente una carpeta con instrucciones y a veces código que sueltas en tu agente para ampliarlo. Una de cada cuatro, ahí fuera, lleva algo que no debería. Una de cada veinte es probablemente hostil por diseño.

En mi propio Claude Code corro 29 skills — herramientas de SEO, un pipeline de deploy, motores de investigación, generadores de contenido. Así que hice lo evidente: volví la taxonomía contra mí mismo.

---

## Auditando mis 29 skills

No instalé SkillSpector. (Tengo una regla fija: nunca ejecutar herramientas de terceros dentro de este entorno — la ironía de instalar un escáner de seguridad sin verificar para comprobar código sin verificar no se me escapa.) Usé su taxonomía como referencia y audité directamente contra los patrones de mayor señal:

- **SC2 — Fetch de scripts externos:** contenido remoto canalizado a una shell
- **AST1 — Ejecución dinámica:** `eval`, `exec`, `os.system`, `subprocess(shell=True)`
- **E2 / PE3 — Acceso a credenciales:** leer variables de entorno o almacenes de secretos y mandarlos fuera
- **RA1 — Automodificación:** una skill que escribe en la propia capa de control del agente
- **TP2 — Engaño Unicode:** caracteres de ancho cero, anulaciones RTL, homóglifos escondidos en descripciones

El resultado: **limpio.** Cero ejecución dinámica. Cero recolección de credenciales. Cero fetch-a-intérprete. Cero automodificación. Los únicos caracteres no-ASCII eran tildes españolas y un signo de multiplicación en una fórmula — no los ataques de homóglifos que ese patrón busca cazar.

Ese es el resultado honesto, y un resultado aburrido para escribir sobre él. "Lo comprobé y todo estaba bien" no es una historia. Así que seguí y me hice la pregunta más útil: *por qué* estaba limpio — y dónde dejaría de estarlo.

---

## Los tres huecos que encontré

Mis skills están limpias hoy no porque las escanee, sino por un sistema de defensa que corre *alrededor* del agente — cuatro hooks de shell que interceptan cada llamada a herramienta, validan los prompts de los subagentes y verifican la integridad de los ficheros en cada sesión. (Mapeé ese sistema ataque por ataque en [un post anterior](/blog/ai-agents-of-chaos-paper-defense-mapping/).)

Pero mapear las 16 categorías de SkillSpector contra mis hooks destapó algo que no me había admitido a mí mismo. Mi defensa es casi por completo un modelo de **ejecución**. Caza el comportamiento peligroso en el momento en que se ejecuta. Eso deja tres huecos reales:

**Hueco 1 — Sin escaneo estático previo a la instalación.** Si una skill contuviera una línea `curl | bash`, mi hook de ejecución la bloquearía *cuando intentara correr*. Pero nada inspeccionaba la skill *antes* de que entrara en el entorno. Confiaba en pillarlo en vivo. Esa es una posición peor que pillarlo en la puerta.

**Hueco 2 — Sin firmas de malware.** SkillSpector trae reglas YARA para patrones conocidos como maliciosos. Yo no tengo ninguna.

**Hueco 3 — Sin auditoría de dependencias al instalar.** Una skill nueva que empaquete un paquete vulnerable se me colaría hasta que ese paquete hiciera algo.

Esta es la parte que la mayoría de posts del tipo "audité mi sistema y es seguro" se dejan fuera. Un resultado limpio no es lo mismo que cobertura completa. Los huecos son donde vive el siguiente ataque.

---

## Cerrando el hueco 1: una herramienta, no una promesa

Los huecos 2 y 3 elijo no arreglarlos con código — y quiero ser explícito al respecto, porque las omisiones silenciosas son como funciona el teatro de seguridad. Ambos huecos solo importan si instalo skills de terceros. No lo hago. Están mitigados por **política**, no por ingeniería, y decirlo abiertamente es la postura honesta.

El hueco 1 es distinto. "Ya lo pillaré en ejecución" es una esperanza, no un control. Así que construí la capa que faltaba: un escáner estático previo a la instalación, `/skill-audit`. Solo lectura. Cero dependencias. Nunca ejecuta código de skills y nunca toca la red — greppea los mismos patrones de alta señal y mapea cada hallazgo de vuelta a la categoría de SkillSpector a la que pertenece.

Lo validé en las dos direcciones, porque un escáner que solo dice "limpio" no sirve para nada:

- Contra mis 29 skills reales → **limpio**, exit 0. Coincidió con mi auditoría manual.
- Contra una skill de prueba deliberadamente maliciosa (`curl | sh`, `cat ~/.ssh/id_rsa | nc`, `rm -rf /`, `os.system`) → **cuatro hallazgos**, severidades correctas, y la skill inocente de al lado intacta.

Un detalle que disfruté: el escáner se salta su propio código fuente. Su catálogo de patrones *contiene* cada firma que busca, así que escanearse a sí mismo no produce más que falsos positivos — el mismo problema de autoexclusión que toda herramienta de seguridad real tiene que resolver. Y cuando escribí el fichero de prueba malicioso, mi hook de pre-ejecución me bloqueó otra vez por teclear el literal `curl | bash` en un comando. Tuve que generar el fichero desde Python para sortear mis propias defensas. Eso es el sistema funcionando exactamente como se diseñó.

---

## La lección real: instalación frente a ejecución

SkillSpector y mis hooks no compiten. Vigilan puertas distintas.

```
┌──────────────────────────────────────────────┐
│  Llega una skill nueva                        │
├──────────────────────────────────────────────┤
│  ① INSTALACIÓN  (SkillSpector / skill-audit)  │
│     Escaneo estático antes de que corra       │
│     - curl-a-shell, ejecución dinámica        │
│     - acceso a credenciales, automodificación │
│     - engaño unicode, firmas conocidas        │
├──────────────────────────────────────────────┤
│  La skill se ejecuta                          │
├──────────────────────────────────────────────┤
│  ② EJECUCIÓN  (hooks pre/post-tool)           │
│     Bloquea comportamiento peligroso en vivo  │
│     - comandos destructivos, escrituras prot. │
│     - inyección de prompts, fugas de creds    │
│     - validación de subagentes, integridad    │
└──────────────────────────────────────────────┘
```

Un escaneo estático puede ser engañado por código que ensambla su carga útil en tiempo de ejecución. Un hook de ejecución no puede frenar una skill que nunca supo que era peligrosa hasta que actuó. Cada capa cubre el punto ciego de la otra. Eso no es redundancia — es defensa en profundidad, y es justo el objetivo.

La conclusión incómoda del 26% de NVIDIA no es "escanea tus skills". Es que el ecosistema de agentes desarrolló una cadena de suministro — marketplaces, skills compartidas, instalaciones de un clic — antes de desarrollar el modelo de seguridad que una cadena de suministro exige. Ya hemos estado aquí: con npm, con PyPI, con las extensiones de navegador. El patrón siempre es el mismo: la distribución llega primero, y la capa de auditoría llega después del primer incidente.

Construye la capa de auditoría antes del incidente.

---

## Pruébalo tú mismo

Si corres skills de Claude Code — sobre todo cualquiera que no hayas escrito tú — audítalas. Puedes usar [SkillSpector](https://github.com/nvidia/skillspector) de NVIDIA para el pipeline completo de AST/LLM/OSV, o escribir una pasada ligera como la mía. El punto no es la herramienta. El punto es que *algo* inspeccione una skill antes de que se gane tu confianza, y que *otra cosa* la vigile una vez que corre.

Mi sistema de defensa en ejecución es open source: [github.com/JAvito-GC/claude-guardrails](https://github.com/JAvito-GC/claude-guardrails) — hooks pre/post-tool, detección de inyección de prompts con normalización Unicode, checksums de integridad y validación de subagentes.

---

## Consigue el framework listo para producción

El repo open source te da los hooks de ejecución. El kit te da el resto: plantillas de modelado de amenazas, 12 playbooks de respuesta a incidentes para fallos de agentes IA, mapeo de cumplimiento SOC 2 e ISO 27001, y una rúbrica de puntuación de postura de seguridad.

**[AI Agent Defense Kit](https://javiermoralesecurity.gumroad.com/l/ai-defense-kit)** — $49

---

*Para un tratamiento más profundo de arquitecturas de defensa para sistemas de IA autónomos — verificación en instalación, control en ejecución, aislamiento de memoria y monitorización continua — consulta mi libro [Blindar Agentes IA](/books/).*
