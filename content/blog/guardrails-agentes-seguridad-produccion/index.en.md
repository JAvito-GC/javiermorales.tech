---
title: "Designing Guardrails for AI Security Agents in Production"
date: 2026-06-02
description: "A practical design pattern guide for building guardrails around AI agents that operate in production security environments — audit logging, write guards, containment protocols, and prompt injection defense."
summary: "AI agents with access to your SIEM, identity provider, and containment actions are privileged processes. Here is how I design guardrails to keep them safe in production."
translationKey: "guardrails-security-agents"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai-agents", "guardrails", "production", "detection-engineering"]
---

An AI agent that can read your SIEM, query your identity provider, and trigger containment actions is not a chatbot — it is a privileged process. It needs guardrails.

I have spent the past year building autonomous security agents that investigate alerts, correlate signals across dozens of data sources, and take containment actions. The single most important lesson: **the hard part is not making agents smart enough to act — it is making them safe enough to trust.**

This post documents the guardrail architecture I use in production.

## Design Principle: Read-Heavy, Write-Restricted

The fundamental design principle is asymmetry. Agents should be able to read everything but write almost nothing without explicit controls.

**Agents CAN freely:**
- Query all data sources (SIEM, identity provider, cloud provider, EDR)
- Calculate risk scores and confidence levels
- Correlate signals across multiple systems
- Generate investigation reports
- Self-audit their own decision history

**Agents CANNOT:**
- Modify user accounts (except at the highest severity levels with approval)
- Change alert status without documented justification
- Write to production infrastructure
- Close investigation cases without evidence chain
- Execute containment actions outside their assigned scope

This asymmetry means an agent failure mode defaults to "it read a lot but did nothing" rather than "it disabled the CEO's account at 3 AM."

## Five Guardrail Layers

### Layer 1: Audit Logging

Every tool call the agent makes gets written to an append-only JSONL log. No exceptions.

```python
import json, time, hashlib

def audit_log(agent_id: str, tool: str, params: dict, result: str):
    entry = {
        "ts": time.time(),
        "agent": agent_id,
        "tool": tool,
        "params": params,
        "result_hash": hashlib.sha256(result.encode()).hexdigest(),
        "prev_hash": get_last_entry_hash()
    }
    # Append-only, tamper-evident chain
    with open(f"/var/log/agents/{agent_id}.jsonl", "a") as f:
        f.write(json.dumps(entry) + "\n")
```

The `prev_hash` field creates a hash chain — if anyone modifies a historical entry, the chain breaks. A separate governance agent validates chain integrity every hour.

### Layer 2: Write Guards

Every mutation operation passes through a write guard that can operate in three modes: `block`, `dry-run`, or `live`.

```python
class WriteGuard:
    def __init__(self, mode: str = "dry-run"):
        self.mode = mode  # "block" | "dry-run" | "live"

    def execute(self, action: str, target: str, params: dict) -> dict:
        if self.mode == "block":
            return {"status": "blocked", "reason": "write guard active"}

        if self.mode == "dry-run":
            return {"status": "dry-run", "would_execute": action, "target": target}

        # Live mode — still requires deny-hook check
        if self.deny_hook_check(action, target):
            return {"status": "denied", "reason": "permanent blocklist"}

        return self._execute_live(action, target, params)
```

New agents start in `block` mode. After a week of reviewing their dry-run logs, I promote them to `dry-run`. Only after hundreds of validated decisions do they earn `live` mode — and even then, only for specific action types.

### Layer 3: Deny Hooks

Some operations are permanently blocked regardless of context. These are non-negotiable:

- Never delete a user account
- Never modify IAM policies
- Never disable audit logging
- Never access credential stores directly
- Never escalate its own permissions

These are hardcoded deny rules, not configurable. No prompt, no severity level, no override can bypass them.

### Layer 4: Actor Scope

When an agent investigates a specific user or system, its containment actions are scoped exclusively to that target. An agent investigating `user-12345` cannot take actions against `user-67890`, even if it believes there is a connection. Expanding scope requires a new investigation with its own approval chain.

### Layer 5: Evidence Signing

Every piece of evidence collected during an investigation is signed with HMAC-SHA256 to maintain chain of custody:

```python
import hmac, hashlib, json, time

def sign_evidence(evidence: dict, signing_key: bytes) -> dict:
    evidence["collected_at"] = time.time()
    evidence["agent_version"] = AGENT_VERSION
    payload = json.dumps(evidence, sort_keys=True).encode()
    signature = hmac.new(signing_key, payload, hashlib.sha256).hexdigest()
    return {"evidence": evidence, "signature": signature}
```

If an investigation ever goes to legal review, every data point has a cryptographic proof of when it was collected and that it has not been altered.

## Prompt Injection Defense

AI agents that ingest external data (alert payloads, email subjects, log entries) are vulnerable to prompt injection. An attacker who controls a log message could attempt to manipulate agent behavior.

My defenses:

1. **XML boundary tags** — System instructions and external data are separated by strict XML boundaries. The agent's instructions are in `<system>` tags; all external input is wrapped in `<external_data>` tags with explicit warnings.

2. **Input validation** — All ingested data goes through schema validation before the agent sees it. If an email subject contains instruction-like patterns (`ignore previous`, `you are now`, `system:`), it gets flagged and sanitized.

3. **Output scanning on tool responses** — When the agent calls an MCP tool, the response is scanned for injection patterns before it is passed back to the agent's context. A compromised external system cannot feed instructions through tool outputs.

## Graduated Containment: Security Action Levels

Not every threat requires the same response. I use four Security Action Levels (SAL):

| Level | Response | Approval Required |
|-------|----------|-------------------|
| SAL 1 | Monitor — increase logging verbosity | None (autonomous) |
| SAL 2 | Soft containment — force MFA, reduce session length | Agent + peer review |
| SAL 3 | Hard containment — suspend active sessions, revoke tokens | Human analyst approval |
| SAL 4 | Full isolation — disable account, block all network access | SOC manager + CISO notification |

The agent determines SAL level based on signal confidence, asset criticality, and blast radius. But crucially, SAL 3 and above always require human approval — the agent proposes, humans dispose.

## Testing

Trust in these guardrails comes from exhaustive testing:

- **1,700+ unit tests** covering agent decision paths, edge cases, and adversarial inputs
- **4 CI gates** that every change must pass: AI-assisted code review, SAST scanning, dependency audit, and semantic analysis of prompt changes
- **Dual-agent validation** — a second agent independently reviews the first agent's investigation conclusions before any containment action executes

The dual-agent pattern catches a surprising number of reasoning errors. When Agent A concludes "this is a compromised account," Agent B independently evaluates the same evidence. Disagreements escalate to human review.

## Lessons Learned

**Start with dry-run everything.** The temptation is to ship agents that can act immediately. Resist it. Run every agent in dry-run for at least two weeks. You will discover decision patterns you never anticipated, and you will be glad they were not executing live.

**Log decisions, not just actions.** When reviewing an incident, knowing what the agent *did* is not enough. You need to know *why* it did it — what signals it weighted, what alternatives it considered, what confidence threshold it crossed. This makes the difference between debugging and guessing.

**Governance agents that audit other agents prevent drift.** Without automated oversight, agent behavior drifts over time as models update, prompts evolve, and data distributions shift. A dedicated governance agent that reviews peer decisions catches drift before it becomes a security gap.

---

AI security agents are force multipliers — but only if you can trust them. The guardrail architecture described here has allowed me to safely deploy agents that handle thousands of alerts per week while maintaining the control surface a security team requires. The key insight: guardrails are not limitations on agent capability — they are what makes capability deployable.
