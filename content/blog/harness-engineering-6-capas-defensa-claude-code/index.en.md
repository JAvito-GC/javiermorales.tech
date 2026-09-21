---
title: "Harness Engineering: 6 Defense Layers I Built Around Claude Code"
date: 2026-05-12
description: "Harness Engineering is the discipline of building everything around an AI model. I built a 6-layer defense system for Claude Code agents — hooks, guards, integrity checks — scoring 99/100 in security. Here is the architecture."
summary: "The model is not the product. The harness is. I share the 6-layer defense system I built around Claude Code to manage 5 projects with zero credential leaks."
translationKey: "harness-engineering"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai", "claude-code", "harness-engineering", "devtools"]
---

In April 2026, Andrej Karpathy gave a talk at Sequoia where he introduced a concept that resonated with everyone building AI systems in production: **the harness is more important than the model**.

His formula is simple:

```
Agent = Model + Harness
```

The model is a commodity. GPT-4, Claude, Gemini -- they all converge. What differentiates a useful agent from a dangerous one is the **harness**: the constraints, sensors, feedback loops, and infrastructure that wrap the model and turn raw capability into controlled behavior.

I have been building exactly this for the past six months. Not in theory -- in a production system that manages 5 projects, runs scrapers, deploys code, and handles credentials. The system scores 99/100 on security audits with zero credential leaks across thousands of agent interactions.

This is the architecture.

---

## What Is Harness Engineering

Harness Engineering is the discipline of building everything that is NOT the model but makes the model useful, safe, and controllable. It includes:

- How you constrain the agent's behavior
- How you detect when things go wrong
- How you feed context back into the system
- How you isolate execution environments
- How you encode expertise into reusable patterns

The model picks the next token. The harness decides what the model can see, touch, and break.

---

## Pattern 1: Constraints (The Reactive Config)

Every production system has a config file. In Claude Code, that is `CLAUDE.md`. But here is the key insight: **every line should come from a real incident**.

My `CLAUDE.md` is not a wishlist. It is a scar tissue document. Each rule exists because the agent violated it at least once:

```markdown
# Security - MANDATORY
1. Zero work footprint. Never reference employer names or work directories.
2. Never hardcode credentials. All secrets in ~/.klaudio-creds.sh
3. Never commit secrets. Pre-commit hook rejects credential patterns.
4. Separate git identity. Verify git config user.email before every commit.
5. No work MCP servers. This project uses its own MCP config.
```

This is not documentation. It is a constraint layer. The agent reads it on every session start and treats it as law. When a new failure mode appears, you add one line. The config grows reactively, encoding operational memory.

---

## Pattern 2: Sensors (Pre/Post Hooks)

Constraints alone are not enough. LLMs are probabilistic -- they will violate rules. You need sensors that detect violations in real time.

I implemented two hook layers:

**Pre-tool hook** -- runs before every tool call:
```bash
# Block credential patterns in file writes
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
    SCAN_MSG=$(echo "$INPUT_JSON" | python3 "$KLAUDIO_DIR/guardrails/scan_content.py")
    if [ "$SCAN_RC" -eq 2 ]; then
        echo "BLOCKED: Credential in Write/Edit content" >&2
        exit 2
    fi
fi
```

**Post-tool hook** -- runs after every tool call:
```bash
# Prompt injection scanning on external content
if echo "$TOOL_NAME" | grep -qiE 'mcp__|firecrawl|youtube'; then
    echo "$RESULT_TEXT" | python3 "$SANITIZE" --mode scan
fi
```

The pre-hook prevents the agent from writing credentials to files or executing dangerous commands. The post-hook scans all external content (web scrapes, transcripts, MCP tool results) for prompt injection patterns before the agent processes them.

---

## Pattern 3: Codified Skills

A general-purpose LLM is a generalist. To make it an expert, you encode domain knowledge into structured skill files.

I have 23 skills installed. Each one is a markdown file with:
- Trigger conditions (when to activate)
- Step-by-step methodology
- Reference material
- Evaluation criteria

The agent does not reinvent SEO auditing every time. It loads the skill, follows the procedure, and produces consistent output. Skills are the difference between "AI assistant" and "AI specialist."

---

## Pattern 4: Feedback Loops

An agent without feedback degrades. It drifts from constraints, accumulates errors, and loses context. You need mechanisms that close the loop.

**Integrity checks** -- SHA256 verification of defense files on session start:
```bash
while IFS= read -r line; do
    expected_hash=$(echo "$line" | awk '{print $1}')
    file_path=$(echo "$line" | awk '{print $2}')
    actual_hash=$(shasum -a 256 "$file_path" | awk '{print $1}')
    if [ "$expected_hash" != "$actual_hash" ]; then
        FAILURES="${FAILURES}  TAMPERED: ${file_path}\n"
    fi
done < "$CHECKSUM_FILE"
```

**On-stop hooks** -- remind the agent of uncommitted work and log violations:
```bash
if [ -n "$(git status --porcelain)" ]; then
    echo "Uncommitted changes in Klaudio. Commit if work is complete."
fi
```

**Session relay** -- a message bus between parallel agent sessions. When one agent discovers something, others learn about it in their next session.

---

## Pattern 5: Infrastructure Isolation

The model runs locally. But execution happens elsewhere.

My rule is absolute: **no code execution on the development machine**. All scrapers, Docker containers, and deployments run on a VPS. The local machine is code-only. This means a compromised agent cannot access local credentials, SSH keys, or work infrastructure.

```markdown
# From CLAUDE.md
- Code only on MacBook. All execution on VPS. Never run project code locally.
```

This is defense in depth. Even if the agent bypasses every hook, it cannot reach production data from the development environment.

---

## Pattern 6: Discovery Files (Agent Cards)

When you run multiple agents across multiple projects, they need to discover each other's capabilities. I use:

- `AGENTS.md` files that describe what each agent does
- MCP config (`.claude/mcp.json`) for tool discovery
- Agent cards in `.agents/` with role definitions and boundaries

This is the service mesh equivalent for AI agents. Without it, agents duplicate work, conflict, or miss available tools.

---

## Results

Six months of harness engineering, measured:

- **99/100 security audit score** (custom 8-check audit script)
- **Zero credential leaks** across thousands of interactions
- **5 projects managed** by one person with AI agents
- **6 defense layers** that operate independently (defense in depth)
- **3,000+ active listings** scraped and maintained without manual intervention

The model did not produce these results. The harness did.

---

## The Takeaway

If you are building with AI agents, stop optimizing prompts and start engineering your harness. The model is a commodity. Your competitive advantage is the system around it.

The full defense system is open source: [github.com/JAvito-GC/claude-guardrails](https://github.com/JAvito-GC/claude-guardrails)

Build your own. Every system needs a different harness. But the patterns -- constraints, sensors, skills, feedback loops, isolation, discovery -- are universal.
