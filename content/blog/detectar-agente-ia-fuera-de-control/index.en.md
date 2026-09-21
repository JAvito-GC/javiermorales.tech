---
title: "How to Detect When Your AI Agent Goes Off-Script"
date: 2026-08-10
description: "Don't trust the agent to behave — instrument it. Which signals to capture, which logs matter, and which detections to write to catch prompt injection, tool abuse, and exfiltration via MCP."
summary: "The conversation about agent security has stalled at 'watch out for the lethal trifecta.' Fine — you've got it. Now how do you detect it in production? This post gets down to the detection engineering: the four signals to instrument in an autonomous agent, the log almost nobody captures, and concrete detections you can write today."
translationKey: "detecting-rogue-ai-agents"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "ai-agents", "detection-engineering", "prompt-injection", "mcp", "appsec"]
---

Almost everything written about AI agent security stops at the threat phase: the lethal trifecta, prompt injection, the agent with a shell that reads your email. Correct diagnosis, repeated to the point of boredom. But there's one question almost nobody answers, and it's the only one that matters once the agent is already in production: **how do you find out it happened?**

An autonomous agent isn't a user and it isn't a service. It's a non-deterministic actor with credentials, making decisions from text you don't control and executing actions with real tools. From a detection engineering standpoint that has an uncomfortable translation: you can't prevent everything it will do, so you have to **instrument it the way you'd instrument an insider with privileged access.** You don't trust it to behave. You wire it with telemetry and write detections against that telemetry.

This post is that part. Which signals to capture, which logs matter, and which concrete detections to write.

---

## The foundational mistake: treating model output as the security event

The instinct is to focus on the prompt and the LLM's response. It's the wrong place. The text the model generates doesn't hurt anyone: what hurts is the **action**. The tool call. The `GET` to a weird domain. The `read_file` on `~/.ssh/id_rsa`. The `POST` to a webhook nobody registered.

Detection rule number one, and everything else hangs off it:

> The security event isn't what the agent *says*. It's what the agent *does* with a tool.

That tells you where to put the sensors: at the tool-calling layer, not the token-generation layer. If your only telemetry is "the prompt and the response," you're watching the shadow instead of the object.

---

## The four signals to instrument

For every tool invocation —every tool call, every MCP call— capture at minimum:

1. **Tool identity and full arguments.** Tool name, originating MCP server, and the untruncated parameters. The argument is where the attack lives (`{"path": "../../etc/shadow"}`).
2. **Decision provenance.** What triggered this call? The system instruction, the user request, or **retrieved content** (a web page, an email, a RAG document)? This is the signal almost nobody captures and it's the most valuable. A tool call whose causal origin is untrusted text is your primary indicator of prompt injection.
3. **Result and size.** Exit code, bytes returned, rows read. Exfiltration shows up in volume before it shows up in content.
4. **Sequence and timing.** The order of calls and the time delta. Agents have behavioral "signatures"; a sequence deviation is a signal.

If your agent framework doesn't give you signal 2, wrap it yourself. Nothing exotic is needed: a wrapper around the tool dispatcher that annotates each call's context origin and emits a structured event. Stdlib and a JSON logger are enough. That log is your detection source; treat it the way you'd treat EDR or CloudTrail, not as a debug `print`.

Example of the minimum event you should be emitting for every tool call:

```json
{
  "ts": "2026-08-10T09:14:22Z",
  "agent_id": "triage-bot-3",
  "tool": "http_get",
  "mcp_server": "web-fetch",
  "args": {"url": "https://pastebin.example/raw/xY3"},
  "trigger_source": "retrieved_content",
  "context_ref": "email_id:44812",
  "bytes_out": 0,
  "bytes_in": 1840,
  "session_id": "s-9f2c"
}
```

With that you can write real detections.

---

## Concrete detections you can write today

Not theory. Rules.

**1. Tool call originating from untrusted content that touches a sensitive tool.**
The crown jewel. If `trigger_source` is `retrieved_content` or `tool_result` (not `user` or `system`) **and** the invoked tool is on your sensitive list (email sending, outbound HTTP, command execution, filesystem writes), alert. This pattern —"an email told me to call the payments API"— is prompt injection materializing into action. It's the highest-signal, lowest-noise detection you'll write.

**2. Tool catalog deviation.**
Every agent has a scope: a triage bot reads alerts and queries the CMDB, it doesn't run `curl`. Model the expected set of tools per agent role (an allowlist, literally) and alert when it invokes something outside it. This isn't machine learning: it's a `set` and a comparison. The agent that "discovers" a tool it never uses is your equivalent of a process that suddenly starts doing LDAP recon.

**3. Traversal and secret access in arguments.**
Regex over the arguments of filesystem tools: `..`, absolute paths to `/etc`, `.ssh`, `.env`, `credentials`, `id_rsa`. Trivial, high value. The legitimate agent works in its task directory; the one going after `~/.aws/credentials` doesn't.

**4. Exfiltration fan-out.**
Correlate by `session_id`: a large read (high `bytes_in` from a `read_file` or a query) followed in the same session by a network egress (`bytes_out` to an external destination). Data in, data out, little time between. It's the classic exfiltration signature, except the "malware" is an agent confused by a prompt.

**5. Network destinations outside the allowlist.**
Agents should talk to a known set of domains. Any `http_get`/`http_post` to a destination outside the allowlist is an alert, especially if signal 1 also applies. Pastebins, ephemeral webhooks, raw IPs: high priority.

**6. Loop or anomalous repetition.**
An agent calling the same tool N times with arguments that vary by increments is usually doing enumeration or brute force —or simply stuck, burning your bill. Both deserve an event.

---

## The detail that makes it real: correlate by session, not by event

None of these signals in isolation gives you the picture. Prompt injection isn't an event, it's a **causal chain**: untrusted content comes in → the model treats it as an instruction → it invokes a sensitive tool → it exfiltrates. If your telemetry doesn't carry a `session_id` and a `context_ref` that let you reconstruct that chain, you have loose events and no story. The difference between an actionable alert and a lake of noise is exactly that correlation capability. It's the same as in a traditional SOC: the value is in the link, not in the isolated log line.

---

## Where this fits

An autonomous agent with tools is, in detection terms, a privileged endpoint running code on your behalf from input you don't control. Treat it that way: telemetry at the action layer, detections over provenance and scope, correlation by session. None of this requires a new product. It requires deciding that agent behavior is a first-class detection domain and not a `print` in the console.

This post takes to the ground what stayed a threat in [PewDiePie's agent email lethal trifecta](/blog/pewdiepie-odysseus-agente-email-trifecta-letal/): there the problem, here the detections. If you're building this for your own agents and want the detection kit, response playbooks, and the full threat model, I packaged it in [Blindar Agentes IA and the AI Agent Defense Kit](/books/). But with the six rules above and a decent tool-call log you already cover 80% of the real risk. Start by instrumenting the provenance signal. It's the one nobody captures and the one that'll save you most.
