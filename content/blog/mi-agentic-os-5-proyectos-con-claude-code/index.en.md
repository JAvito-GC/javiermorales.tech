---
title: "My Agentic OS: How I Run 5 Projects Solo with Claude Code"
date: 2026-05-19
description: "A real-world system where one person manages 5 businesses through codified skills, AI agent architecture, and a 6-layer defense system. No team. No VA. Just an Agentic OS."
summary: "I run 5 projects solo — no team, no VA. Here's the AI agent architecture that makes it possible: 23 skills, 6 defense layers, parallel sessions, and a single config file that orchestrates everything."
translationKey: "agentic-os"
draft: false
og_image: "/img/og-default.png"
tags: ["ai", "claude-code", "productivity", "solopreneur", "automation"]
---

I run 5 projects solo. No team. No virtual assistant. No agency. Just me and an AI agent architecture I've been building for months.

The projects: a bike price aggregator scraping 7 sources across Spain, a personal brand with a Hugo blog, a Shopify store, an Etsy template business, and a rider matching platform. Different domains, different tech stacks, different audiences.

The common thread: they all run through a single system I call my **Agentic OS**.

This isn't a course pitch. It's not a theoretical framework. It's what I actually use every day, and I'm going to show you exactly how it works.

## What Is an Agentic OS

An Agentic OS is your life and business codified into domains, skills, and automations — executed by AI agents that understand your context without being told twice.

Think of it as the operating system layer between you (the decision maker) and the execution (code, deploys, content, research). Instead of context-switching between 5 projects and remembering where you left off, the system knows. It knows the infrastructure, the security rules, the deployment targets, the current status of every project.

The key difference from "just using ChatGPT": **state persistence**. My system doesn't start from zero each session. It carries project context, enforces security boundaries, and executes multi-step workflows through codified skills.

## The 4 Layers

### Layer 1: CLAUDE.md — The Master Config

Everything starts with a single file: `CLAUDE.md`. This is the instruction set that every AI session loads on start. It contains:

- **Project map**: 5 projects with paths, status, descriptions, and tech stacks
- **Security rules**: what never gets committed, what never gets referenced, credential patterns to block
- **Infrastructure**: VPS details, DNS config, deployment targets
- **Shared tools**: MCP servers, scrapers, transcribers
- **Session protocol**: how parallel agents communicate

```
# Simplified structure of CLAUDE.md

## Projects
| Project     | Path                  | Status  |
|-------------|----------------------|---------|
| MotoRadar   | projects/enduroscout/ | PRIMARY |
| Brand       | projects/personal-brand/ | ACTIVE |
| Vulkaan     | projects/shopify/    | ACTIVE  |
| Etsy        | projects/etsy/       | ACTIVE  |
| Knubby Club | projects/knubby/     | PARKED  |

## Security - MANDATORY
1. Zero work footprint
2. Never hardcode credentials
3. Separate git identity
4. All secrets in ~/.klaudio-creds.sh

## Skills (23 codified)
/triage, /deploy, /seo-audit, /deep-research...
```

This file is the single source of truth. When I open a new session, the AI already knows which project is primary, what's parked, and what boundaries it cannot cross.

### Layer 2: Skills — 23 Codified Operations

Skills are reusable, domain-specific workflows stored as structured files. Each skill has a trigger pattern, execution steps, and output format.

Some examples from my 23 installed skills:

- `/triage` — Takes a list of URLs (YouTube videos, articles, tools), fetches content, scores each on a /25 scale, outputs structured markdown with BUILD/WATCH/SKIP verdicts
- `/deploy <target>` — Single command to deploy any project to the VPS. Handles Docker builds, nginx config, SSL, health checks
- `/seo-audit` — Crawls up to 500 pages, delegates to 15 specialist sub-agents (crawlability, Core Web Vitals, structured data, etc.), generates a health score
- `/deep-research` — Multi-source research with citation management, evidence scoring, and McKinsey-template PDF output
- `/copywriting` — Marketing copy generation using proven frameworks (PAS, AIDA, BAB) with A/B variants

The power isn't in any individual skill — it's in **composition**. I can say "triage these 12 URLs, then for anything scored BUILD, draft a content strategy" and it chains skills automatically.

### Layer 3: Defense System — 6 Layers of Automated Guards

When you give AI agents real access to your infrastructure, you need guardrails. My defense system runs on every single tool call:

```
┌─────────────────────────────────────┐
│         TOOL CALL INITIATED         │
└──────────────────┬──────────────────┘
                   │
         ┌─────────▼─────────┐
         │  PRE-TOOL HOOK    │  Blocks credentials,
         │  (enforcer.sh)    │  corporate crossover,
         │                   │  destructive operations
         └─────────┬─────────┘
                   │ PASS
         ┌─────────▼─────────┐
         │  TOOL EXECUTES    │
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  POST-TOOL HOOK   │  Audit logging,
         │  (guard.sh)       │  injection scan,
         │                   │  credential leak check
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  SUBAGENT GUARD   │  Blocks sub-agents from
         │                   │  credential extraction,
         │                   │  corporate paths
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  INTEGRITY CHECK  │  SHA256 verification
         │                   │  of defense files
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  ON-STOP HOOK     │  Uncommitted changes
         │                   │  reminder, violation log
         └─────────────────────┘
```

This isn't paranoia — it's operational hygiene. The pre-tool hook alone blocks 14 credential patterns from ever being written to a file. The post-tool hook scans every MCP server response for prompt injection attempts. The integrity check verifies that no defense file has been tampered with since the last known-good baseline.

Result: 99/100 security score on my own audit framework.

### Layer 4: Session Relay — Parallel Agent Communication

Here's where it gets interesting. I often run multiple Claude sessions simultaneously — one working on MotoRadar scrapers, another writing blog content, another doing SEO research.

The problem: these sessions are isolated. They can't see each other's work.

My solution: a lightweight message bus (`session-relay.py`) that lets sessions communicate:

```bash
# Session A (motoradar) finishes a scraper update:
python3 scripts/session-relay.py send \
  --from motoradar --to all \
  --topic action \
  --body "Updated mundimoto scraper - now pulls 265 listings with provinces"

# Session B (brand) checks on start:
python3 scripts/session-relay.py check --unread
# > [motoradar→all] action: Updated mundimoto scraper...
```

Every session checks for unread messages on start. After significant changes, sessions broadcast what they did. Topics include: `finding`, `action`, `request`, `status`, `alert`, `handoff`.

This means my "team" — which is just me running parallel AI sessions — stays coordinated without me manually context-switching between terminals.

## Real Examples

### Triaging 12 URLs in 3 Minutes

I collect YouTube videos, articles, and tools throughout the week. When I have a batch, I run `/triage`:

```
Input:  12 URLs (mix of YouTube, articles, GitHub repos)
Output: Structured markdown with:
        - Summary of each piece
        - Score /25 (relevance, actionability, quality)
        - Verdict: BUILD / WATCH / SKIP
        - Specific implementation notes for BUILD items

Time: ~3 minutes for 12 URLs
```

The skill transcribes YouTube videos via yt-dlp, fetches articles via WebFetch with VPS fallback, scores everything against my current project priorities, and outputs a decision file I can act on immediately.

Last batch: 12 URLs yielded 6 BUILD items that directly fed into new features.

### Single-Command Deployments

```bash
/deploy motoradar
```

That's it. Behind the scenes:
1. SSH into VPS
2. Pull latest code
3. Run database migrations if needed
4. Restart Docker containers
5. Verify nginx is serving
6. Health check the API endpoints
7. Report back with status

No Dockerfile debugging. No "wait, which server was that on?" No deployment runbooks to follow manually.

### Automated SEO Audits

```bash
/seo-audit motoradar.es
```

Crawls the site, identifies issues across 9 categories (crawlability, indexability, security, URL structure, mobile, Core Web Vitals, structured data, JavaScript rendering, IndexNow), generates a prioritized action list. Runs in parallel with up to 15 specialist sub-agents.

I run this monthly across both my sites. Issues get fixed in the same session.

## Intelligence Arbitrage

The thesis behind all of this: **1 person + AI architecture = team output**.

I call it intelligence arbitrage. The gap between what a solo operator can produce with proper AI infrastructure versus what most people think requires a team — that gap is the opportunity.

A traditional setup for managing 5 projects would require:
- 1-2 developers
- A content writer
- An SEO specialist
- A DevOps person (at least part-time)
- A project manager to coordinate

My setup replaces the coordination overhead entirely. The CLAUDE.md **is** the project manager. The skills **are** the specialists. The session relay **is** the stand-up meeting.

The bottleneck shifts from execution to decision-making — which is exactly where a human should be.

## Getting Started

You don't need 23 skills on day one. Start with:

1. **A CLAUDE.md file** that maps your projects and rules
2. **One skill** for your most repetitive task (deployment, content creation, research)
3. **A pre-tool hook** that blocks credential leaks

Then iterate. Every time you find yourself explaining the same context twice, codify it. Every time you run a multi-step process manually, turn it into a skill.

The system compounds. Month 1 you have 3 skills. Month 3 you have 15. By month 6, you're operating at a level that would have required a small team twelve months ago.

---

The full system is open source: [github.com/JAvito-GC/klaudio](https://github.com/JAvito-GC/klaudio)

If you're building something similar, I'd like to hear about it. Find me on [LinkedIn](https://www.linkedin.com/in/javiermoralesgc/) or through [javiermorales.tech](https://javiermorales.tech).
