---
title: "A Month Ago I Wrote That Health Checks Lie. This Week Mine Lied to Me"
date: 2026-07-27
description: "I wrote that a green dashboard doesn't prove a system is doing its job. Then I found two of my own agents had been failing silently for weeks, and neither warned me. A post-mortem on fail-open, fail-closed, and why preaching something doesn't vaccinate you against it."
summary: "In «Your Health Check Is Lying to You» I argued that availability and correctness are different questions. A month later I had to eat my words: two of my agents degraded and died silently for weeks. This is the part that post left out —what it feels like to be on the blind side— and the distinction I learned the hard way: fail-open versus fail-closed."
translationKey: "agentes-fallo-silencioso"
draft: false
og_image: "/img/og-default.png"
tags: ["detection-engineering", "ai-security", "observability", "automation"]
---

A month ago I published [a post about why health checks lie](/blog/health-check-lies/): that a `200 OK` tells you the service is alive, not that the data it serves is true, and that green is the most dangerous color on a dashboard. I wrote it with the confidence of someone spotting the mistake from the outside.

This week I got to see it from the inside. Two of my own agents had been failing for weeks, and neither warned me. Writing about a failure doesn't vaccinate you against it —turns out it just puts you more on the spot— so here's the part that post left out: what it feels like to be on the blind side, and a distinction I didn't make then and won't forget now.

## The symptom

I have two small agents on a home server. One summarizes the day's security news every morning and sends it to me over Telegram. The other drafts posts from a calendar. Both talk to an LLM via API, with the key stored —I thought— in a credentials file.

I was switching to a cheaper model when I ran the digest agent as a test. It worked: message in Telegram, headlines ordered, "digest sent" in the log. Green.

Except the smart summary —the one that picks the 3 stories that matter and analyzes them— wasn't there. Just raw headlines. The agent had been sending something that *looked* like a digest for weeks, and the dashboard in my head stayed green because the message arrived on time every morning. Exactly what I described in June, happening to me without my seeing it.

## Root cause: the key that was never there

The credentials file the scripts read from didn't contain the API key. It never had. It lived somewhere else, and at some point during a refactor the scripts were left reading the wrong file. They loaded the key as an empty string, called the API with a blank `Authorization: Bearer `, and got back an **HTTP 401**.

A textbook config bug. The bug isn't the interesting part. It's that my two agents reacted to the *same* 401 in opposite ways —and one was much worse than the other—.

## Fail-open versus fail-closed

Here's the distinction I never quite named in the health-check post, and it's the one that really matters.

**The digest agent failed open.** It had a `try/except` around the call. When the 401 came, it caught the exception, wrote a discreet "summary failed" to a log nobody reads, and **carried on** sending the digest with headlines only. From the outside, all normal. The degradation was invisible.

**The blog agent failed closed.** No error handling. The 401 took it down entirely. Cron ran it, it blew up, and the error was lost because nobody watched the cron output.

One degraded silently. The other died silently. And if I have to pick which scares me more, I choose the first without hesitation. A system that goes down you eventually see: something stops arriving, someone complains. A system that **keeps delivering a degraded version of itself** can last months, because it produces just enough not to raise suspicion. It's the «green dashboard over a rotten field» from my earlier post, except this time the field was mine.

The difference between the two wasn't design. It was luck. Neither was built to fail safely: one went quiet because of a thoughtlessly placed `try/except`, the other screamed into the void for lack of one. Silent fail-closed isn't better than fail-open by design —it's fail-open with worse luck—. The safe outcome would have been for either one to warn me. Neither did.

## What I changed

In June's post I proposed the cure in the abstract: cheap assertions that check the data means what it claims to mean. This week I had to actually write them, against my own code:

- **I moved the key** to the place the scripts read from, and verified —loading it and measuring its length— that both see it. Verify, don't assume.
- **I killed the digest's fail-open.** If the summary isn't generated, it no longer sends headlines dressed up as analysis: it sends an explicit notice that it failed. I'd rather a loud error than a false success.
- **I added a content assertion, not a status one.** The agent checks that the LLM response exists and has the shape of a summary before calling it good. The second question I preach: not "did it finish?" but "did it do its job?".

And a kicker that proves the moral: the cheap model I was switching to turned out to be a reasoning model that, under the digest's token limit, returned an *empty* response with an impeccable `200 OK`. Without the content assertion, I would have "fixed" the agent while leaving it just as broken —this time with a correct status code's blessing—. The 200 lying again, right while I was fixing the lies.

## The lesson I'm taking away

I wrote a month ago that green is an assertion, not a destination, and that you have to make it prove itself. I believed it. I wasn't doing it in my own house. The gap between knowing something and applying it to yourself is wider than any of us likes to admit, and you cross it by tripping over what you already wrote.

Coverage you haven't measured is an assumption, not a fact —I'll sign that today with more conviction than in June—. And fail-open is comfortable precisely because it never wakes you at night. What doesn't wake you when it should is what's going to hurt you most.
