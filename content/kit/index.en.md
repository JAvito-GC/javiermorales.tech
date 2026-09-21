---
title: "Detection Engineering Starter Kit"
description: "Free starter kit: 3 production-ready detection templates + AI prompts for security operations. Built by a Staff Security Engineer."
layout: "landing"
---

<div class="landing-hero">
  <span class="landing-hero__eyebrow">Free Download</span>
  <h1 class="landing-hero__title">Detection Engineering<br>Starter Kit</h1>
  <p class="landing-hero__subtitle">3 production-ready detection templates, AI prompts for alert triage, and a detection-as-code workflow — everything you need to start building high-signal detections.</p>
  <a href="#download" class="landing-hero__cta">Download free &darr;</a>
</div>

<div class="credentials-bar">
  <span class="credentials-bar__item">Used in production environments</span>
  <span class="credentials-bar__item">AWS + Multi-cloud ready</span>
  <span class="credentials-bar__item">AI-enhanced workflows</span>
</div>

<div class="landing-section">
  <h2 class="landing-section__title">What's Inside</h2>
  <div class="features">
    <div class="feature">
      <div class="feature__icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="32" height="32"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
      </div>
      <h3 class="feature__title">3 Detection Templates</h3>
      <p class="feature__desc">Production-tested YAML detection rules for AWS CloudTrail, authentication anomalies, and supply chain indicators. Copy, adapt, deploy.</p>
    </div>
    <div class="feature">
      <div class="feature__icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="32" height="32"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
      </div>
      <h3 class="feature__title">AI Triage Prompts</h3>
      <p class="feature__desc">Prompt templates for Claude and GPT that turn raw alerts into structured triage decisions. Reduce alert fatigue by 60%+.</p>
    </div>
    <div class="feature">
      <div class="feature__icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="32" height="32"><polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/></svg>
      </div>
      <h3 class="feature__title">Detection-as-Code Workflow</h3>
      <p class="feature__desc">Git-based workflow for managing detections: write, test, deploy with CI/CD. Includes GitHub Actions template.</p>
    </div>
  </div>
</div>

<div class="landing-section" id="download">
  <div class="freebie-form" id="freebie-form-container">
    <h3 class="freebie-form__title">Get the Kit</h3>
    <p class="freebie-form__desc">Enter your email and I'll send the starter kit directly to your inbox.</p>
    <form id="freebie-form" action="https://formspree.io/f/xbdqqnzv" method="POST">
      <input type="hidden" name="_subject" value="Detection Engineering Starter Kit Download">
      <input type="hidden" name="source" value="freebie-kit-en">
      <div class="freebie-form__fields">
        <input type="email" name="email" class="freebie-form__input" placeholder="your@email.com" required>
        <button type="submit" class="freebie-form__submit">Send me the kit</button>
      </div>
    </form>
    <div class="freebie-form__success" id="freebie-success">
      Check your inbox — the kit is on its way.
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
