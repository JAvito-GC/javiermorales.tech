---
title: "Detection-as-Code: How I Cut False Positives by 60%"
date: 2026-04-22
description: "A systematic noise reduction program across a multi-account AWS environment with hundreds of SIEM detections, unit testing, and automated deployment."
tags: ["Detection Engineering", "SIEM", "AWS", "Security"]
og_image: "/img/og-detection.png"
translationKey: "detection-as-code"
---

When you inherit a detection platform with hundreds of rules in a multi-account AWS environment, the first instinct is to add more. More rules, more coverage, more alerts.

The problem: **more alerts doesn't mean more security.** It means more noise, more analyst fatigue, and more real alerts buried under false positives.

This article explains how I led a systematic program to reduce false positive volume by 60% without sacrificing real coverage.

## The Problem: Death by Alerts

The initial state:

- **Hundreds of detections** in production covering cloud, identity, SaaS, and endpoint telemetry
- **Multi-account AWS environment** with dozens of accounts, each with its own behavioral pattern
- **Unsustainable alert volume**: the security team couldn't distinguish critical from noise
- **No testing**: rules deployed directly to production with no validation

```
                    BEFORE
    ┌──────────────────────────┐
    │   CloudTrail  GuardDuty  │
    │   Identity    SaaS Logs  │
    │   Endpoint    VPC Flow   │
    └────────────┬─────────────┘
                 │
          ┌──────▼──────┐
          │    SIEM     │
          │ (hundreds   │
          │  of rules)  │
          └──────┬──────┘
                 │
    ┌────────────▼────────────┐
    │   AVALANCHE OF ALERTS   │
    │   (60% false positives) │
    └─────────────────────────┘
```

## Step 1: Telemetry Audit

Before touching a single rule, I ran a **full telemetry audit**. I discovered:

- **Stale sources**: critical log sources that had gone months without sending data. Nobody noticed because there was no source health monitoring
- **Broken routing**: a significant portion of detections weren't reaching the security team due to a silent routing configuration failure

The audit revealed the problem wasn't just the rules — it was the infrastructure underneath them.

## Step 2: Detection-as-Code

Every detection is treated as code:

### Detection Structure

```python
# detection: iam_role_creation_unusual_hours
# severity: medium
# tactic: persistence

def rule(event):
    return (
        event.get("eventName") == "CreateRole"
        and not is_known_automation(event)
        and is_outside_business_hours(event)
        and not is_infrastructure_role(event)
    )

def title(event):
    return f"IAM Role created outside business hours by {event.deep_get('userIdentity', 'arn')}"

def alert_context(event):
    return {
        "account": event.get("recipientAccountId"),
        "region": event.get("awsRegion"),
        "role_name": event.deep_get("requestParameters", "roleName"),
        "user": event.deep_get("userIdentity", "arn"),
    }
```

### Unit Testing

Each rule has positive and negative test data:

```python
def test_rule_fires_on_manual_creation():
    event = create_event(
        eventName="CreateRole",
        hour=3,  # 3 AM
        user="arn:aws:iam::123:user/human"
    )
    assert rule(event) is True

def test_rule_ignores_terraform():
    event = create_event(
        eventName="CreateRole",
        hour=3,
        user="arn:aws:iam::123:role/terraform"
    )
    assert rule(event) is False
```

### Automated Deployment

```
    ┌─────────┐    ┌──────────┐    ┌──────────┐
    │  Git    │───▶│  CI/CD   │───▶│  SIEM    │
    │  Push   │    │  Tests   │    │  Deploy  │
    └─────────┘    └──────────┘    └──────────┘
         │              │               │
    Detection     Unit tests      Rule active
    as code       + linting       in production
```

## Step 3: Systematic Noise Reduction

The reduction followed three strategies:

### 1. Infrastructure Role Baselining

The #1 source of false positives: **infrastructure roles doing normal things**.

Terraform, CI/CD, Lambda functions — all generate events that look suspicious but are normal operations. I built a baselining system:

- Catalog of infrastructure roles per account
- Normal behavior pattern per role
- Dynamic suppression: if behavior matches baseline, no alert

### 2. Contextual Enrichment

Each alert is enriched with context before reaching the analyst:

- **Identity**: human, service, or automation?
- **Account**: production, staging, or sandbox?
- **History**: has this activity occurred before?
- **Schedule**: within the responsible team's business hours?

### 3. Output Routing Optimization

Not all alerts need the same destination:

| Severity | Destination | Response Time |
|----------|------------|--------------|
| Critical | PagerDuty + Slack | Immediate |
| High | Security Slack channel | < 1 hour |
| Medium | Auto-created ticket | < 24 hours |
| Low/Info | Dashboard only | Weekly review |

## Step 4: Data Lake Optimization

Query performance was another bottleneck. I achieved **over 90% performance improvement** in SIEM queries:

- Re-architected legacy infrastructure from EC2 to event-driven Lambda
- Fixed a critical data loss bug in the pipeline
- Optimized partitioning and compression

## Results

After 6 months of systematic work:

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| False positives | Baseline | -60% | Reduction |
| Query performance | Baseline | +90% | Speed |
| Coverage | X rules | >X rules | More detections |
| Testing | 0% | 100% of rules | Unit tested |
| Stale sources | Unknown | 0 | Monitored |

## Lessons

1. **Less noise > more rules.** A detection generating 100 false positives is worse than no detection — it creates alert fatigue
2. **Audit your sources first.** If your logs are stale or your alerts aren't reaching you, it doesn't matter how good the rules are
3. **Treat detections as code.** Testing, code review, CI/CD. If it has no tests, it doesn't deploy
4. **Context is everything.** The same action can be an attack or normal operations. Without context, it's noise
5. **Measure noise, not just coverage.** Coverage metrics alone incentivize more rules, not better rules

---

*This article reflects general detection engineering patterns. Specific implementation details are generic and do not represent any particular organization's architecture.*
