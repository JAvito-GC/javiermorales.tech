---
title: "Your 'Impossible' Bypass Has an Expiry Date"
date: 2026-06-30
description: "I closed a case three weeks ago: a geo-filter that couldn't be beaten, full stop. Today the same filter handed me everything I'd given up on. Nothing in my code changed. The infrastructure underneath it did — and that's the part most write-ups never account for."
summary: "A geo-fence I'd documented as 'impossible to bypass — case closed' quietly became trivial, because one variable I treated as constant wasn't. This is a field note on reverse-engineering a marketplace's geo-filter in real time, the three undocumented gotchas that decide whether it honors your coordinates or silently ignores them, and the bigger lesson: every bypass you write down has a shelf life, because the other side's infra moves while your notes sit still."
translationKey: "impossible-bypass-expiry"
draft: false
og_image: "/img/og-default.png"
tags: ["security", "reverse-engineering", "scraping", "apis", "geo-fencing"]
---

Three weeks ago I wrote a sentence I was sure of: *"There is no way to capture this region without an exit IP located there. Case closed."*

I was reverse-engineering the geo-filter of a Spanish classifieds marketplace — the kind where people sell second-hand motorcycles. I needed listings from a specific island region, and the site simply would not give them to me. I tried everything a reasonable person tries, documented the dead end, and moved on. Cases get closed for good reasons.

Today the same filter handed me exactly what I'd given up on. I changed nothing in my code. And that gap — between "impossible" and "trivial," with no edit in between — is the whole point of this post.

---

## The premise I treated as a constant

Here's the thing about a closed case: it rests on assumptions you stop questioning. Mine was the exit IP.

The marketplace geo-filters anonymous traffic by the **IP it sees**, not by the coordinates you send. I'd verified that. So my conclusion followed cleanly: my requests left through a mobile proxy whose carrier-grade NAT geolocated to the capital, hundreds of kilometers from the region I wanted. Send whatever latitude and longitude you like — the IP says capital, so you get the capital. There is no bypass. Done.

The logic was airtight. The premise was rotten.

Because "the exit IP geolocates to the capital" is not a law of physics. It's a fact about one carrier's NAT configuration on one day. And carriers change. Somewhere in those three weeks the proxy's traffic started egressing through a different operator — and that operator's IP geolocated *to the exact region I'd written off.* My "impossible" was a snapshot of infrastructure I didn't own, and the infrastructure moved.

This is the trap, and it's worth naming precisely: **I had filed an environmental variable under "constant."** Everything downstream of that filing was correct reasoning built on a fact with an expiry date I never checked.

---

## What "verify, don't assume" actually costs

The first thing I did today wasn't write code. It was run one command: *where does my exit IP geolocate right now?* Two seconds. The answer rewrote a conclusion I'd held for three weeks.

I want to sit on that for a moment, because "always verify" is the kind of advice that sounds free and isn't. Verifying is cheap. *Knowing what to re-verify* is the expensive part. I re-test my own code constantly. I had never thought to re-test the geolocation of an IP I don't control, because I'd mentally promoted it from "external dependency" to "settled fact." That promotion is the actual bug. The code was fine. The mental model had a stale cache.

If you operate anything that depends on a third party's behavior — an API, a proxy, a rate limiter, an upstream classifier — make a list of the things you've decided are stable. That list is your real attack surface. Not the code. The assumptions.

---

## The three gotchas that decide everything

Once the IP was right, I still had to make the filter honor my coordinates. The naive path — drive a headless browser to the search page — kept returning the wrong region, because that path hits an endpoint that filters by IP and *ignores the coordinates in the URL entirely.* Fine for the region my IP now matched; useless for the neighboring one.

So I went to the marketplace's direct search API instead. It does honor coordinates — but only if you get three undocumented details exactly right. Each one, on its own, silently breaks the geo-filter and hands you national results that *look* plausible. I found all three the only way you ever find these: by running the request, staring at the postal codes that came back, and asking why they were wrong.

**1. Sort order quietly overrides distance.** Add `order_by=newest` and the API ranks results nationally and drops the distance filter on the floor. With my target coordinates *plus* newest: 40 results, zero from the region. The same request *without* newest: 5 results, every one of them in the right region. The sort parameter wasn't sorting — it was overriding the geo-fence. Nothing in the response tells you this. The 40 wrong results arrive with a 200 OK and full confidence.

**2. A price floor returns nothing.** The API takes a `min_price` parameter. Send it, and the endpoint returns zero items — not an error, not a warning, just an empty list that reads identically to "no stock here." The filter expects a price *range*; a floor on its own poisons the whole query. I moved price filtering to my own code and the listings came back.

**3. Keyword shape changes the catch.** Searching `motorcycle+trail` returned a quarter of what plain `trail` did. The API matches multi-word phrases far more strictly than single tokens. The "more specific" query was the worse query.

None of these throw. None of them log. Each one returns a clean, populated, *wrong* result that you will accept unless you check the one field that matters — in my case, the postal code of every single item that came back.

---

## The pattern, stated plainly

Strip away the motorcycles and the marketplace and here's what's left, and it generalizes well past scraping:

- **A bypass is a relationship, not a fact.** It describes how your system behaves against someone else's system *at a moment in time*. The other side doesn't owe you a changelog. Carriers re-NAT, APIs re-rank, classifiers retrain. The day you write "impossible," start a timer.
- **"Closed" is the most dangerous status a finding can have.** An open problem gets re-examined. A closed one gets cited. My three-week-old note wasn't just stale — it was actively steering me away from re-checking, because I'd already "solved" it. The cost of a wrong closed case is everything you don't do because of it.
- **A 200 OK is not a correct answer.** Every one of the three gotchas returned success. Success is the absence of an error, not the presence of the truth. The only thing that told me the difference was validating the actual content against what it claimed to be — the postal codes, not the status line.

I reopened the case, migrated the region's queries to the direct API with all three details right, and the listings I'd called unreachable started flowing. The fix took an afternoon. Realizing the fix was *possible* took one `curl` against an assumption I'd stopped questioning three weeks ago.

That's the discipline worth keeping: not "verify everything," which is exhausting and vague, but **keep a written list of what you've decided is constant, and put an expiry date on each line.** Those are the facts that will rot quietly while you build on top of them — and they're the ones nobody re-checks, precisely because they're already filed under "done."
