---
title: "Recursos"
description: "Guías prácticas y frameworks de producción para equipos que despliegan agentes IA autónomos."
layout: "landing"
translationKey: "books"
url: "/es/recursos/"
aliases: ["/es/libros/", "/es/books/"]
---

<div class="landing-hero">
  <span class="landing-hero__eyebrow">Recursos</span>
  <h1 class="landing-hero__title">Recursos de Seguridad para<br>la Era de Agentes IA</h1>
  <p class="landing-hero__subtitle">Playbooks prácticos y frameworks listos para producción. Para ingenieros de seguridad que despliegan sistemas autónomos. Sin relleno teórico. Sin vendor pitches.</p>
</div>

<div class="landing-section">
  <div class="book-grid">
    <div class="book-card">
      <img src="/images/cover-es.png" alt="Portada del libro Blindar Agentes IA" class="book-card__cover" loading="lazy">
      <div class="book-card__content">
        <h2 class="book-card__title">Blindar Agentes IA</h2>
        <p class="book-card__subtitle">Patrones para Controlar Agentes, Modelos y Herramientas</p>
        <p class="book-card__desc">16 capítulos con patrones defensivos probados — desde threat modeling hasta respuesta a incidentes, incluyendo ataques de cadena de suministro en skills de terceros y envenenamiento de memoria. Incluye plan de hardening de 90 días, checklist de seguridad y template de threat model.</p>
        <p class="book-card__audience"><strong>Para:</strong> Ingenieros de seguridad, DevSecOps, SREs, ingenieros AI/ML que despliegan agentes en producción.</p>
        <div class="book-card__actions">
          <a href="https://amzn.eu/d/0fd0AhGf" target="_blank" rel="noopener" class="book-card__btn book-card__btn--primary">Kindle — €9.99</a>
          <a href="https://javiermoralesecurity.gumroad.com/l/blindaragentesia" target="_blank" rel="noopener" class="book-card__btn book-card__btn--secondary">PDF+EPUB — €14.99</a>
        </div>
      </div>
    </div>
    <div class="book-card">
      <img src="/images/cover-kit.png" alt="Portada AI Agent Defense Kit" class="book-card__cover" loading="lazy">
      <div class="book-card__content">
        <h2 class="book-card__title">AI Agent Defense Kit</h2>
        <p class="book-card__subtitle">Playbooks de IR, Plantillas y Mapeo de Compliance Listos para Producción</p>
        <p class="book-card__desc">20 ficheros accionables: 12 playbooks de respuesta a incidentes para fallos de agentes IA, plantillas de threat model, mapeo SOC 2 e ISO 27001, rúbrica de postura de seguridad y guía de implementación con decisiones de arquitectura.</p>
        <p class="book-card__audience"><strong>Para:</strong> Equipos de seguridad que despliegan agentes IA y necesitan frameworks listos para usar, no solo teoría.</p>
        <div class="book-card__actions">
          <a href="https://javiermoralesecurity.gumroad.com/l/ai-defense-kit" target="_blank" rel="noopener" class="book-card__btn book-card__btn--primary">Consigue el Kit — $49</a>
        </div>
        <p class="book-card__includes">Incluye: 12 playbooks IR · 3 plantillas · Mapeo compliance · Rúbrica de scoring · Guía de implementación</p>
      </div>
    </div>
    <div class="book-card">
      <img src="/images/cover-freekit.svg" alt="Portada Detection Engineering Starter Kit" class="book-card__cover" loading="lazy">
      <div class="book-card__content">
        <h2 class="book-card__title">Detection Engineering Starter Kit</h2>
        <p class="book-card__subtitle">Gratis — 3 Plantillas de Detección Listas para Producción + Prompts de Triaje con IA</p>
        <p class="book-card__desc">Kit gratuito para ingenieros de seguridad: 3 plantillas de detección probadas en producción (AWS CloudTrail, anomalías de autenticación, cadena de suministro), prompts de triaje para Claude y GPT, y un workflow detection-as-code con plantilla de GitHub Actions.</p>
        <p class="book-card__audience"><strong>Para:</strong> Cualquiera que empiece con detection-as-code y quiera reglas de alta señal listas para desplegar hoy.</p>
        <div class="book-card__actions">
          <a href="/es/kit-es/" class="book-card__btn book-card__btn--primary">Descarga gratis →</a>
        </div>
      </div>
    </div>
    <div class="book-card">
      <img src="/images/cover-auditkit.svg" alt="Portada Agent Audit Kit" class="book-card__cover" loading="lazy">
      <div class="book-card__content">
        <h2 class="book-card__title">Agent Audit Kit</h2>
        <p class="book-card__subtitle">Gratis y Open Source &mdash; Linter de Seguridad para Servidores MCP y Agentes IA</p>
        <p class="book-card__desc">Scanner estatico (Python, cero dependencias, cero red) que audita tu <code>mcp.json</code> y configs de agente contra el OWASP Agentic Top 10. Lo que ninguna otra herramienta hace: para cada hallazgo, la guia de deteccion &mdash; los logs y senales para cazar el abuso en produccion &mdash; con reglas Sigma listas para desplegar.</p>
        <p class="book-card__audience"><strong>Para:</strong> Ingenieros de seguridad y DevSecOps que despliegan agentes IA / MCP y quieren auditarlos antes de que lo haga otro.</p>
        <div class="book-card__actions">
          <a href="https://github.com/JAvito-GC/agent-audit-kit" target="_blank" rel="noopener" class="book-card__btn book-card__btn--primary">Ver en GitHub &rarr;</a>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="landing-section">
  <h2 class="landing-section__title">Contenido del Libro</h2>
  <div class="book-toc">
    <ol>
      <li>La Brecha</li>
      <li>Threat Modeling para Sistemas Autónomos</li>
      <li>Principios Que No Caducan</li>
      <li>Tu Agente Filtró Credenciales</li>
      <li>Un Input No Confiable Secuestró Tu Agente</li>
      <li>Tu Agente Hizo 47 Llamadas API Que Nadie Aprobó</li>
      <li>El Becario Shippeó un Agente con Acceso Admin</li>
      <li>El Skill Que Instalaste Trabajaba Para Otro</li>
      <li>Algo Fue Mal y Nadie Sabe Qué</li>
      <li>La Alerta Que Gritaba Lobo</li>
      <li>Alguien Manipuló Tus Guardrails</li>
      <li>El Agente Creyó Una Mentira Que Le Contaron La Semana Pasada</li>
      <li>Cuando los Agentes Crean Agentes</li>
      <li>Monitorizar Lo Que No Puedes Predecir</li>
      <li>Respuesta a Incidentes — Edición Agentes</li>
      <li>Tu Plan de Hardening de 90 Días</li>
    </ol>
    <p><strong>Además:</strong> Checklist de Seguridad + Template de Threat Model</p>
  </div>
</div>

<div class="landing-section">
  <h2 class="landing-section__title">Sobre el Autor</h2>
  <p>Javier Morales es Staff Security Engineer especializado en detection engineering y operaciones de seguridad impulsadas por IA. Se dedica a descubrir cómo se pueden comprometer los agentes autónomos — y a construir los sistemas que los detienen.</p>
</div>

<script type="application/ld+json">
[
  {
    "@context": "https://schema.org",
    "@type": "Book",
    "name": "Blindar Agentes IA",
    "author": {"@type": "Person", "name": "Javier Morales"},
    "description": "Patrones para Controlar Agentes, Modelos y Herramientas. 16 capítulos de patrones defensivos para ingenieros de seguridad que despliegan agentes IA.",
    "inLanguage": "es",
    "numberOfPages": 200,
    "genre": "Seguridad Informática",
    "image": "https://javiermorales.tech/images/cover-es.png",
    "offers": [
      {"@type": "Offer", "price": "9.99", "priceCurrency": "EUR", "availability": "https://schema.org/InStock", "url": "https://amzn.eu/d/0fd0AhGf"},
      {"@type": "Offer", "price": "14.99", "priceCurrency": "EUR", "availability": "https://schema.org/InStock", "url": "https://javiermoralesecurity.gumroad.com/l/blindaragentesia"}
    ]
  },
  {
    "@context": "https://schema.org",
    "@type": "Product",
    "name": "AI Agent Defense Kit",
    "description": "20 ficheros listos para producción: 12 playbooks IR, plantillas de threat model, mapeo SOC 2 e ISO 27001, scoring de postura de seguridad y guía de implementación.",
    "brand": {"@type": "Person", "name": "Javier Morales"},
    "category": "Framework de Seguridad Digital",
    "offers": {
      "@type": "Offer",
      "price": "49",
      "priceCurrency": "USD",
      "availability": "https://schema.org/InStock",
      "url": "https://javiermoralesecurity.gumroad.com/l/ai-defense-kit"
    }
  },
  {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": [
      {"@type": "ListItem", "position": 1, "name": "Inicio", "item": "https://javiermorales.tech/es/"},
      {"@type": "ListItem", "position": 2, "name": "Libros y Kits"}
    ]
  }
]
</script>
