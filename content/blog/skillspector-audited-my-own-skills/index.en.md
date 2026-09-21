---
title: "26% of AI Agent Skills Are Vulnerable. I Audited My Own."
date: 2026-06-16
description: "NVIDIA's research found 26% of agent skills contain vulnerabilities. I scanned all 29 of my own Claude Code skills against the same taxonomy — and found something more interesting than a clean result."
summary: "A study of 42,447 agent skills found 26.1% vulnerable and 5.2% likely malicious. I ran my own 29 skills against the SkillSpector taxonomy. They came back clean — but the audit exposed three real gaps in my defense model, and the fix became a new tool."
translationKey: "skillspector-audit"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai", "research", "claude-code", "open-source"]
---

I tried to scan my own AI agent skills for a `curl | bash` pattern. My own security hook blocked the command before it could run.

```
BLOCKED: Pipe-to-shell execution blocked
```

I was the owner. I was running a read-only `grep`. And the enforcement layer still stopped me — because the pattern matched, and the layer does not care who you are. That is the whole thesis of this post in one accident: the controls that matter are the ones the operator cannot talk their way around. Not even the operator.

Here is why I was grepping in the first place.

---

## The Number

NVIDIA published [SkillSpector](https://github.com/nvidia/skillspector), an open-source scanner that vets AI agent skills *before* you install them. It ships with a taxonomy of 64 vulnerability patterns across 16 categories — prompt injection, data exfiltration, privilege escalation, supply chain, MCP tool poisoning, and more.

The number that made me stop scrolling came from the research behind it — a study titled *Agent Skills in the Wild* (Liu et al., 2026) that analyzed **42,447 skills** from major marketplaces:

- **26.1%** contain at least one vulnerability
- **5.2%** show likely malicious intent
- Skills with executable scripts are **2.12x** more likely to be vulnerable

A "skill" is just a folder with instructions and sometimes code that you drop into your agent to extend it. One in four of those, in the wild, is carrying something it shouldn't. One in twenty is probably hostile by design.

I run 29 skills in my own Claude Code setup — SEO tools, a deploy pipeline, research engines, content generators. So I did the obvious thing. I turned the taxonomy on myself.

---

## Auditing My Own 29 Skills

I did not install SkillSpector. (I have a standing rule: never run third-party tooling inside this environment — the irony of installing an unvetted security scanner to check for unvetted code is not lost on me.) I used its taxonomy as a reference and audited against the high-signal patterns directly:

- **SC2 — External script fetching:** remote content piped into a shell
- **AST1 — Dynamic execution:** `eval`, `exec`, `os.system`, `subprocess(shell=True)`
- **E2 / PE3 — Credential access:** reading env vars or secret stores and shipping them out
- **RA1 — Self-modification:** a skill writing to the agent's own control layer
- **TP2 — Unicode deception:** zero-width characters, RTL overrides, homoglyphs hidden in descriptions

The result: **clean.** No dynamic execution. No credential harvesting. No fetch-to-interpreter. No self-modification. The only non-ASCII characters were Spanish accents and a multiplication sign in a formula — not the homoglyph attacks the pattern is meant to catch.

That is the honest result, and a boring one to write about. "I checked and everything was fine" is not a story. So I kept going and asked the more useful question: *why* was it clean — and where would it stop being clean?

---

## The Three Gaps I Found

My skills are clean today not because I scan them, but because of a defense system that runs *around* the agent — four shell hooks that intercept every tool call, validate subagent prompts, and verify file integrity on every session. (I mapped that system attack-by-attack in [a previous post](/blog/ai-agents-of-chaos-paper-defense-mapping/).)

But mapping the 16 SkillSpector categories against my hooks exposed something I had not admitted to myself. My defense is almost entirely a **runtime** model. It catches dangerous behavior at the moment of execution. That leaves three real gaps:

**Gap 1 — No pre-install static scan.** If a skill contained a `curl | bash` line, my runtime hook would block it *when it tried to run*. But nothing inspected the skill *before* it entered the environment. I was trusting that I'd catch it live. That is a worse position than catching it at the door.

**Gap 2 — No malware signatures.** SkillSpector ships YARA rules for known-bad patterns. I have none.

**Gap 3 — No dependency audit on install.** A new skill bundling a vulnerable package would slip past me until that package actually did something.

This is the part most "I audited my system and it's secure" posts leave out. A clean result is not the same as full coverage. The gaps are where the next attack lives.

---

## Closing Gap 1: a tool, not a promise

Gaps 2 and 3 I am choosing not to fix with code — and I want to be explicit about that, because silent omissions are how security theater works. Both gaps only matter if I install third-party skills. I don't. They are mitigated by **policy**, not engineering, and stating that openly is the honest posture.

Gap 1 is different. "I'll catch it at runtime" is a hope, not a control. So I built the missing layer: a pre-install static scanner, `/skill-audit`. Read-only. Zero dependencies. It never executes skill code and never touches the network — it greps for the same high-signal patterns and maps each hit back to the SkillSpector category it belongs to.

I validated it in both directions, because a scanner that only ever says "clean" is useless:

- Against my 29 real skills → **clean**, exit 0. It agreed with my manual audit.
- Against a deliberately malicious test skill (`curl | sh`, `cat ~/.ssh/id_rsa | nc`, `rm -rf /`, `os.system`) → **four findings**, correct severities, the innocent skill beside it untouched.

One detail I enjoyed: the scanner skips its own source. Its pattern catalogue *contains* every signature it hunts for, so scanning itself produces nothing but false positives — the same self-exclusion problem every real security tool has to solve. And when I wrote the malicious test fixture, my pre-tool hook blocked me again for typing the literal `curl | bash` into a command. I had to generate the test file from Python to get around my own defenses. That is the system working exactly as designed.

---

## The Real Lesson: Install-Time vs Run-Time

SkillSpector and my hooks are not competitors. They guard different doors.

```
┌──────────────────────────────────────────────┐
│  A new skill arrives                          │
├──────────────────────────────────────────────┤
│  ① INSTALL-TIME  (SkillSpector / skill-audit) │
│     Static scan before the code can run       │
│     - curl-to-shell, dynamic exec             │
│     - credential access, self-modification    │
│     - unicode deception, known-bad signatures │
├──────────────────────────────────────────────┤
│  The skill runs                               │
├──────────────────────────────────────────────┤
│  ② RUN-TIME  (pre/post-tool hooks)            │
│     Block dangerous behavior as it happens     │
│     - destructive commands, protected writes   │
│     - prompt injection, credential leaks       │
│     - subagent validation, integrity checks    │
└──────────────────────────────────────────────┘
```

A static scan can be fooled by code that assembles its payload at runtime. A runtime hook can't stop a skill it never knew was risky until it acted. Each layer covers the other's blind spot. That is not redundancy — it is defense-in-depth, and it is the entire point.

The uncomfortable takeaway from NVIDIA's 26% is not "scan your skills." It is that the agent ecosystem grew a supply chain — marketplaces, shared skills, one-click installs — before it grew the security model a supply chain demands. We have been here before with npm, with PyPI, with browser extensions. The pattern is always the same: distribution arrives first, and the audit layer arrives after the first incident.

Build the audit layer before the incident.

---

## Try It Yourself

If you run Claude Code skills — especially any you didn't write — audit them. You can use NVIDIA's [SkillSpector](https://github.com/nvidia/skillspector) for the full AST/LLM/OSV pipeline, or write a lightweight pass like mine. The point is not the tool. The point is that *something* inspects a skill before it earns your trust, and *something else* watches it once it runs.

My runtime defense system is open source: [github.com/JAvito-GC/claude-guardrails](https://github.com/JAvito-GC/claude-guardrails) — pre/post-tool hooks, prompt injection detection with Unicode normalization, integrity checksums, and subagent validation.

---

## Get the Production-Ready Framework

The open source repo gives you the runtime hooks. The kit gives you the rest: threat model templates, 12 incident response playbooks for AI agent failures, SOC 2 and ISO 27001 compliance mapping, and a security posture scoring rubric.

**[AI Agent Defense Kit](https://javiermoralesecurity.gumroad.com/l/ai-defense-kit)** — $49

---

*For a deeper treatment of defense architectures for autonomous AI systems — install-time vetting, runtime enforcement, memory isolation, and continuous monitoring — see my book [Securing Autonomous AI](/books/).*
