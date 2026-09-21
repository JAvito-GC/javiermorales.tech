---
title: "AI Can Find 10,000 Vulnerabilities in Weeks. Who's Going to Patch Them?"
date: 2026-06-09
description: "Anthropic reports an internal system found over 10,000 high- and critical-severity vulnerabilities in weeks. The interesting part isn't the finding. It's that the bottleneck just moved — from discovery to remediation — and most security orgs aren't built for the new constraint."
summary: "When AI finds vulnerabilities faster than humans can patch them, the limiting factor stops being detection and becomes verification and remediation. Amdahl's law applied to security operations: a security engineer's read on Anthropic's recursive self-improvement essay."
translationKey: "ai-finds-10000-vulns-who-patches"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai-agents", "vulnerability-management", "detection-engineering", "appsec"]
---

On June 9, 2026, Anthropic's institute published an essay titled *When AI builds itself* — a look at how AI is starting to accelerate AI development. Most of the coverage will focus on the headline: models writing their own successors, recursive self-improvement, the usual mix of awe and dread.

I want to pull out one line that most people will skim past, because it's the one that actually changes my job:

> An internal system (Project Glasswing) found "more than ten thousand high- and critical-severity software vulnerabilities" in a matter of weeks.

Set aside whether you trust the number — it's Anthropic's own figure, internal and forward-looking, and I'm citing it as theirs, not as independent fact. The point doesn't depend on the exact count. The point is the *shape* of what just happened: vulnerability discovery, the thing security teams have spent two decades trying to scale, is no longer the hard part.

The hard part is everything that comes after.

---

## The bottleneck just moved

For most of the history of application security, the scarce resource was *finding* the bug. You hired pentesters. You bought scanners that drowned you in false positives. You ran bug bounties and waited. Discovery was slow, expensive, and human-bound — so the entire discipline organized itself around the assumption that findings are precious and rare.

That assumption is dying. When an AI system can surface ten thousand real, high-severity findings in weeks, findings stop being the constraint. The constraint becomes:

- **Triage** — which of these ten thousand are actually exploitable in our context?
- **Verification** — is this a true positive, or a confident-sounding hallucination?
- **Remediation** — who writes the fix, who reviews it, who ships it without breaking production?

Every one of those is still, today, gated by human judgment. And that's the whole problem.

---

## Amdahl's law, applied to security

There's a principle from computer architecture called Amdahl's law. Roughly: if you speed up one part of a process but leave another part untouched, the untouched part caps your total speedup. Make the fast part infinitely fast and you're still limited by whatever you didn't accelerate.

Anthropic's essay makes this point about code generation — as AI writes more code, *human review* becomes the throughput ceiling. They even note that their own pre-merge Claude reviewer would have caught roughly a third of the bugs behind past production incidents. The reviewer helps. But review capacity is finite.

The same law applies, harder, to vulnerability management:

| Phase | 2023 | 2026 (AI-assisted) |
|-------|------|--------------------|
| Discovery | Slow, human-bound | Near-instant, abundant |
| Triage | Manageable volume | Overwhelmed |
| Verification | Per-finding human review | Now the bottleneck |
| Remediation | The slow part | Still the slow part |

If discovery goes from a trickle to a firehose and remediation stays at human speed, your backlog doesn't shrink — it explodes. You've optimized the part that was never really the constraint and left the constraint exactly where it was. A vulnerability that's *found* but not *fixed* is not security progress. It's a liability with better documentation.

---

## What this means if you run security operations

This isn't a reason to ignore AI-driven discovery — that ship has sailed, and your adversaries are already on it. It's a reason to rebalance where you invest. A few concrete shifts I'd argue for:

**1. Stop measuring detection. Start measuring time-to-remediation.** The number of findings is about to become meaningless — it'll be enormous by default. The metric that matters is how fast a confirmed, exploitable finding gets a shipped, verified fix. If your dashboards still celebrate "vulnerabilities detected," they're measuring the wrong half.

**2. Treat verification as a first-class engineering problem.** When findings are abundant, your scarce resource is *trustworthy triage at scale*. That means automated reproduction (does this actually exploit?), context-aware prioritization (is this path even reachable in prod?), and ruthless false-positive filtering. The teams that win won't be the ones that find the most — they'll be the ones that can *believe* their findings fast enough to act.

**3. Build the remediation pipeline before you turn on the firehose.** AI that proposes fixes is the obvious next step, and it's coming. But an AI-written patch still needs human review — which puts you right back against Amdahl. Invest now in the boring infrastructure: reproducible builds, fast test suites, staged rollouts, automated regression checks. That infrastructure is what determines how fast you can *safely* absorb fixes, AI-generated or not.

**4. Keep humans where judgment compounds.** Anthropic's own framing is that human comparative advantage is shifting toward *taste and judgment* — choosing what to work on, deciding when to trust a result, spotting the dead ends. In security that maps cleanly: let the machine find and reproduce; keep humans on "is this risk worth our remediation capacity this quarter?" That decision doesn't scale by throwing more findings at it.

---

## The deeper shift

We spent twenty years building an industry around the scarcity of finding bugs. That scarcity is ending. The orgs that thrive over the next few years won't be the ones with the best scanners — everyone will have an excellent scanner. They'll be the ones who rebuilt their operating model around the new bottleneck: turning an overwhelming stream of findings into a manageable stream of *verified, prioritized, shipped fixes.*

The question stops being "can we find the vulnerabilities?" The answer to that is now, increasingly, yes — trivially, abundantly, faster than you asked for. The question becomes the one Anthropic's essay quietly raises: who, and what process, is going to keep up?

---

## Build agents and pipelines that hold up under that load

If you're wiring AI into your security operations — discovery, triage, or remediation — you need a control layer that keeps the automation trustworthy: verification you can audit, guardrails on what the agent can touch, and isolation between what finds problems and what fixes them. I built one and open-sourced the patterns behind it: pre/post-tool hooks, prompt-injection detection, integrity checksums, subagent validation, and 68+ automated tests.

**[AI Agent Defense Kit](https://javiermoralesecurity.gumroad.com/l/ai-defense-kit)** — $49. Threat models, 12 incident-response playbooks for agent failures, SOC 2 / ISO 27001 compliance mapping, and an implementation guide.

---

*For a deeper treatment of defense architectures for autonomous AI systems — multi-agent orchestration, memory isolation, continuous monitoring patterns — see my book [Securing Autonomous AI](/books/).*
