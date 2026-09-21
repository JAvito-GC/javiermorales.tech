---
title: "One Security Engineer, a Whole Team: How I Run Like a SOC With AI (and What I Never Delegate)"
date: 2026-08-10
draft: false
description: "How a solo security engineer can operate like a full SOC by orchestrating AI agents for triage, correlation, and detection — and the three things you should never delegate."
summary: "The intelligence arbitrage thesis applied to security ops: which parts of a SOC's work you orchestrate with agents, what you never automate, and the discipline that keeps it from turning into a disaster."
translationKey: "solo-soc-operator-ia"
og_image: "/img/og-default.png"
tags: ["security", "soc", "ai-agents", "detection-engineering", "intelligence-arbitrage"]
---

There's a line I repeat until I'm sick of it: **one person with the right tools and AI performs like a whole team.** It's not marketing. It's what I keep proving as I build real things — a price aggregator that scrapes half a market, security kits, audit tooling — all solo, all with agents doing the heavy lifting.

But there's a huge gap between believing that line and surviving it in security operations, where getting it wrong doesn't mean a blog post with a typo: it means an incident you never saw, or a destructive action you fired off yourself with a badly supervised agent.

This post is the honest map: which parts of a SOC's work you can orchestrate with AI as a single person, what you must **never** delegate, and the discipline without which all of this becomes a machine for manufacturing false confidence.

## What orchestrates well

Security operations work isn't a monolithic block. It's a set of distinct cognitive phases, and only some of them lend themselves to agent orchestration.

**First-level triage.** Eighty percent of a SOC's alerts are noise shaped like urgency. An agent that takes the alert, enriches it with context (geo-IP, reputation, user history, whether the asset is critical) and produces a preliminary verdict with its reasoning saves you the most repetitive, demoralizing work there is. It doesn't decide. **It orders your queue.**

**Cross-source correlation.** The classic pain of the solo analyst is console-hopping: SIEM, identity, cloud, ticketing, each in its own tab. An agent with structured read access (MCP does this cleanly) pulls the whole story into a single narrative: "this odd login lines up with a mail-forwarding rule created 20 minutes ago and a bulk download." That's exactly what a human would take 15 minutes to reconstruct by hand.

**Detection generation (draft).** Writing the first version of a Sigma rule or a detection query from a TTP is a perfect task for an agent. It gives you the skeleton; you harden it, test it against real data, and tune it. Detection-as-code accelerates brutally here — as long as human review stays non-negotiable (we'll get there).

**Reporting and documentation.** Incident summaries, timelines, post-mortem drafts. The agent writes the boring 70%; you supply the judgment and the conclusion. Here the risk is low and the time saved is enormous.

## What you never delegate

This is where most of the enthusiastic "automate your SOC" threads lie by omission.

**The containment decision.** Isolating a host, disabling an account, blocking an IP at the perimeter. These are actions capable of taking down production and tipping off the attacker. An agent can *propose* containment with all the context chewed through; the finger on the button is human. Automatic containment only in ultra-scoped, reversible cases with a known blast radius — and even then, with logging and an alert.

**The final verdict on a real incident.** Triage orders; the determination that "this is a breach" is one you sign. Models hallucinate with confidence and eloquence. An agent that tells you "false positive" in a perfectly written paragraph is more dangerous than one that fumbles the answer clumsily, because it lowers your guard.

**Threat modeling and priorities.** What to defend first, what risk you accept, where your crown jewels are. That's business judgment and context the model doesn't have. Delegating it is delegating your job, not automating it.

## The discipline, or this becomes a disaster

AI doesn't turn you into a team. It gives you **the leverage** of a team if — and only if — you keep a discipline most people skip because it's boring.

**Read access by default.** Agents see almost everything and touch almost nothing. Every write capability or destructive action is an explicit decision, with its justification, not a permission inherited "for convenience." I learned this building my own tools: agents run behind hooks that block destructive operations and protected paths before they execute. You don't trust the agent to behave; **you make it impossible for it to misbehave.**

**Everything an agent does lands in an auditable log.** If you can't reconstruct why an agent closed an alert or proposed an action, you don't have a SOC: you have a black box that will surprise you on the worst possible day.

**Cross-validation on what matters.** For weighty outputs, don't trust a single pass. A second agent that critiques the first one's verdict, or a rule tested against historical data before it goes to production. Redundancy is cheap; the incident you didn't see is not.

**You're still the analyst.** The day you stop reading what your agents do and start approving on autopilot, you've recreated the original problem — alerts without context — with an extra layer of unearned trust on top.

## The real equation

Intelligence arbitrage is true, but with fine print: **one person + AI performs like a team in volume and speed, not in judgment.** Volume is orchestrated. Judgment stays human, scarce, and expensive on purpose.

The solo security engineer who understands that line operates like a whole SOC. The one who erases it builds a machine for generating very well-written false negatives.

I've been on the good side of that line for a while because I drew it before writing the first line of orchestration. That's the whole difference.
