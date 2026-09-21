---
title: "How I Built an Autonomous SOC with MCP + Claude"
date: 2026-04-22
description: "Architecture of an autonomous security operations platform integrating SIEM, identity, cloud, and ticketing through Model Context Protocol and specialized AI agents."
tags: ["MCP", "Claude API", "Security", "AI Agents"]
og_image: "/img/og-soc.png"
translationKey: "autonomous-soc"
---

A typical SOC (Security Operations Center) has a fundamental problem: **too many alerts, too little context, and too little time.**

An analyst receives an alert. Opens the SIEM. Searches logs. Switches to the identity console. Verifies the user. Opens ticketing. Checks for previous incidents. Back to the SIEM. All manual, all slow, all repetitive.

This article explains how I built a platform that automates this entire workflow.

## The Architecture: MCP as the Backbone

Model Context Protocol (MCP) is the standard that allows a language model to connect with external tools in a structured way. Instead of giving the model direct API access, MCP defines a clean protocol:

```
    ┌─────────────────────────────────────────────┐
    │              Claude (LLM)                    │
    │   Reasoning + Decision + Response            │
    └──────────────────┬──────────────────────────┘
                       │ MCP Protocol
    ┌──────────────────▼──────────────────────────┐
    │              MCP Servers                      │
    ├──────────┬───────────┬──────────┬───────────┤
    │  SIEM    │ Identity  │  Cloud   │ Ticketing │
    │  Server  │  Server   │  Server  │  Server   │
    └──────────┴───────────┴──────────┴───────────┘
         │          │           │           │
    ┌────▼───┐ ┌────▼───┐ ┌────▼───┐ ┌────▼────┐
    │ Panther│ │  Okta  │ │  AWS   │ │  Jira   │
    │        │ │        │ │        │ │         │
    └────────┘ └────────┘ └────────┘ └─────────┘
```

### Why MCP and Not Direct API Calls?

1. **Separation of concerns**: the model reasons, MCP servers execute
2. **Security**: each server has minimal permissions and independent auditing
3. **Modularity**: adding a new source means creating a new server, not rewriting the agent
4. **Open standard**: any MCP-compatible model can use the same servers

## The Agents: Specialization by Tier

I don't use a generic agent for everything. Each investigation level has its own specialized agent:

### Triage Agent (Tier 1)

The first responder. Receives the alert and performs initial assessment:

```
Incoming alert
    │
    ▼
┌─────────────────────────┐
│   Triage Agent          │
│                         │
│ 1. Parse alert          │
│ 2. Enrich context       │
│    - User (Identity)    │
│    - Account (Cloud)    │
│    - History (SIEM)     │
│ 3. Classify             │
│    - FP / TP / Unknown  │
│ 4. Decide               │
│    - Close              │
│    - Escalate           │
│    - Investigate deeper │
└─────────────────────────┘
```

This agent handles 70-80% of alerts. Most are false positives that close with enough context: "It's Terraform doing what Terraform does."

### Investigation Agent (Tier 2)

When triage needs to go deeper:

- Temporal correlation: what else happened in that account in the last 24 hours?
- Behavioral analysis: is this pattern normal for this user?
- Indicator expansion: are other users or accounts affected?
- Vulnerability lookup: does this account have known exposures?

### Forensic Agent (Tier 3)

For confirmed incidents:

- Complete attack chain timeline
- MITRE ATT&CK mapping
- Containment recommendations
- Incident report draft

## Integrations: 6+ Platforms

Each platform has its dedicated MCP server:

| Platform | Function | Operations |
|----------|----------|------------|
| SIEM | Detection & logs | Search alerts, query logs, get context |
| Identity Provider | Identity management | User info, MFA status, active sessions |
| Cloud APIs | Infrastructure | Resource state, configuration, permissions |
| Ticketing | Incident management | Create tickets, find precedents, update status |
| Collaboration | Communication | Notifications, escalation, approvals |
| Vulnerability Scanner | Security posture | Vulnerabilities per asset, active CVEs |
| Endpoint Management | Devices | Device state, installed software |

## The Complete Flow

A real example (anonymized):

```
09:15 — Alert: "Unusual API call from new IP in production account"

09:15 — Triage Agent:
        → SIEM: get alert details
        → Identity: verify user — human, DevOps engineer
        → Cloud: verify account — production
        → SIEM: search user's previous activity — first time from this IP
        → Classification: NEEDS_INVESTIGATION

09:16 — Investigation Agent:
        → SIEM: full user activity last 48h
        → Identity: recent changes to user (new device?)
        → Cloud: what resources were accessed from this IP?
        → Vulnerability: does the account have exposures?
        → Conclusion: User on new VPN (new remote office).
           Pattern consistent with their role. No malicious indicators.
        → Action: Close as FP, update IP baseline

09:17 — Total: 2 minutes automated vs 45 minutes manual
```

## Results

| Metric | Manual | With AI | Improvement |
|--------|--------|---------|-------------|
| Mean triage time | 45 min | 5 min | 9x |
| Automated coverage | — | 78% | Of alerts resolved without human |
| Workflows created | — | 15+ | Reusable |
| Weekly savings | — | 7+ hours | Analyst time |

## Defensive Architecture

An AI agent with access to 6+ security platforms is a high-value target. The security of the system itself is critical:

### Defense Layers

1. **Integrity verification**: SHA256 checksums of all agent configuration files
2. **Prompt injection scanning**: all MCP responses scanned before processing
3. **Minimal permissions**: each MCP server has only the operations it needs, nothing more
4. **Audit trail**: every tool call logged with timestamp, parameters, and result
5. **Guardrails**: rules blocking destructive operations or out-of-scope access

### Agent Monitoring

The agent itself is monitored:

- Watchdog verifying agent responsiveness
- Alerts if the agent makes decisions outside normal patterns
- Rate limiting on external API calls
- Documented manual fallback for every automated workflow

## Lessons Learned

1. **Start with triage, not investigation.** 80% of the value is in quickly classifying what's noise
2. **MCP > direct API calls.** Standardization enables fast iteration while maintaining security
3. **Specialized agents > generic agent.** An agent that does everything does nothing well
4. **Manual fallback is mandatory.** Every automated workflow needs a documented procedure for when the agent fails
5. **Secure the securer.** If your security agent isn't protected, you've created a new attack vector

---

*This article reflects general SOC automation patterns with AI. Details are generic and do not represent any particular organization's architecture.*
