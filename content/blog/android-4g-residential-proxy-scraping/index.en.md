---
title: "IP Reputation Is a Fragile Detection Signal — What I Learned Building a 4G Residential Proxy"
date: 2026-07-10
description: "IP reputation is one of a WAF's cheapest signals — and one of its most brittle. I built a residential proxy from an old Android phone to see the detection surface from the other side. Here's what it teaches a defender about where IP-based detection breaks and why behavioral signals win."
summary: "Most WAFs lean hard on IP reputation to tell humans from bots. Building the evasion side — an old Android phone as a 4G residential proxy — showed me exactly where that signal collapses, and why rate and sequence behavior outlast any IP allow/deny list. A detection-engineering post-mortem, with the full stack included."
translationKey: "android-4g-proxy"
draft: false
og_image: "/img/og-default.png"
tags: ["detection-engineering", "security", "waf", "networking", "threat-detection"]
---

I spend my day building detection. The fastest way I know to understand how a signal fails is to stand on the other side of it and try to beat it — so when a commercial WAF blocked a data-collection job of mine in minutes, I treated it as a detection-engineering exercise: *which signal caught me, and how brittle is it?*

The answer was IP reputation, and it turned out to be far more fragile than its prominence in most WAF rule sets suggests. A datacenter IP hit the WAF a few times and got a JavaScript challenge, then a hard block. Rotating through more datacenter IPs bought me nothing — they all sat in the same reputation bucket the WAF already distrusted. That's IP reputation working exactly as designed.

Then I moved the same traffic behind a residential IP, and the signal collapsed. Not because I was clever — because the signal is coarse. This post is that experiment: I built the evasion path (an old Android phone as a 4G residential proxy), watched which detections held and which didn't, and pulled out the lesson for anyone who *builds* WAF logic rather than dodges it. The full stack is included, and — the part most write-ups skip — everything that breaks.

**Why a defender should care:** if one spare phone neutralizes your IP-reputation layer, that layer is a speed bump, not a wall. What actually held up was behavioral detection — request rate and sequence — and that's where detection budget belongs.

## Why a phone IP is different

A WAF's job is to separate humans from bots, and IP reputation is one of its cheapest signals. Datacenter ranges (AWS, GCP, OVH, DigitalOcean) are trivially fingerprinted and sit in a permanent "guilty until proven innocent" bucket. A single aggressive sweep from one of them trips the challenge.

Mobile carrier IPs are the opposite. Thousands of real humans share them behind CGNAT, so blanket-blocking a mobile range means blocking real customers — something no WAF operator wants to do. The IP your phone gets on 4G is indistinguishable from the one a real buyer browsing on their commute is using, because it *is* that kind of IP.

That's the whole insight, and it cuts both ways. As a defender, it means IP reputation is structurally unable to distinguish a residential proxy from a real customer — the false-positive cost of blocking a mobile range is too high to pay. Any detection strategy that leans primarily on IP reputation is defending a door that doesn't lock. The rest of this is plumbing — but keep that failure mode in mind, because the fix on the defensive side falls out of it.

## The stack

The goal: let a container on my VPS make outbound HTTP requests that exit through the phone's 4G connection, without the phone needing a public IP or an open inbound port.

```
[ container on VPS ] → [ socat bridge ] → [ reverse SSH tunnel ] → [ Android/Termux ] → [ 4G / carrier ] → internet
```

**1. Termux on the phone.** [Termux](https://termux.dev/) gives you a real Linux userland on Android. Install `openssh` and `autossh`. No root required.

**2. A reverse tunnel, phone → server.** The phone can't accept inbound connections (CGNAT, no public IP), so *it* dials out to the server and opens a reverse tunnel. The server side of the tunnel becomes a local port that forwards back through the phone:

```bash
# on the phone (Termux)
autossh -M 0 -N \
  -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" \
  -R 2222:localhost:8080 \
  tunneluser@your-server
```

Here the phone runs a tiny local HTTP proxy on `:8080` (any lightweight SOCKS/HTTP proxy in Termux works), and exposes it on the server as `localhost:2222`. `autossh` respawns the tunnel when it dies — which it will.

**3. A socat bridge into the container network.** My scraper runs in a container, so `localhost:2222` on the host isn't directly reachable from inside it. A one-line `socat` service bridges the host-local tunnel port onto the container's gateway address:

```ini
# /etc/systemd/system/proxy-bridge.service
[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:8888,bind=172.18.0.1,fork,reuseaddr TCP:127.0.0.1:2222
Restart=always
```

Now the container reaches the phone's proxy at `172.18.0.1:8888`, and the scraper just sets that as its HTTP proxy.

**4. The part that actually matters: slow-drip.** A good residential IP is necessary but not sufficient. If you fire a full catalog sweep through it — hundreds of pages back to back — you still look like a bot and trip behavioral detection, IP reputation notwithstanding. The fix is to stop batching.

Instead of one big run, I schedule small bites: a handful of pages every 15 minutes, spread across the day.

```cron
7,22,37,52 * * * * /path/to/scrape_one_slice.sh
```

Four slices an hour, each doing a little work. Over a day that adds up to full coverage, but the request rate from any single IP stays in the noise floor of normal human browsing. This single change did more for reliability than every header-spoofing trick combined.

**5. Back off on your own blocks.** The scraper keeps a tiny state file with a `consecutive_blocks` counter. Three blocks in a row and it goes dormant for an hour instead of hammering into a wall and deepening the penalty. When the tunnel drops (it will), the requests fail fast, the counter climbs, and the thing puts itself to sleep rather than burning goodwill.

## Everything that breaks

Scraping posts love to stop at the clever part. Here's the maintenance tax nobody mentions.

- **The tunnel dies constantly.** Phone sleeps, Android kills the background process to save battery, the carrier renegotiates the connection, Wi-Fi/4G handoff. `autossh` handles most respawns, but Android's aggressive battery management will eventually kill Termux itself. You need the phone plugged in, battery optimization disabled for Termux, and a wake-lock held. Even then, plan for a manual "kick it" step.
- **Self-healing is mandatory, not optional.** A watchdog on the server that checks whether the tunnel port is alive and the proxy actually egresses (curl your own IP-echo endpoint through it) is the difference between "resilient" and "silently dead for three days." Ask me how I know.
- **It does not scale.** This is one IP. It's great for low-volume, respectful collection. If you need real throughput you're back to a proxy pool — this technique is a scalpel, not a firehose.
- **State counters lie after an outage.** When the tunnel was down, every failed request looked like a "block" and drove the backoff counter to max — so the scraper stayed dormant long after the tunnel came back. Distinguish "I was blocked" from "I had no route." I didn't at first, and lost a day of collection to a scraper that was sulking over a network problem that had already resolved.

## The part you have to think about: ethics and legality

A residential IP makes you *look* like a normal visitor. That is exactly why you should hold yourself to a higher standard, not a lower one, because the technical guardrails that would normally slow you down are gone.

- Respect `robots.txt` and terms of service. "I can" is not "I may."
- Scrape publicly visible data only. Never anything behind auth, never anything personal beyond what's already public.
- Rate-limit yourself well below what the site can handle — the slow-drip isn't just anti-detection, it's basic courtesy so you're not degrading someone's service.
- Know your jurisdiction. Public-data scraping law is unsettled and varies wildly by country.

The slow-drip approach aligns incentives nicely here: the polite thing (few requests, well spaced) and the effective thing (staying under detection thresholds) turn out to be the same thing.

## What this teaches a defender

I built the offensive side, but the payoff is defensive. Three lessons I'm taking back into how I write detection:

- **IP reputation is a filter, not a control.** It cheaply clears the low-effort majority (raw datacenter sweeps), and that's worth having. But treat it as the first coarse sieve, never as the thing standing between you and a motivated actor. One phone defeats it. Budget accordingly.
- **Rate and sequence are the signals that survived.** The slow-drip is what actually kept me under the radar, long after the IP looked clean. That's the mirror image of the defensive truth: behavioral detection — requests per identity over time, access-pattern shape — outlasts any allow/deny list, because it keys on *what the client does*, not *where it comes from*. That's where detection engineering earns its keep.
- **A good signal degrades gracefully; a brittle one fails silently.** IP reputation gives a binary verdict and no aftertaste — once you're past it, it tells the defender nothing. Behavioral scoring accumulates evidence and can catch the same actor on the second, third, tenth deviation. Prefer signals that keep talking.

The uncomfortable summary: the polite thing (few requests, well spaced) and the evasive thing turn out to be identical — which is exactly why volume-and-cadence anomalies are the detections worth investing in. An attacker who has to behave like a normal user to stay hidden has already given up most of their advantage.

If you want to reproduce the setup to test your own detections against it: plug the phone in, disable battery optimization, and write the watchdog *first*. Future-you, staring at three days of empty data, will be grateful.
