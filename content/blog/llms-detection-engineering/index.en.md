---
title: "LLMs in Detection Engineering: Where They Accelerate and Where They Lie"
date: 2026-08-10
description: "A real workflow for using LLMs in detection engineering —triage, rule generation, and refinement— without degrading quality. Including the uncomfortable part: where the model lies and how to verify it."
summary: "How a solo engineer uses LLMs to accelerate detection engineering without lowering the bar: what to delegate, what not to, and how to verify every output before it touches production."
translationKey: "llms-detection-engineering-donde-aceleran"
og_image: "/img/og-default.png"
draft: false
tags: ["Detection Engineering", "LLM", "AI-Driven Security Operations", "SIEM", "Security"]
---

There are two ways to get LLMs wrong in detection engineering. The first is not using them: still hand-writing every rule while the backlog grows faster than you can ship. The second is worse: letting the model write detections and trusting them because they "compile" and "sound right."

I've spent months using LLMs daily in a real detection workflow, as a solo engineer. The thesis is simple: **one person with a well-governed LLM performs like a small team.** But only if you treat the model as a fast, confident intern, not as an expert. This post is the concrete manual: what I delegate, what I don't, and how I verify every output before it touches production.

## Where the LLM genuinely accelerates

**First-pass triage.** The most expensive work of a detection engineer isn't writing rules, it's reading alerts. An LLM with enough context —the raw event, the runbook, the asset's history— summarizes an alert and proposes hypotheses in seconds. It doesn't decide. It orders. I go from "50 alerts without context" to "50 alerts with a two-line summary and a hypothesis ranked by probability." Time to the first human decision collapses.

**Translation between detection dialects.** I have logic in Sigma and need it in the SIEM's DSL. Or the other way around. The LLM does 80% of the mechanical syntax-translation work. What used to be 20 minutes of digging through docs is now two minutes of review.

**The first draft of a rule.** I describe the behavior —"access to Secrets Manager from a new IP followed by exfiltration to an external bucket in under five minutes"— and it hands me back a skeleton: fields, time window, correlation conditions. It's never the final version. But starting from a structured draft instead of a blank page changes the rhythm of the day.

**Generating negative test cases.** Here the LLM shines counterintuitively: it's excellent at inventing the benign traffic that will trip a badly written rule. "Give me ten legitimate patterns that would fire this detection." Half are noise; the other half are false positives I hadn't considered. That's worth gold.

## Where trusting it is dangerous

**Thresholds and baselines.** The LLM doesn't know your environment. When you ask for "a reasonable threshold of failed login attempts," it invents a number that sounds sensible —"five in ten minutes"— with no basis in your actual telemetry. That number is a hallucination formatted as data. Thresholds come from your percentiles, not from the statistical intuition of a model trained on the internet.

**Field names and log semantics.** Models fill gaps with confidence. They'll invent a `sourceIPAddress` field that in your real schema is called `src_ip`, or assume a field exists in a log where it doesn't. The rule looks correct, passes the linter, and never fires in production. This is the most expensive silent failure: **a detection that exists on paper and not in reality.**

**Coverage and the feeling of completeness.** If you ask "does this cover technique X?", the LLM tends to say yes. It's obliging by design. Mistaking its confidence for real threat coverage is how you end up with an ATT&CK map full of green boxes and an adversary strolling through the gaps.

**Temporal correlation logic.** The moment the detection involves sequence and windows —"A, then B, but not C in between, within N minutes"— the rate of subtle errors spikes. Misplaced window operators, overlapping conditions, an `AND` where an `OR` belonged. It compiles. It's wrong.

## The workflow I use: the LLM proposes, the telemetry disposes

The golden rule: **the LLM generates, the data verifies, the human signs.** No artifact reaches production without crossing all three gates.

1. **Generate with context, not blind.** I give it the real schema of my logs, a couple of existing rules for style, and the runbook. Too much context, not too little. An LLM without your schema is a plausibility generator.

2. **Verify against real data, always.** Every candidate rule runs first in *dry-run* mode against 30-90 days of historical telemetry before it's armed. If the LLM says "this will catch the threat with almost no false positives" and the history returns 400 hits a day, the model was lying. The data isn't. This step connects directly to the [detection-as-code program that cut my false positives by 60%](/blog/detection-as-code-60-menos-falsos-positivos/): without testing against data, the LLM's speed only accelerates the generation of noise.

3. **Review the diff, not the explanation.** I read the logic it wrote, not the paragraph it uses to justify it. The model's prose is always convincing; the logic is what runs. I check field names, temporal operators, and thresholds especially —the three hotspots for hallucination.

4. **Version and attribute.** Every rule generated or modified by an LLM is tagged in version control. If three months from now a detection behaves strangely, I want to know whether it was born from a human or from a model draft that was never reviewed properly.

## The uncomfortable part

The LLM doesn't make you a better detection engineer. It makes you *faster* at what you already know how to evaluate. If you can't read a rule and smell that the threshold is invented or the field doesn't exist, the model only accelerates your mistakes and hands you a false sense of coverage. Productivity doesn't come from delegating judgment —it comes from delegating the mechanics and keeping the judgment.

Intelligence arbitrage is real: one person with this workflow closes in an afternoon what used to be a week. But the multiplier applies to your judgment, it doesn't replace it. Multiply by zero and you stay at zero, faster.

Start small. An LLM for first-pass triage and syntax translation, with mandatory verification against data, is a safe win today. Delegating the judgment of what to detect and at what threshold never will be.
