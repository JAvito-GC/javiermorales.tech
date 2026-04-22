---
title: "How I Installed OpenClaw Locally for 0 EUR"
date: 2026-04-22
description: "Step-by-step guide to installing OpenClaw on Ubuntu with a local GPU and Qwen 3.6 via OpenRouter. No VPS, no subscriptions, no paid hosting."
summary: "Nobody has published a local install guide for OpenClaw — everything out there is VPS tutorials with affiliate links. Here's exactly how I set it up on my Ubuntu PC with a 6GB GPU and Qwen 3.6 for free via OpenRouter."
translationKey: "openclaw-local"
draft: false
tags: ["openclaw", "local-ai", "ollama", "openrouter", "ubuntu"]
---

Search "install OpenClaw" on YouTube. The first 30 results are the same thing: a paid VPS, an affiliate link, and a tutorial copied from the official README. Nobody explains how to install it on a PC you already have at home.

I did it. An old PC with Ubuntu, a 6GB GPU, and zero euros per month. Here's everything you need to know.

## Why local AI

Three reasons:

1. **Cost: 0 EUR/month.** No subscription. No API bill. Open source models run on your hardware.
2. **Privacy.** Your prompts never leave your local network. No provider stores them, trains on them, or sells them.
3. **Always on.** An agent running 24/7 at home can automate tasks while you sleep. It doesn't depend on having a browser tab open.

There's a fourth reason that doesn't get mentioned enough: with a residential IP you can scrape portals that block datacenter IPs. VPS ranges from Hetzner, DigitalOcean or AWS are blacklisted. Your home connection is not.

## Hardware: what you actually need

This is what I use:

| Component | My setup | Recommended minimum |
|-----------|----------|-------------------|
| CPU | Intel i5-4690 (2014) | Any 4-core CPU |
| RAM | 32 GB DDR3 | 16 GB (tight) |
| GPU | NVIDIA GTX 980 Ti (6 GB VRAM) | Any NVIDIA GPU with 4+ GB VRAM |
| Disk | HDD 380 GB (dedicated partition) | 50 GB free |
| OS | Ubuntu 24.04 LTS | Ubuntu 22.04+ or Debian 12+ |

A few important notes:

- **The GPU is not mandatory.** Ollama can run models on CPU and RAM alone. But it's 3-5x slower.
- **6 GB VRAM is a real limit.** Models like Gemma 3 4B (3.3 GB) fit comfortably. Qwen 3.5 9B in Q4_K_M (~5.7 GB) barely fits. Anything above 9B needs more VRAM or offloads to CPU (slow).
- **32 GB RAM is the sweet spot.** With 16 GB you can run models up to ~12B on CPU, but it gets tight if you want OpenClaw + Ollama + a browser open at the same time.
- **Disk doesn't matter if you use API.** If you rely on OpenRouter you don't need to download models (the largest ones are 20+ GB). You only need space if going full local.

My PC is from 2014. Literally a 12-year-old processor. If yours is newer, even better.

## Step 1: Ubuntu 24.04

If you already have Linux installed, skip to step 2. If you're coming from Windows, the safest route is dual boot: install Ubuntu on a separate partition without touching Windows.

I won't cover Ubuntu installation here because there are 10,000 tutorials and every case is different (UEFI vs Legacy, SSD vs HDD, existing partitions). The only things that matter:

- **Ubuntu 24.04 LTS** (supported until 2029)
- **Dedicated partition** of at least 50 GB
- **NVIDIA drivers installed** (Ubuntu detects them automatically during installation, but verify)

To confirm the GPU is detected:

```bash
nvidia-smi
```

You should see something like:

```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.xxx       Driver Version: 550.xxx       CUDA Version: 12.x              |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce GTX 980 Ti     Off  | 00000000:01:00.0  Off |                  N/A |
| 28%   34C    P8              16W / 250W |      0MiB /  6144MiB   |      0%      Default |
+-----------------------------------------+------------------------+----------------------+
```

If `nvidia-smi` doesn't work, install the drivers:

```bash
sudo apt update
sudo ubuntu-drivers install
sudo reboot
```

## Step 2: Install Ollama

Ollama is the runtime that executes AI models on your machine. Think Docker, but for LLMs.

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Verify it's running:

```bash
ollama --version
```

```
ollama version 0.21.0
```

Ollama installs as a systemd service and starts automatically. The server listens on `localhost:11434`.

## Step 3: Download local models

This is where your VRAM matters. These are the models I've tested that fit in 6 GB:

### Gemma 3 4B (recommended to start)

```bash
ollama pull gemma3:4b
```

Size: ~3.3 GB. Leaves VRAM headroom. On my GTX 980 Ti:

```bash
ollama run gemma3:4b "Explain what a reverse proxy is in 3 lines"
```

Speed: ~44 tokens/second on GPU. Fast. Enough for simple tasks: summaries, formatting, classification, short drafts.

### Qwen 3.5 9B Q4_K_M (for higher quality)

```bash
ollama pull qwen3.5:9b-q4_K_M
```

Size: ~5.7 GB. Just barely fits in 6 GB VRAM. Slower than Gemma but noticeably smarter. Good for research, document analysis, long text generation.

Estimated speed: ~18 tokens/second on similar hardware.

### Models that DON'T fit in 6 GB

- **Qwen 3.6 235B** — needs ~120 GB. Impossible locally. But it's free on OpenRouter (next section).
- **Nemotron 120B** — needs ~60 GB+. Only viable in cloud.
- **Qwen 3.5 27B** — needs ~16 GB VRAM or ~32 GB RAM on CPU. Works on CPU with 32 GB RAM but it's slow (~5-8 tok/s).

The reality: models you can run on 6 GB VRAM are good for simple tasks, but for complex reasoning you need something 200B+. That's where OpenRouter comes in.

## Step 4: Install OpenClaw

OpenClaw needs Node.js 22+ and git:

```bash
# Install Node.js 22 via NodeSource
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs git

# Verify
node --version  # v22.22.2 or higher
git --version
```

Install OpenClaw:

```bash
npm install -g @openclaw/cli
```

Verify the version:

```bash
openclaw --version
```

```
openclaw v2026.4.15
```

## Step 5: Configure OpenClaw with Ollama (local models)

The first time you run OpenClaw it walks you through a setup wizard. But you can configure it manually:

```bash
openclaw configure
```

Select:

1. **Provider:** Ollama
2. **Endpoint:** `http://localhost:11434` (default)
3. **Model:** `gemma3:4b` (or whichever you downloaded)

This creates the configuration at `~/.openclaw/openclaw.json`.

Now start the gateway:

```bash
openclaw gateway start --port 18789 --bind 127.0.0.1
```

The `--bind 127.0.0.1` flag is important: it only accepts local connections. If you expose it on `0.0.0.0` without authentication, anyone on your network can use your instance.

To make it persistent (start automatically when the PC boots), create a systemd service:

```bash
mkdir -p ~/.config/systemd/user/

cat > ~/.config/systemd/user/openclaw-gateway.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target ollama.service

[Service]
ExecStart=/usr/bin/openclaw gateway start --port 18789 --bind 127.0.0.1
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now openclaw-gateway.service
```

Verify it's running:

```bash
systemctl --user status openclaw-gateway.service
```

```
● openclaw-gateway.service - OpenClaw Gateway
     Loaded: loaded (~/.config/systemd/user/openclaw-gateway.service; enabled)
     Active: active (running) since ...
```

## Step 6: Configure OpenRouter (for large models)

Local 4-9B models are fine for many things, but there are tasks where you need a 200B+ parameter model: complex analysis, long code generation, multi-step reasoning.

OpenRouter is an API gateway that gives you access to dozens of models. Some are free, including Qwen 3.6 (235B parameters) during its preview period.

### Create account and get API key

1. Go to [openrouter.ai](https://openrouter.ai)
2. Create an account (free)
3. Go to **Keys** -> **Create Key**
4. Copy your key. The format is: `sk-or-v1-...`

**Never share or publish your API key.** Store it securely.

### Configure in OpenClaw

```bash
openclaw configure
```

Select:

1. **Provider:** OpenRouter
2. **API Key:** paste your `sk-or-v1-...` key
3. **Model:** `openrouter/qwen/qwen3-235b-a22b`

This configures Qwen 3.6 (235B parameters, mixture of experts with 22B active) as your main model via API.

Restart the gateway:

```bash
openclaw gateway restart
```

### Alternative: keep both providers

The ideal configuration uses Ollama for fast, cheap tasks (always free) and OpenRouter for tasks that need more power. You can switch between providers by editing `~/.openclaw/openclaw.json`:

```json
{
  "models": {
    "providers": {
      "ollama": {
        "endpoint": "http://localhost:11434"
      },
      "openrouter": {
        "apiKey": "sk-or-v1-..."
      }
    },
    "default": "openrouter/qwen/qwen3-235b-a22b"
  }
}
```

The `default` field determines which model OpenClaw uses by default. Change it to `ollama/gemma3:4b` when you want zero cost.

## Step 7: Test that everything works

### Basic gateway test

```bash
curl http://localhost:18789/health
```

```json
{"status": "ok", "version": "2026.4.15"}
```

### Chat test with the model

```bash
openclaw chat "What version of OpenClaw am I running?"
```

If it responds coherently, everything is working. If you get a connection error, check that the gateway is active (`systemctl --user status openclaw-gateway.service`).

### Test Ollama directly

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "gemma3:4b",
  "prompt": "Hello, respond in one line",
  "stream": false
}'
```

It should return a JSON with the model's response.

## What I use it for

I didn't install this to play around. I use it to automate real work:

- **Automated scraping.** I have cron jobs that launch scrapers every 6 hours and OpenClaw processes the data: cleans duplicates, classifies by brand, calculates prices.
- **Research.** I feed it PDFs, articles or technical documentation and it returns structured summaries.
- **Drafts.** Product descriptions, landing page copy, blog posts (not this one — I wrote this one myself).
- **Data analysis.** I give it a CSV with thousands of rows and ask it to find anomalies or patterns.

The differentiator versus using ChatGPT in the browser: this runs unattended. I can schedule tasks at 3AM and review the results in the morning. It's an agent, not a chatbot.

## Cost breakdown

| Item | Monthly cost |
|------|-------------|
| Hardware (already owned) | 0 EUR |
| Ubuntu 24.04 | 0 EUR |
| Ollama | 0 EUR |
| OpenClaw | 0 EUR |
| Local models (Gemma, Qwen) | 0 EUR |
| Electricity (~50W average, 24/7) | ~5 EUR |
| OpenRouter (Qwen 3.6 free preview) | 0 EUR |
| **Total** | **~5 EUR** |

When the Qwen 3.6 free preview on OpenRouter ends, the per-token cost will be minimal — we're talking cents per conversation. And you always have local models as a free fallback.

Compare that to the alternatives:

- Claude/ChatGPT subscription: 20 EUR/month (and you can't use them as an autonomous agent)
- VPS with GPU (Lambda, Vast.ai): 50-200 EUR/month
- Anthropic or OpenAI API without limits: variable, but easily 30+ EUR/month with moderate usage

## Limitations (being honest)

- **6 GB VRAM limits you to small models.** Gemma 3 4B and Qwen 3.5 9B are useful but don't compete with GPT-4 or Claude Opus on complex tasks. For that you need OpenRouter.
- **A 2014 i5 is not fast.** CPU inference is viable but slow. If you plan to run 27B+ models on CPU, be patient.
- **No Docker, no sandbox.** OpenClaw has a sandbox mode based on Docker. I don't have it installed, so commands the agent executes have full system access. Be careful with what you ask it to do.
- **Initial setup is not trivial.** If you've never touched Linux, installing Ubuntu + NVIDIA drivers + Ollama + Node.js + OpenClaw can take an afternoon. But you do it once.

## Conclusion

All OpenClaw content on the internet assumes you're going to pay for a VPS. Nobody talks about the most obvious option: use a PC you already have.

A 2014 computer with Ubuntu, 32 GB of RAM and a 6 GB GPU is enough to have your own AI agent running 24/7. Free. Without depending on any provider.

The complete setup took me about 3 hours including the Ubuntu installation. If you already have Linux, you can have it running in an hour.

If you have questions or want to see how I use it to automate motorcycle price scraping, subscribe — more articles are on the way.

---

*Updated: April 22, 2026. OpenClaw v2026.4.15, Ollama v0.21.0, Ubuntu 24.04 LTS.*
