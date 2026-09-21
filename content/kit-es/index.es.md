---
title: "Detection Engineering Starter Kit"
description: "Kit gratuito: 3 plantillas de deteccion listas para produccion + prompts de IA para operaciones de seguridad. Creado por un Staff Security Engineer."
layout: "landing"
aliases: ["/es/kit/"]
---

<div class="landing-hero">
  <span class="landing-hero__eyebrow">Descarga gratuita</span>
  <h1 class="landing-hero__title">Detection Engineering<br>Starter Kit</h1>
  <p class="landing-hero__subtitle">3 plantillas de deteccion listas para produccion, prompts de IA para triaje de alertas y un workflow de detection-as-code — todo lo que necesitas para empezar a construir detecciones de alta senal.</p>
  <a href="#download" class="landing-hero__cta">Descargar gratis &darr;</a>
</div>

<div class="credentials-bar">
  <span class="credentials-bar__item">Usado en entornos de produccion</span>
  <span class="credentials-bar__item">AWS + Multi-cloud</span>
  <span class="credentials-bar__item">Workflows con IA</span>
</div>

<div class="landing-section">
  <h2 class="landing-section__title">Que Incluye</h2>
  <div class="features">
    <div class="feature">
      <div class="feature__icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="32" height="32"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
      </div>
      <h3 class="feature__title">3 Plantillas de Deteccion</h3>
      <p class="feature__desc">Reglas de deteccion YAML probadas en produccion para AWS CloudTrail, anomalias de autenticacion e indicadores de supply chain. Copia, adapta, despliega.</p>
    </div>
    <div class="feature">
      <div class="feature__icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="32" height="32"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
      </div>
      <h3 class="feature__title">Prompts de Triaje con IA</h3>
      <p class="feature__desc">Plantillas de prompts para Claude y GPT que convierten alertas en bruto en decisiones de triaje estructuradas. Reduce la fatiga de alertas en un 60%+.</p>
    </div>
    <div class="feature">
      <div class="feature__icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="32" height="32"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>
      </div>
      <h3 class="feature__title">Workflow Detection-as-Code</h3>
      <p class="feature__desc">Workflow basado en Git para gestionar detecciones: escribe, testea, despliega con CI/CD. Incluye plantilla de GitHub Actions.</p>
    </div>
  </div>
</div>

<div class="landing-section" id="download">
  <div class="freebie-form" id="freebie-form-container">
    <h3 class="freebie-form__title">Consigue el Kit</h3>
    <p class="freebie-form__desc">Introduce tu email y te envio el starter kit directamente a tu bandeja.</p>
    <form id="freebie-form" action="https://formspree.io/f/xbdqqnzv" method="POST">
      <input type="hidden" name="_subject" value="Detection Engineering Starter Kit Download">
      <input type="hidden" name="source" value="freebie-kit-es">
      <div class="freebie-form__fields">
        <input type="email" name="email" class="freebie-form__input" placeholder="tu@email.com" required>
        <button type="submit" class="freebie-form__submit">Enviar kit</button>
      </div>
    </form>
    <div class="freebie-form__success" id="freebie-success">
      Revisa tu bandeja — el kit va en camino.
    </div>
  </div>
</div>

<script>
(function(){
  var form = document.getElementById('freebie-form');
  var success = document.getElementById('freebie-success');
  if(!form) return;
  form.addEventListener('submit', function(e){
    e.preventDefault();
    var data = new FormData(form);
    fetch(form.action, {method:'POST', body:data, headers:{'Accept':'application/json'}})
      .then(function(r){
        if(r.ok){
          form.style.display='none';
          success.style.display='block';
        }
      });
  });
})();
</script>
