# javiermorales.tech

Personal site and blog built with Hugo. Luxury dark theme, bilingual (EN/ES), CSS-only animations.

**Live:** [javiermorales.tech](https://javiermorales.tech)

## Stack

- **Hugo** — Static site generator
- **Nginx** — Serving on Hetzner VPS
- **Cloudflare** — DNS, SSL, CDN
- **Google Fonts** — Playfair Display + Inter

## Structure

- `layouts/` — Custom theme (no external dependencies)
- `content/` — Blog posts (page bundles, bilingual)
- `data/` — Structured content (projects, experience, tech stack)
- `i18n/` — EN/ES translations
- `static/css/style.css` — Single CSS file, dark luxury aesthetic

## Local Development

```bash
hugo server -D
```

## License

MIT
