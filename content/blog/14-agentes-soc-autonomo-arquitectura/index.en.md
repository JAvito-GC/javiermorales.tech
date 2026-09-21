---
title: "14 AI Agents Cleared Our Alert Backlog in 8 Weeks: The Multi-Tier SOC Architecture"
date: 2026-05-26
description: "How I designed a 14-agent autonomous SOC with tiered governance, dual validation, and graduated containment -- from 112 stale alerts to zero backlog in 8 weeks."
summary: "A practical architecture guide for building a multi-agent autonomous SOC: 14 specialized agents across 5 tiers, from signal processing to automated containment."
translationKey: "14-agent-soc"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "soc", "ai-agents", "detection-engineering", "automation"]
---

We went from 112 alerts in backlog to zero in 8 weeks. Not by hiring analysts -- by building 14 specialized AI agents organized in a strict tier hierarchy.

This post is the architecture guide I wish I had when I started. It covers the multi-tier framework, key design decisions, the journey from proof-of-concept to production, and what I would do differently.

## The Multi-Tier Framework

Most SOC automation attempts fail because they treat the problem as a single "auto-triage" step. Real security operations require multiple cognitive phases: signal processing, validation, deep investigation, containment, and governance. Each phase has different trust requirements and different failure modes.

Here is the full pipeline:

```
┌─────────────────────────────────────────────────────────────────┐
│                    TIER 0: GOVERNANCE                            │
│  [Self-Audit Agent] [Decision Quality Monitor]                  │
│  Watches all tiers. Flags drift, bias, hallucination.           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   TIER 1     │    │   TIER 2     │    │   TIER 3     │      │
│  │  Signal      │───▶│  Independent │───▶│  Deep        │      │
│  │  Processing  │    │  Validation  │    │  Investigation│     │
│  │              │    │              │    │              │      │
│  │ - Enrichment │    │ - Re-scores  │    │ - 7-phase    │      │
│  │ - Scoring    │    │   from raw   │    │   parallel   │      │
│  │ - Context    │    │   evidence   │    │   analysis   │      │
│  │   assembly   │    │ - Catches    │    │ - Evidence   │      │
│  │              │    │   T1 errors  │    │   correlation│      │
│  └──────────────┘    └──────────────┘    └──────┬───────┘      │
│                                                  │              │
│                                          ┌───────▼───────┐      │
│                                          │  TIER 3.5     │      │
│                                          │  Containment  │      │
│                                          │               │      │
│                                          │  SAL 1: Log   │      │
│                                          │  SAL 2: Isolate│     │
│                                          │  SAL 3: Block  │     │
│                                          │  SAL 4: Nuke   │     │
│                                          └───────┬───────┘      │
│                                                  │              │
│                                          ┌───────▼───────┐      │
│                                          │   TIER 4      │      │
│                                          │   Human Expert │      │
│                                          │               │      │
│                                          │  - Incident   │      │
│                                          │    declaration│      │
│                                          │  - Systemic   │      │
│                                          │    fixes      │      │
│                                          └───────────────┘      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Tier 0: Governance

Two agents that exist outside the operational pipeline:

- **Self-Audit Agent** -- periodically replays past decisions and checks for consistency, hallucination, or drift from documented procedures.
- **Decision Quality Monitor** -- tracks metrics like false positive rate, escalation accuracy, and time-to-resolution. Raises alerts when quality degrades.

These agents have read access to every tier's outputs but cannot modify them.

### Tier 1+2: Signal Processing and Validation

**Tier 1** takes raw alerts from the SIEM and produces enriched, scored signals. It pulls context from the identity provider, asset inventory, and threat intelligence feeds. The output is a structured evidence bundle with a severity score.

**Tier 2** is the critical differentiator. A completely independent agent re-evaluates the same raw alert without seeing Tier 1's conclusion. It pulls its own evidence and produces its own score. Only when both tiers agree does the alert proceed automatically. Disagreements trigger human review or escalation to Tier 3.

This dual-agent validation catches the single biggest risk in AI-driven triage: confident but wrong closures.

### Tier 3: Investigation

When an alert requires deep analysis, Tier 3 runs a 7-phase parallel investigation:

1. Identity timeline (who did what, when, from where)
2. Network context (lateral movement, anomalous connections)
3. Endpoint forensics (process trees, file modifications)
4. Cloud activity (API calls, permission changes, resource creation)
5. Threat intelligence correlation (IoCs, TTPs, campaign overlap)
6. Historical pattern matching (has this user/system behaved this way before?)
7. Business impact assessment (what is at risk if this is real?)

Each phase runs as a parallel sub-task. Results feed into a correlation engine that produces a unified investigation report with confidence scores per finding.

### Tier 3.5: Automated Containment

The containment tier operates on a graduated severity scale (SAL = Severity Action Level):

- **SAL 1:** Log and monitor. No active response.
- **SAL 2:** Isolate. Revoke active sessions, disable API keys, quarantine the endpoint.
- **SAL 3:** Block. Network isolation, identity suspension, cloud resource freezing.
- **SAL 4:** Full nuke. Account disable, credential rotation, forensic snapshot, full isolation.

SAL 1-2 are fully autonomous. SAL 3 requires one human confirmation. SAL 4 always escalates to Tier 4.

### Tier 4: Human Expert

Some things should never be automated: incident declaration, regulatory notification decisions, architectural remediation, and systemic detection improvements. Tier 4 is not a failure mode -- it is the intentional ceiling of automation.

## Key Architecture Decisions

### Read-Heavy, Write-Restricted

Every agent has broad read access but extremely narrow write permissions. The Tier 1 enrichment agent can query the SIEM, identity provider, and asset database -- but it can only write to the evidence bundle and the internal scoring queue. The containment agent can execute actions but only through a hardened CLI with pre-approved action types.

### Tamper-Evident Evidence Bundles

Every evidence bundle is HMAC-signed at creation. If any field changes after signing, downstream agents reject it. This prevents a compromised or hallucinating agent from retroactively modifying its own evidence trail.

### Graduated Trust

No single agent has both "investigate" and "contain" permissions. The investigation tier produces recommendations. A separate containment agent evaluates those recommendations against policy before executing. Separation of duties, applied to AI.

### Self-Monitoring

The governance layer watches for:
- Score inflation (agents getting "bored" and auto-closing too aggressively)
- Investigation shortcuts (skipping phases when under load)
- Containment drift (SAL levels creeping upward without justification)

## The Journey: POC to Production

### Week 1-2: Proof of Concept

Started with a workflow automation platform and AI model integration. Batch-processed 81 stale alerts in the first run. Results were promising but messy -- the model hallucinated tool names, invented non-existent log entries, and occasionally contradicted itself. Good enough to prove the concept, not good enough to trust.

### Week 3-4: Structured Agent Framework

Migrated from workflows to a proper agent SDK with structured CLI tools. Each tool has a typed schema, input validation, and deterministic output format. The model no longer free-texts its actions -- it calls defined tools with validated parameters. Error rate dropped dramatically.

### Week 5-6: Investigation and Containment

Added Tier 3 (parallel investigation) and Tier 3.5 (graduated containment). The 7-phase investigation model emerged from observing what human analysts actually do when they get a complex alert. The SAL framework came from our existing incident severity definitions.

### Week 7-8: Governance and Hardening

Built the governance layer, wrote 1700+ tests, established 4 CI gates (lint, unit, integration, end-to-end simulation). Added HMAC signing to evidence bundles. Ran a red team exercise where we intentionally fed adversarial alerts to test agent resilience.

## Results

After 8 weeks in production:

- **Per-alert triage time:** ~3 minutes (down from 15-30 minutes manual)
- **Speed improvement:** 5-10x across the pipeline
- **Investigation rate:** 100% (every alert gets at least Tier 1+2 processing)
- **Human escalation rate:** less than 5%
- **Alert backlog:** zero (from 112 stale alerts at start)

The biggest win was not speed -- it was coverage. Before, low-priority alerts sat in backlog for days or weeks. Now every alert gets processed within minutes of firing, regardless of priority.

## What I Would Do Differently

**Start with Tier 2 from day one.** We added dual validation in week 4. The false closures from weeks 1-3 (without independent validation) created trust debt that took weeks to recover from with stakeholders.

**Invest in observability early.** The governance layer should not be the last thing you build. Instrument every agent decision from the start. You cannot improve what you cannot measure.

**Do not underestimate the tool schema work.** 60% of our development time went into building reliable, well-typed CLI tools for agents to call. This is not glamorous work, but it is the foundation. A model is only as good as the tools it can use.

**Test with adversarial inputs.** Normal alerts are easy. The hard cases are alerts that look benign but are not, or alerts that look critical but are noise. Build your test suite around edge cases, not happy paths.

**Plan for agent disagreement.** When Tier 1 and Tier 2 disagree, you need a clear resolution protocol. We spent a week figuring this out reactively. Define it upfront.

---

Building a multi-agent SOC is not about replacing analysts. It is about giving every alert the investigation it deserves, and giving analysts the time to focus on what only humans can do: understanding adversary intent, improving defenses systemically, and making judgment calls that require organizational context.

The 14-agent architecture is not the end state. It is a framework that grows as trust grows. Start with Tier 1, prove it works, add validation, prove that works, and keep climbing. The tier model gives you natural checkpoints for expanding automation safely.
