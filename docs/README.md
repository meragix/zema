# Authyra Documentation

This directory contains the Nuxt.js + Docus documentation site for Authyra.

**Live site**: [meragix.github.io/authyra](https://meragix.github.io/authyra)

Deployed automatically to GitHub Pages on every push to `main` that touches the `docs/` directory.

---

## Packages documented

| Package | Description |
|---|---|
| [`authyra`](https://pub.dev/packages/authyra) | Core framework — pure Dart, zero Flutter dependency |
| [`authyra_flutter`](https://pub.dev/packages/authyra_flutter) | Flutter layer — OAuth2 providers, `SecureAuthStorage`, widgets, GoRouter guard |

`authyra_flutter` re-exports the entire `authyra` package — Flutter apps only need one import.

---

## Two-package architecture

```text
authyra (pure Dart)
├── AuthyraClient          ← stateless orchestrator (injectable, testable)
├── AuthyraInstance        ← singleton wrapper (reactive streams + sync cache)
├── AuthProvider           ← interface for any auth strategy
├── AuthStorage            ← interface for any persistence backend
├── CredentialsProvider    ← email/password, any form-based flow
├── SessionManager         ← multi-account session registry
└── AccountManager         ← switch, sign out, clean sessions

authyra_flutter (Flutter + re-exports authyra)
├── OAuth2Provider         ← Authorization Code + PKCE (any IdP)
├── GoogleProvider         ← prebuilt Google Sign-In
├── GitHubOAuth2Provider   ← prebuilt GitHub OAuth
├── AppleProvider          ← Sign in with Apple
├── ProxyOAuthProvider     ← backend-delegated OAuth (secret stays server-side)
├── SecureAuthStorage      ← flutter_secure_storage implementation
└── OAuth2CallbackHandler  ← deep-link router for OAuth redirects
```

**Design rule**: everything that touches Flutter platform APIs, `url_launcher`, or platform channels lives in `authyra_flutter`. The core is pure Dart.

---

## Running locally

```bash
cd docs
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

---

## Content

All documentation lives in `content/`. Numeric prefixes on directories and files control navigation order (e.g., `1.getting-started/`, `2.core-concepts/`).

See [`content/doc`](content/doc) for the full content tree and per-page descriptions.
