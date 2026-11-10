# Zema documentation site

Source of [zema.meragix.dev](https://zema.meragix.dev), built with [Docus](https://docus.dev) (Nuxt) and deployed to GitHub Pages by [`deploy-docs.yml`](../.github/workflows/deploy-docs.yml) on every push to `main` that touches `docs/`.

## Local development

```bash
cd docs
npm ci
npm run dev     # http://localhost:3000
npm run build   # production build
```

## Structure

| Path | Content |
| --- | --- |
| `content/index.md` | Landing page |
| `content/1.getting-started/` | Why Zema, installation, quick start, core concepts, coming from Zod |
| `content/2.core/` | Schemas, validation, extension types, transformations, composition, advanced |
| `content/3.plugins/` | `zema_forms`, `zema_firestore`, `zema_hive`, `zema_standard_schema` |
| `content/faq.md`, `content/troubleshooting.md` | FAQ and common errors |
| `app/app.config.ts` | Header, logo, social links, colors |

## Code samples

Every ```dart block is compiled against the packages of this repository:

```bash
# from the repository root, after `melos bootstrap`
dart run scripts/check_snippets.dart docs/
```

The READMEs are a blocking CI check; the docs pages are reported in CI and should be kept at zero API errors. Put `<!-- snippet:skip -->` on the line before a fence for pseudo-code, signatures or examples that are meant not to compile.
