---
title: "Resources"
description: "Practical security guides and production-ready frameworks for teams deploying autonomous AI agents."
layout: "landing"
translationKey: "books"
url: "/resources/"
aliases: ["/books/"]
---

<div class="landing-hero">
  <span class="landing-hero__eyebrow">Resources</span>
  <h1 class="landing-hero__title">Security Resources for<br>the AI Agent Era</h1>
  <p class="landing-hero__subtitle">Practical, opinionated playbooks and frameworks for security engineers shipping autonomous systems. No theory padding. No vendor pitches.</p>
</div>

<div class="landing-section">
  <div class="book-grid">
    <div class="book-card">
      <img src="/images/cover-en.png" alt="Securing Autonomous AI book cover" class="book-card__cover" loading="lazy">
      <div class="book-card__content">
        <h2 class="book-card__title">Securing Autonomous AI</h2>
        <p class="book-card__subtitle">Patterns for Controlling Agents, Models & Tools</p>
        <p class="book-card__desc">16 chapters of battle-tested defensive patterns — from threat modeling to incident response, including supply-chain attacks on third-party skills and memory poisoning. Includes a 90-day hardening plan, security checklist, and threat model template.</p>
        <p class="book-card__audience"><strong>For:</strong> Security engineers, DevSecOps, SREs, AI/ML engineers deploying agents in production.</p>
        <div class="book-card__actions">
          <a href="https://amzn.eu/d/00XN689r" target="_blank" rel="noopener" class="book-card__btn book-card__btn--primary">Kindle — $9.99</a>
          <a href="https://javiermoralesecurity.gumroad.com/l/securing-autonomous-ai" target="_blank" rel="noopener" class="book-card__btn book-card__btn--secondary">PDF+EPUB — $14.99</a>
        </div>
      </div>
    </div>
    <div class="book-card">
      <img src="/images/cover-kit.png" alt="AI Agent Defense Kit cover" class="book-card__cover" loading="lazy">
      <div class="book-card__content">
        <h2 class="book-card__title">AI Agent Defense Kit</h2>
        <p class="book-card__subtitle">Production-Ready IR Playbooks, Templates & Compliance Mapping</p>
        <p class="book-card__desc">20 actionable files: 12 incident response playbooks for AI agent failures, threat model templates, SOC 2 & ISO 27001 compliance mapping, security posture scoring rubric, and implementation guide with architecture decisions.</p>
        <p class="book-card__audience"><strong>For:</strong> Security teams deploying AI agents who need ready-to-use frameworks, not just theory.</p>
        <div class="book-card__actions">
          <a href="https://javiermoralesecurity.gumroad.com/l/ai-defense-kit" target="_blank" rel="noopener" class="book-card__btn book-card__btn--primary">Get the Kit — $49</a>
        </div>
        <p class="book-card__includes">Includes: 12 IR playbooks · 3 templates · Compliance mapping · Scoring rubric · Implementation guide</p>
      </div>
    </div>
    <div class="book-card">
      <img src="/images/cover-freekit.svg" alt="Detection Engineering Starter Kit cover" class="book-card__cover" loading="lazy">
      <div class="book-card__content">
        <h2 class="book-card__title">Detection Engineering Starter Kit</h2>
        <p class="book-card__subtitle">Free — 3 Production-Ready Detection Templates + AI Triage Prompts</p>
        <p class="book-card__desc">A free starter kit for security engineers: 3 production-tested detection templates (AWS CloudTrail, authentication anomalies, supply chain), AI triage prompts for Claude and GPT, and a detection-as-code workflow with a GitHub Actions template.</p>
        <p class="book-card__audience"><strong>For:</strong> Anyone starting with detection-as-code who wants high-signal rules they can deploy today.</p>
        <div class="book-card__actions">
          <a href="/kit/" class="book-card__btn book-card__btn--primary">Download free →</a>
        </div>
      </div>
    </div>
    <div class="book-card">
      <img src="/images/cover-auditkit.svg" alt="Agent Audit Kit cover" class="book-card__cover" loading="lazy">
      <div class="book-card__content">
        <h2 class="book-card__title">Agent Audit Kit</h2>
        <p class="book-card__subtitle">Free &amp; Open Source &mdash; A Security Linter for MCP Servers and AI Agents</p>
        <p class="book-card__desc">A static scanner (Python, zero dependencies, zero network) that audits your <code>mcp.json</code> and agent configs against the OWASP Agentic Top 10. The part no other tool does: for every finding, detection guidance &mdash; the logs and signals to catch the abuse in production &mdash; with ready-to-deploy Sigma rules.</p>
        <p class="book-card__audience"><strong>For:</strong> Security engineers and DevSecOps deploying AI / MCP agents who want to audit them before someone else does.</p>
        <div class="book-card__actions">
          <a href="https://github.com/JAvito-GC/agent-audit-kit" target="_blank" rel="noopener" class="book-card__btn book-card__btn--primary">View on GitHub &rarr;</a>
        </div>
      </div>
    </div>
  </div>
</div>

<div class="landing-section">
  <h2 class="landing-section__title">What's Inside the Book</h2>
  <div class="book-toc">
    <ol>
      <li>The Gap</li>
      <li>Threat Modeling Autonomous Systems</li>
      <li>Principles That Don't Expire</li>
      <li>Your Agent Leaked Credentials</li>
      <li>An Untrusted Input Hijacked Your Agent</li>
      <li>Your Agent Made 47 API Calls Nobody Approved</li>
      <li>The Intern Shipped an Agent with Admin Access</li>
      <li>The Skill You Installed Was Working for Someone Else</li>
      <li>Something Went Wrong and Nobody Knows What</li>
      <li>The Alert That Cried Wolf</li>
      <li>Someone Tampered With Your Guardrails</li>
      <li>The Agent Believed a Lie It Was Told Last Week</li>
      <li>When Agents Spawn Agents</li>
      <li>Monitoring What You Can't Predict</li>
      <li>Incident Response — Agent Edition</li>
      <li>Your 90-Day Hardening Plan</li>
    </ol>
    <p><strong>Plus:</strong> Security Checklist + Threat Model Template</p>
  </div>
</div>

<div class="landing-section">
  <h2 class="landing-section__title">About the Author</h2>
  <p>Javier Morales is a Staff Security Engineer focused on detection engineering and AI-driven security operations. He spends his days figuring out how autonomous agents can be compromised — and building the systems that stop them.</p>
</div>

<script type="application/ld+json">
[
  {
    "@context": "https://schema.org",
    "@type": "Book",
    "name": "Securing Autonomous AI",
    "author": {"@type": "Person", "name": "Javier Morales"},
    "description": "Patterns for Controlling Agents, Models & Tools. 16 chapters of battle-tested defensive patterns for security engineers deploying AI agents.",
    "inLanguage": "en",
    "numberOfPages": 200,
    "genre": "Computer Security",
    "image": "https://javiermorales.tech/images/cover-en.png",
    "offers": [
      {"@type": "Offer", "price": "9.99", "priceCurrency": "USD", "availability": "https://schema.org/InStock", "url": "https://amzn.eu/d/00XN689r"},
      {"@type": "Offer", "price": "14.99", "priceCurrency": "USD", "availability": "https://schema.org/InStock", "url": "https://javiermoralesecurity.gumroad.com/l/securing-autonomous-ai"}
    ]
  },
  {
    "@context": "https://schema.org",
    "@type": "Product",
    "name": "AI Agent Defense Kit",
    "description": "20 production-ready files: 12 IR playbooks, threat model templates, SOC 2 & ISO 27001 compliance mapping, security posture scoring, and implementation guide.",
    "brand": {"@type": "Person", "name": "Javier Morales"},
    "category": "Digital Security Framework",
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
      {"@type": "ListItem", "position": 1, "name": "Home", "item": "https://javiermorales.tech/"},
      {"@type": "ListItem", "position": 2, "name": "Books & Kits"}
    ]
  }
]
</script>
