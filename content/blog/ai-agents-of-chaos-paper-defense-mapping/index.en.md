---
title: "I Already Built Defenses Against Every Attack in the 'AI Agents of Chaos' Paper"
date: 2026-05-26
description: "38 researchers from MIT, Stanford, and Harvard published findings on real AI agent attacks. I mapped each failure mode to a defense control I already had in production."
summary: "A new research paper documents 11 failure modes in live AI agents: identity spoofing, memory wipes, malicious file propagation, and false task completion. I built defenses against all of them months ago. Here is the mapping."
translationKey: "ai-agents-chaos-defense"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai", "research", "claude-code", "open-source"]
---

38 researchers from MIT, Stanford, Harvard, Carnegie Mellon, and Northeastern spent two weeks attacking live AI agents with real accounts and real tools. They published their findings in a paper called *AI Agents of Chaos*.

The agents failed in 11 documented ways. Identity spoofing. Memory wipes. Cascading disinformation. Irreversible destructive actions. False completion reports.

I read the paper and realized something: I had already built defenses against every single attack vector they documented. Not as a research project -- as production infrastructure I use daily.

This post maps each failure from the paper to a specific control in my defense system.

---

## The Paper: What They Found

The researchers tested [Archon](https://github.com/archon-ai), an open-source framework connecting LLMs to email, Discord, file storage, and shell access. Each agent had one owner, but anyone on a public channel could message it.

Key findings:

1. **An agent deleted an entire email server** to "keep a password secret"
2. **Identity spoofing via DMs** -- a researcher changed their display name, opened a private chat, and the agent obeyed commands from the impersonator
3. **Memory wipes on demand** -- the fake identity told the agent to delete all saved files, and it complied
4. **Malicious file propagation** -- one compromised agent shared a poisoned file with another agent, which then followed the embedded instructions
5. **Mutual reinforcement** -- two agents confirmed each other's wrong information, creating false confidence
6. **False task completion** -- agents reported "task completed successfully" while underlying systems were destroyed

The paper concludes: *"Responsibility in agentic systems is neither clearly attributable nor enforceable under current designs."*

I disagree. It is enforceable. You just have to build the enforcement layer.

---

## The Defense Mapping

My system runs as a set of shell hooks around Claude Code. Every tool call -- before and after execution -- passes through validation. Here is how each paper attack maps to a specific defense.

### Attack 1: Irreversible Destructive Actions

**Paper scenario:** Agent "Ash" deleted the entire email server to accomplish a goal. It chose the most extreme option available without considering consequences.

**Defense: Pre-Tool Enforcer** (`pre-tool-enforcer.sh`)

Every Bash command is intercepted before execution. Destructive patterns are blocked at the gate:

```bash
# Destructive operations -- blocked before execution
if echo "$COMMAND" | grep -qiE \
    'rm\s+-rf\s+/(\s|$)|rm\s+-rf\s+\*|sudo\s+rm\s+-rf'; then
    BLOCKED=true
    REASON="Destructive command blocked"
fi
```

The agent cannot execute `rm -rf`, cannot drop databases, cannot kill critical processes. This is not a suggestion to the model -- it is a hard block at the shell level. The command never runs.

**Additional guard:** The hook also blocks bypass attempts via backslash escaping (`\rm -rf`), which is a known evasion technique.

---

### Attack 2: Identity Spoofing in Private Channels

**Paper scenario:** A researcher changed their Discord display name to match the agent's owner. In the public channel, the agent caught the mismatch (Discord keeps hidden IDs). But in a new private chat, the agent had no memory -- it saw the name "Chris" and obeyed.

**Defense: Subagent Guard** (`subagent-guard.sh`)

When a subagent is spawned, its prompt is intercepted and scanned for manipulation patterns:

```bash
# Block credential extraction attempts from any source
if echo "$PROMPT" | grep -qiE \
    '(print|show|reveal|list|output|display).*\b(token|secret|credential|password|api.key)\b|\
    (extract|dump|exfil|steal|leak).*\b(token|secret|credential|password|key|creds)\b'; then
    BLOCKED=true
    REASON="Subagent prompt attempts credential extraction"
fi
```

The defense model is different from the paper's trust model. The paper assumes: *if the name matches, trust it*. My system assumes: *no prompt is trusted, regardless of source*. Every instruction is validated against a deny-list of dangerous patterns before execution.

**Key principle:** Identity is not a display name. Identity is verified by what the instruction asks to do, not who claims to send it.

---

### Attack 3: Memory Wipe / File Deletion on Command

**Paper scenario:** The impersonator told the agent to delete all its saved files, memory, and settings. The agent complied because it had no mechanism to protect its own state.

**Defense: Protected File Writes** (`pre-tool-enforcer.sh`)

Critical system files cannot be modified, moved, or overwritten -- not by the agent, not by subagents, not by instructions embedded in external content:

```bash
# Defense file tampering (cp/mv/ln)
if echo "$COMMAND" | grep -qiE \
    '(cp|mv|ln)\s+.*\.claude/(hooks|settings\.json|mcp\.json)|\
    (cp|mv|ln)\s+.*guardrails/(enforcer\.py|rules\.json|sanitize\.py)'; then
    BLOCKED=true
    REASON="Defense file tampering blocked"
fi

# Protected files via bash redirect (>, >>, tee)
if echo "$COMMAND" | grep -qiE \
    '>{1,2}\s*~/Klaudio/\.claude/hooks/|\
    >{1,2}\s*~/Klaudio/guardrails/rules\.json|\
    >{1,2}\s*~/Klaudio/CLAUDE\.md'; then
    BLOCKED=true
    REASON="Write to protected file blocked"
fi
```

The agent cannot delete its own defense files. It cannot overwrite its configuration. It cannot "comply" with an instruction to wipe its state because the enforcement layer sits *outside* the model's control.

---

### Attack 4: Malicious File Propagation Between Agents

**Paper scenario:** A researcher slipped fake instructions into a shared file on GitHub. One agent followed the instructions, then shared the file with a second agent, which also followed them. One bad file infected two agents.

**Defense: Prompt Injection Scanner** (`sanitize.py`)

Every piece of external content -- scraped web pages, YouTube transcripts, API responses, shared files -- passes through a 23-pattern injection scanner with Unicode normalization:

```python
_INJECTION_PATTERNS = [
    # Instruction override attempts
    (re.compile(
        r"(?:IGNORE|DISREGARD|FORGET)\s+(?:ALL\s+)?(?:PREVIOUS|ABOVE)\s+"
        r"(?:INSTRUCTIONS|PROMPTS|CONTEXT)", re.IGNORECASE,
    ), "ignore_instructions"),

    # Tool/function call injection
    (re.compile(
        r"(?:call|execute|run|invoke)\s+(?:tool|function|mcp)",
        re.IGNORECASE,
    ), "tool_call_injection"),

    # Hidden instructions in HTML comments
    (re.compile(
        r"<!--.*(?:ignore|override|system|instruction).*-->",
        re.IGNORECASE | re.DOTALL,
    ), "html_comment_injection"),

    # Task injection (URGENT: delete X)
    (re.compile(
        r"(?:TODO|TASK|ACTION\s+REQUIRED|URGENT)\s*:.*"
        r"(?:delete|remove|send|post|push|execute|run)",
        re.IGNORECASE,
    ), "task_injection"),
]
```

**Critical detail:** The scanner applies NFKC Unicode normalization *before* pattern matching. This defeats homoglyph attacks where an attacker replaces ASCII characters with visually identical Unicode characters to bypass regex.

```python
def _normalize_text(text: str) -> str:
    normalized = unicodedata.normalize("NFKC", text)
    # Strip zero-width characters (U+200B-U+200F, U+2060-U+206F)
    normalized = re.sub(
        r"[​-‏ - ⁠-⁯﻿]", "", normalized
    )
    return normalized
```

If a shared file contains "IGNORE PREVIOUS INSTRUCTIONS" -- whether in plain ASCII, Unicode homoglyphs, or zero-width obfuscation -- the scanner detects it, logs it, and flags the content as untrusted.

---

### Attack 5: False Task Completion Reports

**Paper scenario:** Agents reported "task completed successfully" even when the underlying system was destroyed. The paper notes: *"agents often reported task completion, even though the underlying system state contradicted those reports."*

**Defense: Integrity Verification** (`integrity-check.sh`)

On every session start, the system computes SHA256 checksums of all defense files and compares them against a known-good baseline:

```bash
while IFS= read -r line; do
    expected_hash=$(echo "$line" | awk '{print $1}')
    file_path=$(echo "$line" | awk '{print $2}')

    current_hash=$(shasum -a 256 "$file_path" | awk '{print $1}')
    if [ "$current_hash" != "$expected_hash" ]; then
        FAILURES="${FAILURES}  MODIFIED: ${file_path}\n"
    fi
done < "$CHECKSUM_FILE"
```

If any defense file has been modified -- even if the agent reports everything is fine -- the integrity check fires an alert. The system does not trust agent self-reports. It verifies independently.

**Additional layer: Post-tool audit logging** records every sensitive operation to JSONL, creating an immutable trail that can be reviewed regardless of what the agent *claims* happened.

---

### Attack 6: Credential Exposure via Compliant Agent

**Paper scenario:** The paper documents agents sharing private files, exposing documents, and executing data access without proper authorization.

**Defense: Credential Pattern Detection** (pre-tool + post-tool, both layers)

Both before and after tool execution, content is scanned for credential patterns:

```bash
# Post-tool: outbound credential leak detection
if echo "$WRITE_CONTENT" | grep -qiE \
    'shpat_[a-zA-Z0-9]{10,}|sk-[a-zA-Z0-9]{20,}|\
    ghp_[a-zA-Z0-9]{36}|AKIA[A-Z0-9]{16}|\
    Bearer\s+[a-zA-Z0-9._-]{20,}|re_[a-zA-Z0-9]{20,}'; then
    echo "[SECURITY] CREDENTIAL LEAK DETECTED in $TOOL_NAME output!"
fi
```

This covers 12 credential formats: Shopify tokens, OpenAI keys, GitHub PATs, AWS access keys, Bearer tokens, Resend keys, Cloudflare tokens, Hetzner tokens, Slack tokens, SendGrid keys, and webhook secrets.

**Pre-tool guard** blocks commands that *read* credential files. **Post-tool guard** catches credentials that appear in *output*. Two independent layers.

---

## The Architecture Principle

The paper identifies a fundamental design flaw: agents in the study had no enforcement layer between intention and execution. The model decided, and the action happened.

My system inserts enforcement at three points:

```
┌─────────────────────────────────────────────────┐
│  Model decides to act                           │
├─────────────────────────────────────────────────┤
│  ① PRE-TOOL: Block before execution             │
│     - Destructive commands                      │
│     - Protected file writes                     │
│     - Credential reads                          │
│     - Corporate crossover                       │
├─────────────────────────────────────────────────┤
│  Tool executes (if allowed)                     │
├─────────────────────────────────────────────────┤
│  ② POST-TOOL: Validate after execution          │
│     - Prompt injection in results               │
│     - Credential leaks in output                │
│     - Supply chain alerts (npm)                 │
│     - Audit trail (JSONL)                       │
├─────────────────────────────────────────────────┤
│  ③ SESSION: Verify system state                 │
│     - SHA256 integrity baseline                 │
│     - Defense file modification alerts          │
│     - Subagent prompt validation                │
└─────────────────────────────────────────────────┘
```

The model does not control the enforcement layer. The enforcement layer controls the model.

---

## What the Paper Gets Right

The researchers make an important observation: *"When agents interact with each other, individual failures compound and qualitatively new failure modes emerge."*

This is correct. A single defense-less agent is a vulnerability. Multiple defense-less agents in communication is an amplification system for bad instructions. The paper found that one poisoned file propagated to two agents -- in a production system with hundreds of agents, this becomes a worm.

The defense principle is the same as network security: **zero trust between agents**. Every message, every shared file, every instruction is untrusted input until validated.

---

## What the Paper Misses

The paper frames the problem as unsolved: *"Responsibility is neither clearly attributable nor enforceable."*

I disagree with the second part. Enforceability requires two things:

1. **A layer the model cannot modify** -- shell hooks that run *around* the agent, not inside it
2. **Independent verification** -- checksums, audit logs, and state validation that do not rely on the agent's self-report

Both exist today. They are not theoretical. They are production code. The paper tested systems without these layers. That is a valid finding about the *default* state of AI agents. It is not a finding about what is *possible*.

NIST announced an AI Agent Standards Initiative in February 2026. When those standards arrive, they will describe something very close to what is already running in my system: enforcement boundaries, immutable audit trails, and independent integrity verification.

---

## Try It Yourself

The defense system is open source: [github.com/JAvito-GC/claude-guardrails](https://github.com/JAvito-GC/claude-guardrails)

It includes pre/post-tool hooks, prompt injection detection with Unicode normalization, integrity checksums, subagent validation, and 68+ automated tests.

If you are building AI agents with shell access, tool access, or external data ingestion, you need an enforcement layer. The *AI Agents of Chaos* paper is evidence. The solution is engineering.

---

## Get the Production-Ready Framework

The open source repo gives you the code. The framework gives you everything else: threat model templates, 12 incident response playbooks for AI agent failures, SOC 2 and ISO 27001 compliance mapping, a security posture scoring rubric, and an implementation guide with architecture decisions.

**[AI Agent Defense Kit](https://javiermoralesecurity.gumroad.com/l/ai-defense-kit)** — $49

---

*For a deeper treatment of defense architectures for autonomous AI systems, including multi-agent orchestration, memory isolation, and continuous monitoring patterns, see my book [Securing Autonomous AI](/books/).*
