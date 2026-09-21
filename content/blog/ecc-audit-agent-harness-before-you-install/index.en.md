---
title: "264,000 People Are About to Install an AI Agent Harness. Run This 5-Minute Audit First."
date: 2026-09-21
description: "ECC hit 264k GitHub stars and does supply-chain security better than most. That is exactly why you should audit it before installing. A reusable checklist for any agent harness."
summary: "Everything Claude Code crossed 264k stars and is genuinely well built. That popularity is the point: popular is not the same as audited by you. The 5-minute audit I run against any agent harness before I trust it."
translationKey: "ecc-audit-harness"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "agent-security", "supply-chain", "claude-code", "ai-security"]
---

Everything Claude Code (ECC) crossed 264,000 GitHub stars this week. I checked the number against the GitHub API, not the page render: 264,265 stars, 39,504 forks, in eight months. It is, by that metric, one of the most popular developer projects on the platform.

It is also genuinely good. I read the installer and the security policy before writing a word, and ECC does the hard parts right. So this is not a takedown. It is the opposite: ECC is the best-case example I could find to make a point that applies to every agent harness you will ever install, including the good ones.

The point is simple. Popular is not the same as audited by you. And an agent harness is not a library. It is 68 subagents, 292 skills, hooks that run outside the model's context, and an installer that hands off to code you did not read. When you install it, you are not adding a dependency. You are handing an autonomous system a standing invitation to run commands on your machine, with your keys, on every turn.

That is a trust decision. Most people are about to make it because a number went up.

## Credit where it is due

Before the audit, the fair part. ECC does not do the naive, dangerous things:

- The installer runs `npm install --ignore-scripts`, which deliberately blocks the preinstall and postinstall remote-code-execution path that has burned so many npm users.
- It does not pipe a remote script into a shell. No `sudo`. It does not rewrite your shell profile.
- Its SECURITY.md treats supply-chain exposure as a first-class surface, with coordinated disclosure and real response timelines. It even models the harness input channel itself as an attack surface, distinguishing harness-injected system reminders from repository-carried injection.

That is more security maturity than most projects with a fraction of the attention. If you are going to install a harness, this is close to the responsible end of the spectrum.

And it still does not get you off the hook.

## The 5-minute audit

Run this against ECC, against my own tooling, against anything you install that acts on your behalf. It is not about trusting the author. It is about knowing what you accepted.

**1. Read the installer end to end.** Not the README, the installer. Does it fetch a remote script and run it? Does it escalate to root? Does it touch `.bashrc`, `.zshrc`, or your PATH? ECC passes these. But note what it does next: it delegates the real work to a Node installer script the wrapper does not show. An installer that does the visible part safely and then runs code you did not open is still asking for trust you have not verified.

**2. Enumerate the hooks.** Hooks are the part that matters most and that people read least. They run outside the model's context, which means they execute on your machine on tool events whether or not the model decided anything. List every hook. Read every hook. A hook is arbitrary code with your permissions, triggered by events you do not fully control.

**3. Measure the always-loaded surface.** Separate what loads on demand from what loads every turn. 292 skills is not 292 features, it is 292 files you are implicitly trusting and will never personally read. Trust by volume is not trust. It is surrender with extra steps.

**4. Map the egress.** What talks to the network? Which MCP servers, which endpoints, which telemetry? Every outbound path is a potential exfiltration path for the secrets and source the agent can see. If you cannot list them, you cannot defend them.

**5. Pin the version.** Popularity makes a project a bigger target, not a safer one. 264k stars is 264k reasons for someone to try to poison a release. Pin the commit SHA. Re-audit on upgrade.

## The one thing you cannot delegate

ECC ships AgentShield, a scanner for exactly this class of problem. Good scanners help. But no scanner, theirs or mine, closes the last gap, because the last gap is not technical. It is the code you personally did not read and the surface too large for you to read at all.

A security-conscious harness can hand you a safer default. It cannot make the trust decision on your behalf. When you install 292 skills, you are trusting that all 292 are what they claim, forever, across every update, and you are doing it on the strength of a star count. That residual risk does not disappear because the author is careful. It transfers to you the moment you type the install command.

That is the real lesson, and it outlives ECC. The next harness will have more stars.

## Audit before you trust

I built the [Agent Audit Kit](https://github.com/JAvito-GC/agent-audit-kit) for exactly this: an open-source, MIT-licensed tool that runs this kind of checklist against an agent or MCP setup, flags the code that runs outside the model, and tells you what you are actually accepting. It runs locally. Nothing leaves your machine.

Hype is a great reason to go look. It is never a reason to trust. Go install ECC if it earns its place in your workflow. Just run the five minutes first.
