---
title: "From 8,000 to 3,000 Alerts/Week: How I Automated Security Triage with AI"
date: 2026-04-22
draft: false
translationKey: "alert-triage-ai"
description: "How I built a multi-agent AI system that reduced security alert noise by 65%, automated 82%+ of alert closures, and turned 45 minutes of morning triage into 5."
tags: ["security", "ai", "automation", "soc", "mcp", "agents"]
categories: ["Security Engineering", "AI"]
author: "Javier Morales"
---

Every Monday morning, I opened the alert dashboard and faced the same thing: 8,000+ alerts accumulated from the previous week. Most of them were noise. False positives, duplicates, low-risk events that someone flagged as "critical" three years ago and nobody dared to touch. I knew which ones were junk just by reading the title. But still, they all had to be reviewed.

If you work in security, you know this story. Alert fatigue isn't an abstract concept --- it's the reason SOC teams have brutal turnover and why real incidents get buried under noise.

I decided it was time for AI to do what I was doing mentally every morning: classify, correlate, and close the obvious stuff. Here's what I built and the results I got.

## The Real Problem: It's Not the Alerts, It's the Context

Raw alert volume isn't the actual problem. The problem is that every alert requires **context** to make a decision:

- Does this user have a history of anomalous behavior?
- Is this endpoint already part of an open investigation?
- Was this event triaged last week with the same pattern?
- Does the source IP appear in our exclusion lists?

A senior analyst answers these questions in seconds because they carry **years of context** in their head. A junior analyst takes 5-10 minutes per alert because they need to check 3-4 different platforms.

My hypothesis: if an AI agent could access the same platforms and maintain memory of historical context, it could make the same decisions as a senior analyst for the 80% of routine cases.

## The Architecture: 9 Specialized Agents

I didn't build one mega-prompt that does everything. I built a system of 9 specialized agents, each with a specific role, coordinated by a central orchestrator.

```
┌─────────────────────────────────────────────────────┐
│                   ORCHESTRATOR                      │
│           (routing + prioritization)                │
└──────────┬──────────┬──────────┬────────────────────┘
           │          │          │
    ┌──────▼──┐ ┌─────▼────┐ ┌──▼──────────┐
    │ TRIAGE  │ │ INVEST.  │ │  REPORTING  │
    │         │ │          │ │             │
    │ Classif.│ │ Enrich.  │ │ Summaries  │
    │ Dedup.  │ │ Correl.  │ │ Metrics    │
    │ Scoring │ │ Timeline │ │ Escalation │
    └────┬────┘ └────┬─────┘ └──────┬──────┘
         │           │              │
    ┌────▼───────────▼──────────────▼──────┐
    │         MCP LAYER (6+ connectors)    │
    │                                      │
    │  SIEM ─ Ticketing ─ Identity ─ EDR  │
    │  Threat Intel ─ CMDB ─ Memory        │
    └──────────────────────────────────────┘
```

### Why Multi-Agent Instead of a Single Prompt

The reason is practical: a single prompt with context from 6 platforms, alert history, and decision rules blows through the context window fast. Plus, each agent can use a different model depending on the complexity of its task:

- **Triage agents**: fast, cheap model (routine classification)
- **Investigation agents**: powerful model (complex reasoning)
- **Reporting agents**: standard model (structured text generation)

### MCP: The Glue That Connects Everything

The key piece was the **Model Context Protocol (MCP)**. Instead of building custom API integrations for each platform, MCP lets agents "talk" to security tools in a standardized way.

Each MCP connector exposes a platform's capabilities as tools the agent can invoke:

- **SIEM**: search events, get alert details, query logs
- **Ticketing**: create/update/close tickets, search previous incidents
- **Identity**: query user history, verify permissions, review sessions
- **EDR**: endpoint status, processes, indicators of compromise
- **Threat Intel**: IP/domain/hash reputation
- **CMDB**: asset owner, criticality, environment

### Persistent Memory: The Secret Ingredient

One of the biggest wins was implementing **persistent memory** across sessions. The system remembers:

- Alert patterns already triaged and their resolution
- Recurring false positives and their signatures
- Context from ongoing investigations
- Previous human analyst decisions (feedback loop)

This means the second time an identical pattern appears, the agent doesn't need to re-investigate from scratch. It simply applies the same decision with a reference to the previous case.

## The Results: Real Numbers

After 3 months of iteration and refinement, here are the numbers:

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Alerts/week | 8,000+ | ~3,000 | **-65%** |
| Morning triage | 45 min | 5 min | **-89%** |
| Automated closures | 0% | 82%+ | -- |
| Events processed/week | manual | 200+ | -- |
| Automation coverage | 0% | 78% | -- |

### Breaking Down the 65% Reduction

Not all of this is "AI closed alerts." The reduction comes from several sources:

1. **Intelligent deduplication (~25%)**: the system groups alerts that are variants of the same event. Instead of 15 alerts for a port scan from the same IP, you see 1 grouped alert with consolidated context.

2. **Auto-closure of known false positives (~30%)**: patterns that have been generating noise for months and are always closed without action. The system identifies and closes them with documentation.

3. **Enrichment that changes priority (~10%)**: alerts that look critical but, after checking context (user on vacation, endpoint under maintenance, known internal IP), drop to informational.

### What I Did NOT Automate

The remaining 22% that requires human intervention includes:

- Alerts with novel indicators of compromise (not previously seen)
- Any alert involving customer data or PII
- Escalations to external teams
- Changes to detection rules

This is deliberate. The AI does not make destructive or irreversible decisions.

## 5 Lessons I Learned Building This

### 1. Start in Read-Only Mode

For the first 4 weeks, the system could only **read and recommend**. It didn't auto-close anything. Every recommendation was compared against the analyst's actual decision.

This produced two fundamental things:
- An implicit training dataset (recommendation vs. actual decision)
- Team trust (nobody wants an AI closing alerts unsupervised from day 1)

Only when the agreement rate exceeded 95% did I enable auto-closures for the lowest-risk categories.

### 2. The 80/20 Rule Is Brutal in Security

**80% of alerts follow 5-6 patterns.** Seriously. I analyzed them:

1. Port scans / reconnaissance from known IPs
2. Failed login attempts below the lockout threshold
3. DLP rules triggered by legitimate internal documents
4. Scheduled configuration changes (maintenance)
5. Network alerts from traffic to legitimate CDNs / cloud services
6. Duplicates of the same detection across multiple sources

If you can automate these 6 patterns, you've already eliminated 80% of the noise. You don't need to solve the general problem of "AI that understands all security alerts."

### 3. Human-in-the-Loop Is Not Optional

I designed the system with 3 levels of autonomy:

- **Auto-close**: low-risk patterns with high confidence (>95%). Closed and documented.
- **Auto-enrich + recommend**: medium risk. Context is enriched, an action is suggested, but a human approves.
- **Notify only**: high risk or novel pattern. Immediately escalated with all collected context.

The model never decides on something it hasn't seen before. That's human work.

### 4. Measure Everything from Day 1

Before writing a single line of agent code, I built the metrics dashboard. Every system decision is logged with:

- Original alert (hash + category)
- Decision taken (close / escalate / enrich)
- Model confidence
- Processing time
- Whether a human reviewed it afterward and what they decided

This isn't just to justify the project to management. It's to **detect drift**. If the agreement rate with analysts drops below 90%, something changed --- whether in the detections, the environment, or the model.

### 5. Detection Engineering Improves as a Side Effect

The most unexpected effect: with clean data about which alerts are noise and why, conversations about **detection tuning** became much more productive.

It's no longer "I think this rule generates too many false positives." It's "this rule generated 342 false positives in 30 days, all from the same pattern, here's the data." Tuning decisions go from being political to being data-driven.

## What's Next: The Feedback Loop

The next step is closing the loop: having the system not just triage alerts, but **propose changes to detection rules** based on accumulated false positive patterns.

Imagine:

> "Rule X has generated 1,200 alerts in 90 days. 98% were closed as false positive for pattern Y. Recommendation: add exclusion for pattern Y or reclassify as informational."

This turns a reactive system (triage) into a proactive one (continuous detection improvement). It's the difference between fighting fires and preventing them.

## Who This Is For

If you're on a security team with more alerts than you can process (spoiler: almost everyone), you don't need an enterprise "AI SOC" product. You need:

1. **API access to your platforms** (SIEM, ticketing, identity)
2. **An LLM with tool-use capability** (MCP or function calling)
3. **Patience for read-only mode** (4-6 weeks minimum)
4. **Metrics from day 1**

The system I built isn't a product. It's a specific solution for a specific problem. But the architecture --- specialized agents + MCP + persistent memory --- is replicable for any security operations workflow.

The question isn't whether AI can do alert triage. It already can. The question is how many hours of your week you're willing to keep spending on work that a machine can do just as well.

---

*If you're building something similar or have questions about the architecture, reach out. It's always easier the second time around.*
