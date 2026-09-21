---
title: "The Hidden Cost of Agent Loops — A Security and FinOps Take"
date: 2026-06-17
description: "The people telling you to run AI agents in autonomous loops have unlimited tokens. You don't. Here's how to read the loop hype through a security and cost lens — and why the real skill is knowing when not to use an agent at all."
summary: "Loop engineering is the title of the week. But the engineers promoting it work at the token dispensaries and never see the bill. I break down the loop hype from two angles the hype skips — what it costs, and what it does to your control model — and land on the rule that actually matters: the agent executes decisions, it does not get to make them."
translationKey: "hidden-cost-agent-loops"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai", "finops", "claude-code", "agents"]
---

There is a Warren Buffett line that fits this week perfectly: never ask a barber if you need a haircut. This week, the barbers of AI decided everyone needs a trim.

The trim is called the *loop*. And before you rewrite your LinkedIn bio to "Loop Engineer" — that title is roughly 72 hours old — it's worth reading the trend through two lenses the people selling it tend to skip: what it costs, and what it does to your control model.

---

## What a loop actually is

A loop is simple to describe. You give an agent a goal — "fix this failing test," "triage these alerts," "keep the build green" — and instead of returning one answer, it works on its own: it tries, checks its own output, and repeats until the result passes its own bar. It can spawn sub-agents to run subtasks in parallel. You don't prompt it again. You let it run.

The pitch is intoxicating, and it's not wrong. Engineers behind the major coding agents have been describing dozens of these loops running at once — one watching CI, one keeping tests green, one summarizing feedback every thirty minutes. Set them off and walk away. It genuinely is a glimpse of how a lot of work will get done.

There is just one detail the pitch leaves out.

---

## Detail one: every iteration has a meter running

A loop's defining feature — *try, fail, correct, retry, until it's perfect* — is also its defining cost. Every iteration is a round trip to a model, and every round trip is billed in tokens.

I don't have to theorize about the numbers, because creators have started publishing theirs. One documented **$3,377 in token usage across 28 days on a single machine** — against a $220/month subscription. On a second machine, **$8,560 in a month**. A single task, one prompt that fanned out into a swarm of agents and ran for one hour and forty minutes, cost roughly **$140**. One prompt.

Now layer on the model economics. When Anthropic shipped Claude Fable 5 in June 2026, it landed as the most capable model available — and priced at roughly **double** the previous Opus per token. So the loudest advice of the month reduces to: *run the technique that consumes the most iterations, on the model that costs the most per iteration.* Coming, in several cases, from people whose employer hands them tokens for free.

That is the barber. When someone with an unlimited token budget tells you autonomous loops are the future, they are describing their reality, not yours. For them, $50,000 a month in tokens is a Tuesday. You and I get a quota that resets weekly and an invoice at the end of the month. The advice isn't dishonest — loops may well be the future — but the cost is offloaded entirely onto the person taking it.

This is a FinOps problem wearing an engineering costume. And like every FinOps problem, the fix is not to stop — it's to **measure before you scale**. You cannot reason about a loop you can't see the cost of. Before you set thirty agents running overnight, you need to answer four boring questions: what am I spending across all tools, what is it returning, what is each task worth, and what is running right now. If you can't answer those from memory, you are gambling, not engineering.

---

## Detail two: a loop is an expansion of your attack surface

Here is the part the cost conversation misses, and the part I care about most.

The moment you take yourself out of the loop, two things go up at once: your leverage, and your risk. A system that only runs when you fire it off is safe in a dull way — nothing happens without you. A system that fires on its own, while you're asleep or in a meeting, is real leverage. It is also a process executing with no human reading the output before it reaches a customer, pulls the wrong data, or sends the wrong message to the wrong list.

An autonomous loop is, from a security standpoint, an unattended process with credentials, network access, and the ability to act. We have a whole discipline for that, and none of it says "let it run and hope." It says: least privilege, bounded blast radius, observability, and a kill switch. A loop that can retry forever needs a budget ceiling the same way a service account needs a permission boundary — not because you expect abuse, but because the failure mode of *no limit* is unbounded.

This is why my own automation is deliberately boring. The scrapers behind a price-aggregator I run solo execute on fixed cron schedules with hard caps, not on agents reasoning about when to fire. They are deterministic by design. When something does need judgment, a human is in the loop by default and removed only after the path is battle-tested — not before.

---

## The rule that survives the hype: vending machine vs slot machine

The single most useful framing I've seen for this cuts straight through the noise. Think of every task as a choice between a vending machine and a slot machine.

A **vending machine** is deterministic. Same input, same output, every time. You put in a quarter, press E4, you get a Coke. A simple `if this, then that` workflow — pull last week's revenue, post it to a channel — is a vending machine. Cheap, predictable, it basically never breaks, and it uses no AI at all.

A **slot machine** is not deterministic. You pull the lever and something different comes out each time. That is an AI agent. Powerful when the input is messy and the task genuinely needs reasoning — reading unstructured emails and drafting tailored replies — but it costs more, it fails in stranger ways, and every pull is, in a small way, a gamble.

```
┌────────────────────────────────────────────────┐
│  VENDING MACHINE  (workflow, no AI)             │
│  deterministic · cheap · never breaks           │
│  → fixed triggers, structured data, if/then     │
├────────────────────────────────────────────────┤
│  SLOT MACHINE  (AI agent / loop)                │
│  non-deterministic · costly · fails oddly       │
│  → messy input, real reasoning, generation      │
└────────────────────────────────────────────────┘
```

The skill the hype cycle won't sell you is knowing which one a task actually needs. In a world where everyone is shouting *AI, AI, AI*, the person who can step back and say "we don't need an agent here — a ten-line script does this cheaper, faster, and with less risk" stands out far more than the one cramming an agent into every task. That take signals you understand the problem, not just the trend.

---

## So: should you run loops?

Yes — with the discipline the cheerleaders skip. Read the articles, adapt the patterns, let your agents run overnight if they earn their keep. But put a token budget on them the way you'd put a permission boundary on a service account. Instrument the spend before you scale it. And keep the one line that doesn't bend:

**Let the agent in the loop execute decisions. Don't let it make them.** Judgment doesn't delegate. The engineers running thirty agents on someone else's token budget can afford to crash the loaner car as many times as they like — it isn't theirs. Yours is. Drive it that way.

---

## Get the Production-Ready Framework

If you're putting autonomous agents into real workflows, the boundary work is the job. My kit covers it: threat model templates, 12 incident response playbooks for AI agent failures, SOC 2 and ISO 27001 compliance mapping, and a security posture scoring rubric.

**[AI Agent Defense Kit](https://javiermoralesecurity.gumroad.com/l/ai-defense-kit)** — $49

---

*For a deeper treatment of defense architectures for autonomous AI systems — least privilege, blast-radius control, runtime enforcement, and continuous monitoring — see my book [Securing Autonomous AI](/books/).*
