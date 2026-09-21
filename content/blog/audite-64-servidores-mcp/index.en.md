---
title: "I Audited 64 Public MCP Servers With a Linter I Wrote. 63 Came Back Clean"
date: 2026-07-27
description: "I wrote a security linter for MCP servers and AI agents and ran it against 64 public repos —AWS, Stripe, Google, Sentry, Prisma. The result says more about the real state of agent security, and about false positives, than any alarmist headline. It's free and open source."
summary: "A static scanner (Python, zero dependencies, zero network) that audits MCP server and agent configs against the OWASP Agentic Top 10, with detection guidance for every finding. I validated it against 64 public MCP repos: 63 with no serious findings. This post covers what I found, why most of the initial noise was false positives, and what I learned tuning them out — the honest part tool launches skip."
translationKey: "agent-audit-kit-launch"
draft: false
og_image: "/img/og-default.png"
tags: ["detection-engineering", "ai-security", "mcp", "owasp", "open-source"]
---

There's a lot written about securing AI agents, and almost all of it is abstract: governance frameworks, checklists, the EU AI Act. Little of it tells you, looking at your actual `mcp.json`, what's wrong and how to detect it when someone exploits it.

So I wrote the linter I was missing. And instead of launching it with an alarmist headline, I did something more useful and more uncomfortable: I ran it against **64 public MCP servers** —from AWS, Stripe, Google, Sentry, Prisma, Neon, Grafana, Cloudflare and more— and forced myself to verify every finding by hand. What I learned tuning it is half the value of this post.

## The gap: prevention yes, detection no

The tools that exist —and there are good ones, from Trail of Bits to Anthropic itself— focus on *preventing*: here's the flaw, fix it. Correct and insufficient. In real security you can't always fix it today: the flaw lives in a dependency, in an agent you don't control, or in someone else's product decision. The question left is: *if I can't fix it now, how do I detect it's being abused?*

That's the question I ask for a living as a detection engineer, and the one no agent tool answered. So I built it in: **every finding ships with detection guidance** —the logs and signals to catch the abuse in production— with ready-to-deploy Sigma rules for the highest-severity classes.

## What I found in 64 repos: less than you'd expect, and that's the story

**63 of 64 came back with no serious findings.** Exactly one had a real, weighty flaw, which I get to below.

That result isn't disappointing — it's the lesson. When I ran the first version of the scanner, it returned 15 "findings", including several criticals. That would have been enough for an alarmist post along the lines of "I found critical flaws in big-company MCP servers." It would have been dishonest. Verifying them one by one, most were **false positives**:

- A `remove` command flagged as "destructive action with no confirmation"… that had a `--yes` flag precisely because it **prompts** by default.
- A `logger.remove()` (logging config) mistaken for a destructive operation.
- A *deliberately* read-only code sandbox flagged as "excessive agency" — the exact opposite.
- Ordinary HTTP code (`getProxyAgent()`, `userAgent()`) classified as an "AI agent" because my detector matched `Agent(` as a substring.

Every false positive was a lesson about my own tool. A scanner that shouts "critical" over healthy code isn't rigorous, it's noise — and in security, noise kills trust faster than a missed flaw. Most of the work wasn't *finding* flaws, it was **teaching the scanner to shut up when there isn't one.** The result: from 15 noisy findings to 2 verified, with 63 of 64 repos clean.

## The one real flaw, and why it's instructive

The finding that survived verification: a research agent that takes a user-supplied URL, `WebFetch`es that site, and **drops the raw content straight into the prompt** —"extract what this company does, how money flows…"— with no injection defense declared.

It's a textbook prompt-injection surface: untrusted web content → model context, no sanitization or delimiters. It's not a code bug with an obvious patch; it's a design decision with a risk worth looking at. And it's exactly the kind of pattern an agent auditor should flag: not an obvious `eval()`, but the pipe through which text nobody controls gets in.

## Honesty about what the scanner does NOT do

Here's the part most launches leave out. A static scanner is **precise** on declarative things: hardcoded secrets in `mcp.json`, "read-only" agents holding write tools, unpinned dependencies, poisoned tool descriptions. It doesn't miss those.

But prompt injection and exfiltration depend on **data flow** —is the input from an untrusted source?— and static analysis can't prove that. So those checks are *best-effort*: when the signal is weak, the scanner emits an advisory note, not a weighted finding. I'd rather ship a tool that admits its limits than one that fakes precision it doesn't have. That honesty *is* the feature.

## It's free, and why

The core is open source, MIT-licensed: **[github.com/JAvito-GC/agent-audit-kit](https://github.com/JAvito-GC/agent-audit-kit)**. No signup, clone it and run it. Runs anywhere Python 3.8+ runs, no dependencies, no network, no telemetry — your configs never leave your machine.

It's free on purpose. The agent-security tooling market is already open source; competing by selling a scanner against free, well-maintained tools is a waste of time. What I bring isn't the software: it's the detection angle and the judgment of having verified this by hand against 64 real repos.

## Getting started

```bash
git clone https://github.com/JAvito-GC/agent-audit-kit
cd agent-audit-kit
python3 scanner/agent_audit.py /path/to/your/agents --json \
  | python3 scanner/report.py --auditor "Your Name" > report.html
```

Point it at your agents. And if it hands you a false positive, tell me — I know exactly what it takes to hunt them down.
