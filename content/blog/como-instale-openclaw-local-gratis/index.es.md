---
title: "Como instale OpenClaw en local por 0 EUR"
date: 2026-04-22
description: "Guia paso a paso para instalar OpenClaw en Ubuntu con GPU local y Qwen 3.6 via OpenRouter. Sin VPS, sin suscripciones, sin hosting de pago."
summary: "Nadie ha publicado una guia de instalacion local de OpenClaw — todo lo que hay son tutoriales de VPS con enlaces de afiliado. Aqui explico exactamente como lo monte en mi PC con Ubuntu 24.04, una GPU de 6GB y Qwen 3.6 gratis via OpenRouter."
translationKey: "openclaw-local"
draft: false
tags: ["openclaw", "ia-local", "ollama", "openrouter", "ubuntu"]
---

Busca "instalar OpenClaw" en YouTube. Los primeros 30 resultados son lo mismo: un VPS de pago, un enlace de afiliado y un tutorial copiado del README oficial. Nadie explica como instalarlo en un PC que ya tienes en casa.

Yo lo hice. Un PC viejo con Ubuntu, una GPU de 6GB y cero euros al mes. Aqui esta todo lo que necesitas saber.

## Por que IA local

Tres razones:

1. **Coste: 0 EUR/mes.** No hay suscripcion. No hay factura de API. Los modelos open source corren en tu hardware.
2. **Privacidad.** Tus prompts no salen de tu red local. Ningun proveedor los almacena, los entrena ni los vende.
3. **Siempre encendido.** Un agente que corre 24/7 en tu casa puede automatizar tareas mientras duermes. No depende de que tengas una pestana abierta en el navegador.

Hay una cuarta razon que no se menciona lo suficiente: con una IP residencial puedes hacer scraping de portales que bloquean IPs de datacenter. Los VPS de Hetzner, DigitalOcean o AWS estan en listas negras. Tu conexion de casa, no.

## Hardware: lo que necesitas (de verdad)

Esto es lo que uso yo:

| Componente | Mi setup | Minimo recomendado |
|-----------|----------|-------------------|
| CPU | Intel i5-4690 (2014) | Cualquier CPU de 4 nucleos |
| RAM | 32 GB DDR3 | 16 GB (ajustado) |
| GPU | NVIDIA GTX 980 Ti (6 GB VRAM) | Cualquier GPU NVIDIA con 4+ GB VRAM |
| Disco | HDD 380 GB (particion dedicada) | 50 GB libres |
| OS | Ubuntu 24.04 LTS | Ubuntu 22.04+ o Debian 12+ |

Varias cosas importantes:

- **La GPU no es obligatoria.** Ollama puede correr modelos solo con CPU y RAM. Pero es 3-5x mas lento.
- **6 GB de VRAM es un limite real.** Modelos como Gemma 3 4B (3.3 GB) caben sin problema. Qwen 3.5 9B en Q4_K_M (~5.7 GB) cabe justo. Cualquier cosa por encima de 9B necesita mas VRAM o se descarga a CPU (lento).
- **32 GB de RAM es el punto dulce.** Con 16 GB puedes correr modelos de hasta ~12B en CPU, pero se te queda corto si quieres OpenClaw + Ollama + un navegador abierto a la vez.
- **El disco da igual si usas API.** Si tiras de OpenRouter no necesitas descargar modelos (los mas grandes pesan 20+ GB). Solo necesitas espacio si vas full local.

Mi PC es de 2014. Literalmente un procesador de hace 12 anos. Si el tuyo es mas nuevo, mejor.

## Paso 1: Ubuntu 24.04

Si ya tienes Linux instalado, salta al paso 2. Si vienes de Windows, la forma mas segura es hacer dual boot: instalas Ubuntu en una particion separada sin tocar Windows.

No voy a cubrir la instalacion de Ubuntu aqui porque hay 10.000 tutoriales y cada caso es distinto (UEFI vs Legacy, SSD vs HDD, particiones existentes). Lo unico que importa:

- **Ubuntu 24.04 LTS** (soporte hasta 2029)
- **Particion dedicada** de al menos 50 GB
- **Drivers NVIDIA instalados** (Ubuntu los detecta automaticamente en la instalacion, pero verifica)

Para confirmar que la GPU esta detectada:

```bash
nvidia-smi
```

Deberias ver algo como:

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

Si `nvidia-smi` no funciona, instala los drivers:

```bash
sudo apt update
sudo ubuntu-drivers install
sudo reboot
```

## Paso 2: Instalar Ollama

Ollama es el runtime que ejecuta modelos de IA en tu maquina. Es como Docker pero para LLMs.

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Verifica que esta corriendo:

```bash
ollama --version
```

```
ollama version 0.21.0
```

Ollama se instala como servicio de systemd y arranca automaticamente. El servidor escucha en `localhost:11434`.

## Paso 3: Descargar modelos locales

Aqui es donde importa tu VRAM. Estos son los modelos que he probado y que caben en 6 GB:

### Gemma 3 4B (recomendado para empezar)

```bash
ollama pull gemma3:4b
```

Tamano: ~3.3 GB. Deja margen de VRAM libre. En mi GTX 980 Ti:

```bash
ollama run gemma3:4b "Explica que es un reverse proxy en 3 lineas"
```

Velocidad: ~44 tokens/segundo en GPU. Rapido. Suficiente para tareas simples: resumenes, formateo, clasificacion, drafts cortos.

### Qwen 3.5 9B Q4_K_M (para mas calidad)

```bash
ollama pull qwen3.5:9b-q4_K_M
```

Tamano: ~5.7 GB. Cabe justo en 6 GB de VRAM. Mas lento que Gemma pero notablemente mas inteligente. Bueno para research, analisis de documentos, generacion de texto largo.

Velocidad estimada: ~18 tokens/segundo en hardware similar.

### Modelos que NO caben en 6 GB

- **Qwen 3.6 235B** — necesita ~120 GB. Imposible en local. Pero esta gratis en OpenRouter (siguiente seccion).
- **Nemotron 120B** — necesita ~60 GB+. Solo viable en cloud.
- **Qwen 3.5 27B** — necesita ~16 GB VRAM o ~32 GB RAM en CPU. Funciona en CPU con 32 GB RAM pero es lento (~5-8 tok/s).

La realidad: los modelos que puedes correr en 6 GB de VRAM son buenos para tareas simples, pero para razonamiento complejo necesitas algo mas grande. Ahi entra OpenRouter.

## Paso 4: Instalar OpenClaw

OpenClaw necesita Node.js 22+ y git:

```bash
# Instalar Node.js 22 via NodeSource
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs git

# Verificar
node --version  # v22.22.2 o superior
git --version
```

Instalar OpenClaw:

```bash
npm install -g @openclaw/cli
```

Verificar la version:

```bash
openclaw --version
```

```
openclaw v2026.4.15
```

## Paso 5: Configurar OpenClaw con Ollama (modelos locales)

La primera vez que ejecutes OpenClaw te guia un wizard de configuracion. Pero puedes configurarlo manualmente:

```bash
openclaw configure
```

Selecciona:

1. **Provider:** Ollama
2. **Endpoint:** `http://localhost:11434` (por defecto)
3. **Model:** `gemma3:4b` (o el que hayas descargado)

Esto crea la configuracion en `~/.openclaw/openclaw.json`.

Ahora arranca el gateway:

```bash
openclaw gateway start --port 18789 --bind 127.0.0.1
```

El flag `--bind 127.0.0.1` es importante: solo acepta conexiones locales. Si lo expones a `0.0.0.0` sin autenticacion, cualquiera en tu red puede usar tu instancia.

Para hacerlo persistente (que arranque automaticamente al encender el PC), crea un servicio de systemd:

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

Verifica que esta corriendo:

```bash
systemctl --user status openclaw-gateway.service
```

```
● openclaw-gateway.service - OpenClaw Gateway
     Loaded: loaded (~/.config/systemd/user/openclaw-gateway.service; enabled)
     Active: active (running) since ...
```

## Paso 6: Configurar OpenRouter (para modelos grandes)

Los modelos locales de 4-9B estan bien para muchas cosas, pero hay tareas donde necesitas un modelo de 200B+ parametros: analisis complejo, generacion de codigo largo, razonamiento en multiples pasos.

OpenRouter es un gateway de APIs que te da acceso a decenas de modelos. Algunos son gratis, incluyendo Qwen 3.6 (235B parametros) durante su periodo de preview.

### Crear cuenta y obtener API key

1. Ve a [openrouter.ai](https://openrouter.ai)
2. Crea una cuenta (gratis)
3. Ve a **Keys** → **Create Key**
4. Copia tu clave. El formato es: `sk-or-v1-...`

**Nunca compartas ni publiques tu API key.** Guardala en un lugar seguro.

### Configurar en OpenClaw

```bash
openclaw configure
```

Selecciona:

1. **Provider:** OpenRouter
2. **API Key:** pega tu clave `sk-or-v1-...`
3. **Model:** `openrouter/qwen/qwen3-235b-a22b`

Esto configura Qwen 3.6 (235B parametros, mezcla de expertos con 22B activos) como tu modelo principal via API.

Reinicia el gateway:

```bash
openclaw gateway restart
```

### Alternativa: mantener ambos proveedores

La configuracion ideal es usar Ollama para tareas rapidas y baratas (siempre gratis) y OpenRouter para tareas que necesitan mas potencia. Puedes alternar entre proveedores editando `~/.openclaw/openclaw.json`:

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

El campo `default` determina que modelo usa OpenClaw por defecto. Cambialo a `ollama/gemma3:4b` cuando quieras cero coste absoluto.

## Paso 7: Probar que todo funciona

### Test basico del gateway

```bash
curl http://localhost:18789/health
```

```json
{"status": "ok", "version": "2026.4.15"}
```

### Test de chat con el modelo

```bash
openclaw chat "Que version de OpenClaw estoy ejecutando?"
```

Si responde de forma coherente, todo esta funcionando. Si da error de conexion, revisa que el gateway este activo (`systemctl --user status openclaw-gateway.service`).

### Test de Ollama directamente

```bash
curl http://localhost:11434/api/generate -d '{
  "model": "gemma3:4b",
  "prompt": "Hola, responde en una linea",
  "stream": false
}'
```

Deberia devolver un JSON con la respuesta del modelo.

## Para que lo uso

No instale esto para jugar. Lo uso para automatizar cosas reales:

- **Scraping automatizado.** Tengo cron jobs que lanzan scrapers cada 6 horas y OpenClaw procesa los datos: limpia duplicados, clasifica por marca, calcula precios.
- **Research.** Le paso PDFs, articulos o documentacion tecnica y me devuelve resumenes estructurados.
- **Borradores.** Descripciones de producto, textos para landing pages, posts de blog (no este — este lo escribi yo).
- **Analisis de datos.** Le doy un CSV con miles de filas y le pido que encuentre anomalias o patrones.

El diferenciador frente a usar ChatGPT en el navegador: esto corre desatendido. Puedo programar tareas a las 3AM y revisar los resultados por la manana. Es un agente, no un chatbot.

## Desglose de costes

| Concepto | Coste mensual |
|---------|--------------|
| Hardware (ya lo tenia) | 0 EUR |
| Ubuntu 24.04 | 0 EUR |
| Ollama | 0 EUR |
| OpenClaw | 0 EUR |
| Modelos locales (Gemma, Qwen) | 0 EUR |
| Electricidad (~50W medio, 24/7) | ~5 EUR |
| OpenRouter (Qwen 3.6 free preview) | 0 EUR |
| **Total** | **~5 EUR** |

Cuando el free preview de Qwen 3.6 en OpenRouter termine, el coste por token sera minimo — hablamos de centimos por conversacion. Y siempre tienes los modelos locales como fallback gratuito.

Comparalo con las alternativas:

- Suscripcion a Claude/ChatGPT: 20 EUR/mes (y no puedes usarlas como agente autonomo)
- VPS con GPU (Lambda, Vast.ai): 50-200 EUR/mes
- API de Anthropic o OpenAI sin limites: variable, pero facilmente 30+ EUR/mes con uso medio

## Limitaciones (siendo honesto)

- **6 GB de VRAM te limita a modelos pequenos.** Gemma 3 4B y Qwen 3.5 9B son utiles pero no compiten con GPT-4 o Claude Opus en tareas complejas. Para eso necesitas OpenRouter.
- **Un i5 de 2014 no es rapido.** La inferencia por CPU es viable pero lenta. Si piensas correr modelos de 27B+ en CPU, ten paciencia.
- **Sin Docker, sin sandbox.** OpenClaw tiene un modo sandbox basado en Docker. No lo tengo instalado, asi que los comandos que ejecuta el agente tienen acceso completo al sistema. Hay que tener cuidado con lo que le pides que haga.
- **La configuracion inicial no es trivial.** Si nunca has tocado Linux, instalar Ubuntu + drivers NVIDIA + Ollama + Node.js + OpenClaw te puede llevar una tarde. Pero se hace una vez.

## Conclusion

Todo el contenido sobre OpenClaw en internet asume que vas a pagar un VPS. Nadie habla de la opcion mas obvia: usar un PC que ya tienes.

Un ordenador de 2014 con Ubuntu, 32 GB de RAM y una GPU de 6 GB es suficiente para tener tu propio agente de IA corriendo 24/7. Gratis. Sin depender de ningun proveedor.

El setup completo me llevo unas 3 horas contando la instalacion de Ubuntu. Si ya tienes Linux, en una hora lo tienes corriendo.

Si tienes preguntas o quieres ver como lo uso para automatizar scraping de precios de motos, suscribete — hay mas articulos en camino.

---

*Actualizado: 22 de abril de 2026. OpenClaw v2026.4.15, Ollama v0.21.0, Ubuntu 24.04 LTS.*
