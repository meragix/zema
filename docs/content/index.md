---
seo:
  title: Authyra | Authentication Framework for Dart & Flutter
  description: Type-safe, modular authentication for Dart and Flutter. Pure Dart core, OAuth2 with PKCE, multi-account sessions, and reactive state — no black-box SDK.
---

::u-page-hero
#title
Auth done right. [No black box.]{.text-primary}

#description
Authyra is a modular authentication framework for Dart and Flutter. A pure Dart core you can unit-test anywhere, OAuth2 providers you wire in one call, and a reactive `Stream<AuthState>` that plugs into any UI framework.

#links
  :::u-button
  ---
  color: neutral
  size: xl
  to: /getting-started/installation
  trailing-icon: i-lucide-arrow-right
  ---
  Get started
  :::

  :::u-button
  ---
  color: neutral
  icon: simple-icons-github
  size: xl
  to: https://github.com/meragix/authyra
  variant: outline
  ---
  Star on GitHub
  :::
::

::u-page-section
#title
Built for developers who own their auth

#features
  :::u-page-feature
  ---
  icon: i-lucide-box
  ---
  #title
  [Pure Dart]{.text-primary} core

  #description
  Zero Flutter dependency in `authyra`. Run the same auth logic in your mobile app, a Dart Frog backend, and a CLI tool — with a single `dart test` for all of it.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-plug
  ---

  #title
  [Pluggable]{.text-primary} everywhere

  #description
  `AuthProvider` and `AuthStorage` are interfaces. Swap Google for SAML, `flutter_secure_storage` for Redis, or mock everything in tests — no subclasses required.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-users-round
  ---
  #title
  [Multi-account]{.text-primary} built in

  #description
  `AccountManager` ships in the core — not as an add-on. Switch between work and personal accounts, sign out selectively, and clean expired sessions in one call.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-refresh-cw
  ---
  #title
  Silent [token refresh]{.text-primary}

  #description
  Providers that set `supportsRefresh: true` get automatic background renewal. When the refresh token expires, the session is cleared and `authStateChanges` emits — no surprises.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-shield-check
  ---

  #title
  OAuth2 with [PKCE]{.text-primary}

  #description
  `OAuth2Provider` (in `authyra_flutter`) implements the full Authorization Code + PKCE flow. Prebuilt providers for Google, GitHub, Apple, and a proxy mode for keeping client secrets server-side.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-code-2
  ---
  #title
  [Reactive]{.text-primary} by default

  #description
  `authStateChanges` is a broadcast `Stream<AuthState>` with `Equatable` deduplication. Wire it to `StreamBuilder`, Riverpod, Bloc, or GoRouter — zero boilerplate.
  :::
::
