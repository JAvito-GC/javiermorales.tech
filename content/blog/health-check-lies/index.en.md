---
title: "Your Health Check Is Lying to You"
date: 2026-06-25
lastmod: 2026-09-01
description: "A 200 OK tells you the service is up. It tells you nothing about whether the data inside it is true. Here's how a monitoring dashboard can stay green while your product quietly rots — and the cheap habit that catches it."
summary: "Availability and correctness are two different questions, and most monitoring only answers the first one. I walk through how a system can pass every health check while serving confidently wrong data, why 'green' is the most dangerous color on a dashboard, and the one query that turns a liar into a witness."
translationKey: "health-check-lies"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "monitoring", "data-quality", "detection-engineering", "observability"]
---

There is an old pilot's saying: the instruments don't lie, but they only tell you what they're built to measure. An altimeter will happily read 3,000 feet while you fly straight into a mountain, because measuring the mountain was never its job.

Most of our monitoring is an altimeter. It measures the wrong thing with total confidence.

---

## Two questions, one answer

Every health check answers a question: *is the service up?* It pings an endpoint, gets a `200 OK`, paints the dashboard green, and goes back to sleep. This is genuinely useful. When the box falls over, you want to know in seconds, not when a customer emails.

But "is the service up?" is not the question your users actually care about. They care about *is the answer correct?* And those two questions have almost nothing to do with each other.

A service can be up and serving garbage. A database can respond in 4 milliseconds with a number that is confidently, precisely wrong. The HTTP layer has no opinion about whether the bytes it returns are true. It only knows they were returned.

This is the gap where products quietly die. Not in a crash — a crash is loud, a crash pages you at 3am, a crash gets fixed. They die in the green. They die while every chart says fine.

---

## A green dashboard over a rotting field

Let me make this concrete with a pattern I keep running into, anonymized.

Imagine a system that ingests messy real-world text — listings, tickets, support messages, whatever — and classifies each item into a clean category from a reference table. To do the classification it uses fuzzy matching: take the messy input, find the closest entry in the reference table by text similarity, assign it.

Fuzzy matching is wonderful until it isn't. It has a failure mode that no health check on earth will catch: it always returns *something*. Ask it to match a string that has no good answer, and it won't error. It won't return null. It will hand you the least-bad option with a straight face and a similarity score that looks plausible.

So an input that should be classified as "Type 700" — a modern, distinct variant — gets matched against the closest string in the table, which happens to be "Type 600," an older one that shares most of its name. The match scores high. The record is written. The endpoint returns `200 OK`. The dashboard stays green.

And now your product is lying. Not crashing — lying. It's showing users a category, a metric, a recommendation built on a label that is simply false. The aggregate even looks reasonable: the stats for "Type 600" come out plausible, because the things hiding under that label are real items with real values. The number is internally consistent and externally wrong. That is the worst kind of wrong, because nothing about it trips an alarm.

I have watched a system run for weeks in exactly this state, every check passing, while a meaningful share of its core records pointed at the wrong thing. The monitoring wasn't broken. It was answering the question it was built to answer — *is the service up?* — perfectly. Yes. The service was up. The service was up the whole time it was wrong.

---

## Why "green" is the most dangerous color

The reason this is dangerous, and not just annoying, is psychological. A red dashboard creates urgency. A green dashboard creates *trust* — and trust is exactly what you don't want pointed at a system you haven't actually verified.

Green tells the on-call engineer to stand down. Green tells the product manager the data's fine, ship the feature. Green tells you, three weeks later when a user finally complains, to first suspect the user, because look — everything's green. The dashboard becomes an alibi. It launders a data quality problem into "must be something on your end."

Security people will recognize this immediately, because it's the same failure as a SIEM that's ingesting logs but parsing half of them into the wrong fields. The pipeline is "healthy." Events per second look normal. And your detections are quietly blind, because the field that says `user` is actually holding a hostname, and nothing checks that the contents mean what the schema claims they mean. Availability is green. Correctness is on fire. Nobody's looking at correctness.

---

## The same trap, from the other side: when the check itself fails open

The fuzzy-match story is a check that stays green while the *data* rots. But the exact same class of failure can hit the check's own transport — and I walked straight into it the morning I wrote this.

I came back from time off and ran my infra health check before touching anything. It told me both of my production sites were down:

```
✗ HTTP: motoradar.es → 000
✗ HTTP: javiermorales.tech → 000
```

They were not down. Both had been serving traffic the whole time. I ran curl by hand with full timing, and the numbers told the real story:

```
$ curl -w "code %{http_code} | connect %{time_connect}s | tls %{time_appconnect}s\n" https://motoradar.es
curl: (35) Recv failure: Connection reset by peer
code 000 | connect 0.068s | tls 0.000s
```

TCP connected in 68ms — *something* on the path accepted the connection — but TLS never completed (`time_appconnect` is `0.000`) and curl exited **35**, a reset mid-handshake. A quick control settled it: `curl https://www.cloudflare.com` reset the same way. The problem wasn't my sites, it was my own egress — a TLS-inspecting middlebox on the path was killing outbound HTTPS. The proof: the identical check run from the server itself returned `200` for both.

The check measured *my ability to reach the site from this one machine* and reported it as *the site's availability*. Those are different questions — the same availability-vs-correctness split as before, just one layer down. My case failed *closed* (a false red — annoying but safe), but flip one detail and the same signal hands you a false green: a timeout treated as "assume up," a reset on the origin's side while your monitoring box has clean egress. And a false green is the one you don't investigate.

The lesson generalizes into one rule: **never trust a proxy for the thing itself. Exercise the real behavior and read the real result.**

| Proxy signal (can fail open) | Exercise the behavior |
|---|---|
| `200 OK` | Fetch the page and assert the *content* you expect is in the body |
| Service is `active` | Confirm it produced its expected *output* this cycle |
| A recent timestamp | Confirm a genuinely *new* record arrived, not a batch touch |
| Port is open | Speak the actual protocol and read the response |
| "Build is green" | Run the code path and check what it *returns* |

---

## The fix is a habit, not a tool

The good news is that the cure is cheap. It is not a new platform. It is not a vendor. It is a *second question*, asked on a schedule, in the same breath as the first.

After "is it up?", add: **"does the data still mean what it claims to mean?"**

In practice that's a handful of cheap assertions running next to your uptime check:

- **Cross-field consistency.** If a record is labeled "Type 600," does the source text it came from actually contain "600"? When the label and the evidence disagree, that's a flag — no human review needed to raise it, just to resolve it. In the fuzzy-match case, this single check would have caught nearly every bad record, because the correct answer was sitting right there in the original text the whole time.
- **Distribution sanity.** Did a category's row count triple overnight? Did a price range suddenly include values that are physically impossible for that item? Outliers at the edges are often the tell that something upstream started mislabeling.
- **The "impossible value" trap.** Pick the things that should never happen — a 1985 product priced like a 2025 one, or a field that's suddenly null in most new rows when it used to be populated — and alert on those directly. They are far more honest than an uptime ping.
- **Concurrent stress, not single-request.** A health check that fires one request and gets one `200` tells you the happy path works for one user. Fire twenty at once and you learn whether it works under the conditions your users actually create.

None of this is exotic. The reason it doesn't get built is not difficulty — it's that the first question is *easy and feels complete*. A green checkmark is satisfying. Writing the assertion that says "and by the way, prove the data isn't garbage" requires admitting that up and correct are different, and that you've only been measuring one of them.

---

## Measure the mountain

The altimeter isn't wrong. It's just answering a smaller question than the one that kills you. Adding a single instrument that looks *forward, at the terrain* — not down, at the number — is the difference between confident flight and a confident hole in the ground.

So the next time a dashboard tells you everything is fine, ask it the question it isn't built to answer. Pull one record at random and check that its label matches its evidence. Count the things that should be impossible. If the system is healthy, you've spent five minutes confirming it honestly. If it isn't, you just found out before your users did — which, in the end, is the only kind of monitoring worth the name.

Green is not a destination. It's a claim. Make it prove itself.
