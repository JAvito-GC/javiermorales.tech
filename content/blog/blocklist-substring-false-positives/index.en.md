---
title: "Your Blocklist Is Matching Inside Words"
date: 2026-09-09
description: "A three-letter denylist term that filters scooters quietly deleted every legitimate listing mentioning a 'reinforced' part — because it matched as a substring, inside a word. Why exclusion filters fail silently, and the one-character fix detection engineers keep forgetting."
summary: "I lost real data for weeks to a three-letter blocklist term matching inside an innocent word. Exclusion filters don't error when they're wrong — they quietly remove things, and 'zero results' looks identical to 'no such data.' A story about substring matching, word boundaries, and why the most dangerous filter is the one you never see fire."
translationKey: "blocklist-substring"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "detection-engineering", "data-quality", "false-positives", "regex"]
---

Picture a bouncer with a list of banned names. The list says "Rob." So he turns away Rob — and also Robert, Robin, and the woman whose tag reads "Problem Solver." He is, technically, doing his job. He was told to block "Rob," and every one of those names *contains* "Rob." The list never said *whole names only*, so he never assumed it.

Most blocklists are that bouncer.

---

## The three letters that deleted my data

I run a side project that scrapes classified listings and files each one into a category. Somewhere in the pipeline sits an exclusion filter: a list of keywords that mean "this isn't the kind of vehicle we want." Scooters, for instance. One entry on that list was `forza` — Honda makes a scooter called the Forza, and I didn't want scooters.

For weeks, a category I *knew* had inventory showed almost nothing. No error. No crash. No red anything. The scraper ran, the pipeline was green, the database answered every query in milliseconds. It just quietly held a fraction of the listings it should have.

The filter was matching `forza` as a substring. And the Spanish word for "reinforced" is *reforzado* — re‑**forza**‑do. Every listing that proudly mentioned a *reinforced* subframe, a *reinforced* brake lever, a *reinforced* anything, carried the letters f‑o‑r‑z‑a in the belly of an innocent word. The bouncer turned them all away. Real, common, desirable listings, deleted at the door because their descriptions bragged about a reinforced part.

The fix was one concept: word boundaries. `\bforza\b` instead of `forza`. Match the word, not the letters. It's the kind of change that takes thirty seconds — after it has cost you three weeks of missing data.

---

## Why you never saw it fire

Here is the part that should bother you, because it isn't really about a scraper.

An exclusion filter fails in the one direction you can't see. When it *includes* something wrong, you can find the bad row — it's sitting in your table, visible and auditable. When it *excludes* something wrong, there is nothing to find. The evidence is the absence of evidence. "Zero results" and "correctly filtered everything" produce the exact same output: nothing.

So the failure is silent by construction. No exception fires — the filter did precisely what you wrote; it just *meant* something you didn't. No count looks wrong — you don't have a baseline for how many should have been there. The only symptom is a number slightly lower than your gut expected, and gut feelings don't page anyone.

A crash is loud. A wrong number is quiet. A *missing* number is silent. Systems don't die in the red; they die in the green, holding a database that is confidently incomplete.

If you've read *Your Health Check Is Lying to You*, this is its mirror image: there, a filter let the wrong thing **in** and served it under a green light; here, a filter keeps the right thing **out**. Same silence, opposite direction.

---

## Detection engineers do this constantly

If you write detection rules, you already felt the flinch, because this is a Tuesday in the SOC.

- You blocklist a malicious binary named `psexec`. Your `contains` match also suppresses `psexecsvc` telemetry you needed — and anything a vendor helpfully shipped as `mypsexec_wrapper`.
- You allowlist `corp.com` to cut noise. Your substring match now also trusts `corp.com.evil.ru` and `notcorp.com`.
- You filter out a chatty hostname, `scan01`. It quietly eats `scan01`, `scan012`, `descan01-legacy`, and the one host that mattered.

Every one of these is the Forza bug wearing a security badge: a matching primitive operating on *substrings* when you meant *tokens*. And in detection the direction of the failure is worse. My scraper dropping listings costs me data. Your SIEM filter dropping events costs you the alert you were hired to catch. The rule reads "healthy." Events per second look normal. Coverage is quietly gone, and the dashboard has no opinion about it.

---

## The habits that catch it

Three cheap ones, in order of value.

**Anchor your matches.** Word boundaries, full-token equality, `startswith`/`endswith` when you actually mean the start or the end. Naked `in` and `contains` are almost never what you mean on human text. If your library lets you match a list of *tokens* instead of a blob of characters, do that.

**Instrument your exclusions.** This is the one nobody does. Every filter that removes things should count what it removed, and occasionally sample it. A denylist that suddenly drops 40% where it used to drop 4% is trying to tell you something — and the only way to hear it is to have been counting all along. Silent filters shouldn't exist. Make them log.

**Test the filter against what it must *keep*.** Everyone tests that the blocklist blocks the bad thing. Almost nobody writes the inverse test: a fixture of legitimate, must-survive inputs that the filter runs over and must pass untouched. That single file — *"these are real and must never be excluded"* — would have caught `forza` versus *reforzado* on the first run, in the time it takes to save it.

---

## The uncomfortable summary

Availability monitoring answers *is it up?* Correctness answers *is the answer right?* Exclusion filters open a third question, sneakier than both: *is what's missing supposed to be missing?* — and almost nothing you own is watching it.

The most dangerous filter in your system is not the one throwing errors. It's the one quietly, confidently, correctly-according-to-its-own-code removing things you needed, and calling it a clean run.

Three letters. Inside a word. For three weeks.

Anchor your matches. Count what you drop. And write the test that proves the good stuff survives.
