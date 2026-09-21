---
title: "264.000 Personas Están a Punto de Instalar un Harness de Agentes IA. Haz Esta Auditoría de 5 Minutos Primero."
date: 2026-09-21
description: "ECC llegó a 264k estrellas en GitHub y hace la seguridad de cadena de suministro mejor que la mayoría. Justo por eso deberías auditarlo antes de instalarlo. Un checklist reutilizable para cualquier harness de agentes."
summary: "Everything Claude Code superó las 264k estrellas y está bien construido de verdad. Esa popularidad es el punto: popular no es lo mismo que auditado por ti. La auditoría de 5 minutos que paso a cualquier harness de agentes antes de confiar en él."
translationKey: "ecc-audit-harness"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "agent-security", "supply-chain", "claude-code", "ai-security"]
---

Everything Claude Code (ECC) superó las 264.000 estrellas en GitHub esta semana. Comprobé el número contra la API de GitHub, no contra el render de la página: 264.265 estrellas, 39.504 forks, en ocho meses. Es, por esa métrica, uno de los proyectos para desarrolladores más populares de la plataforma.

Y además es bueno de verdad. Leí el instalador y la política de seguridad antes de escribir una palabra, y ECC hace bien las partes difíciles. Así que esto no es un ataque. Es lo contrario: ECC es el mejor caso posible que encontré para ilustrar algo que aplica a cualquier harness de agentes que instales, incluidos los buenos.

La idea es simple. Popular no es lo mismo que auditado por ti. Y un harness de agentes no es una librería. Son 68 subagentes, 292 skills, hooks que se ejecutan fuera del contexto del modelo, y un instalador que delega en código que no has leído. Cuando lo instalas no estás añadiendo una dependencia. Estás dándole a un sistema autónomo una invitación permanente a ejecutar comandos en tu máquina, con tus claves, en cada turno.

Eso es una decisión de confianza. Y la mayoría está a punto de tomarla porque un número subió.

## Lo justo primero

Antes de la auditoría, la parte justa. ECC no hace las cosas ingenuas y peligrosas:

- El instalador ejecuta `npm install --ignore-scripts`, que bloquea a propósito la vía de ejecución remota de código por preinstall y postinstall que ha quemado a tantos usuarios de npm.
- No canaliza un script remoto hacia un shell. Ni `sudo`. No reescribe tu perfil de shell.
- Su SECURITY.md trata la exposición de cadena de suministro como superficie de primera clase, con disclosure coordinado y plazos de respuesta reales. Incluso modela el propio canal de entrada del harness como superficie de ataque, distinguiendo los system-reminders inyectados por el harness de la inyección transportada en el repositorio.

Eso es más madurez de seguridad que la de la mayoría de proyectos con una fracción de la atención. Si vas a instalar un harness, este está cerca del extremo responsable del espectro.

Y aun así no te libra de tu parte.

## La auditoría de 5 minutos

Pásala contra ECC, contra mis propias herramientas, contra cualquier cosa que instales y que actúe en tu nombre. No va de confiar en el autor. Va de saber qué aceptaste.

**1. Lee el instalador de principio a fin.** No el README, el instalador. ¿Descarga un script remoto y lo ejecuta? ¿Escala a root? ¿Toca `.bashrc`, `.zshrc` o tu PATH? ECC pasa estas. Pero fíjate en lo que hace después: delega el trabajo real en un script de Node que el wrapper no muestra. Un instalador que hace la parte visible con cuidado y luego ejecuta código que no has abierto sigue pidiéndote una confianza que no has verificado.

**2. Enumera los hooks.** Los hooks son la parte que más importa y que menos gente lee. Se ejecutan fuera del contexto del modelo, lo que significa que corren en tu máquina ante eventos de herramienta, decida o no el modelo. Lista cada hook. Lee cada hook. Un hook es código arbitrario con tus permisos, disparado por eventos que no controlas del todo.

**3. Mide la superficie siempre cargada.** Separa lo que se carga bajo demanda de lo que se carga en cada turno. 292 skills no son 292 funciones, son 292 ficheros en los que confías implícitamente y que nunca vas a leer en persona. Confiar por volumen no es confiar. Es rendirse con pasos extra.

**4. Mapea la salida a red.** ¿Qué habla con la red? ¿Qué servidores MCP, qué endpoints, qué telemetría? Cada ruta de salida es una ruta potencial de exfiltración para los secretos y el código que el agente puede ver. Si no puedes listarlas, no puedes defenderlas.

**5. Fija la versión.** La popularidad hace a un proyecto un objetivo mayor, no más seguro. 264k estrellas son 264k razones para que alguien intente envenenar una release. Fija el commit SHA. Reaudita en cada actualización.

## Lo único que no puedes delegar

ECC incluye AgentShield, un escáner para exactamente esta clase de problema. Los buenos escáneres ayudan. Pero ningún escáner, ni el suyo ni el mío, cierra el último hueco, porque el último hueco no es técnico. Es el código que no leíste en persona y la superficie demasiado grande para leerla siquiera.

Un harness consciente de la seguridad puede darte un default más seguro. No puede tomar la decisión de confianza por ti. Cuando instalas 292 skills, estás confiando en que las 292 son lo que dicen ser, para siempre, en cada actualización, y lo haces apoyándote en un contador de estrellas. Ese riesgo residual no desaparece porque el autor sea cuidadoso. Se te transfiere en el momento en que tecleas el comando de instalación.

Esa es la lección de verdad, y sobrevive a ECC. El próximo harness tendrá más estrellas.

## Audita antes de confiar

Construí el [Agent Audit Kit](https://github.com/JAvito-GC/agent-audit-kit) precisamente para esto: una herramienta open-source con licencia MIT que pasa este tipo de checklist contra un setup de agentes o MCP, señala el código que corre fuera del modelo, y te dice qué estás aceptando de verdad. Corre en local. Nada sale de tu máquina.

El hype es una gran razón para ir a mirar. Nunca es una razón para confiar. Instala ECC si se gana su sitio en tu flujo. Solo corre los cinco minutos primero.
