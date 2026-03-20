---
seo:
  title: Zema | Schema Validation for Dart
  description: Type-safe schema validation for Dart and Flutter. Define schemas once, collect all errors in a single pass, and validate anywhere.
---

::u-page-hero
#title
Schema validation for Dart. [Define once, validate anywhere.]{.text-primary}

#description
Zema is a schema validation library for Dart inspired by Zod. A fluent chainable API, exhaustive error collection, and a sealed result type that never throws unless you want it to.

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
  to: "https://github.com/meragix/zema"
  variant: outline
  ---
  Star on GitHub
  :::
::

::u-page-section
#title
Everything you need to validate data in Dart

#features
  :::u-page-feature
  ---
  icon: i-lucide-layers
  ---
  #title
  [Fluent]{.text-primary} chainable API

  #description
  Build schemas by chaining constraints: `z.string().min(2).email()`. Every method returns a new immutable schema instance: no mutation, no side effects.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-list-checks
  ---
  #title
  [Exhaustive]{.text-primary} error collection

  #description
  Every failing field is reported in a single parse call. No silent failures, no early exits. Each issue carries a code, a human-readable message, and a path to the exact location in the input.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-shield
  ---
  #title
  [Sealed]{.text-primary} result type

  #description
  `safeParse()` returns `ZemaSuccess<T>` or `ZemaFailure<T>`, never throws. Use Dart 3 pattern matching to handle both cases. Call `parse()` when you prefer an exception on failure.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-blocks
  ---
  #title
  [Composable]{.text-primary} object schemas

  #description
  Build complex schemas from simple ones. `extend()`, `merge()`, `pick()`, and `omit()` let you derive new schemas from existing ones without repetition.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-zap
  ---
  #title
  [Discriminated]{.text-primary} unions

  #description
  `discriminatedBy()` selects the matching schema directly from a literal field, O(1) instead of a linear scan. No unnecessary validation of non-matching schemas.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-repeat
  ---
  #title
  [Coercion]{.text-primary} for raw inputs

  #description
  `z.coerce()` converts strings from environment variables, query parameters, and form inputs into the correct Dart type before validation runs.
  :::
::
