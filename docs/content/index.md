---
seo:
  title: Zema | Validate untrusted data in Dart and Flutter
  description: Zod-style schema validation for Dart and Flutter. One schema for API responses, forms, Firestore and Hive. Every error in one pass, translated messages, typed results, no build_runner.
---

::u-page-hero
#title
Validate untrusted data in Dart and Flutter. [One schema, every boundary.]{.text-primary}

#description
Describe the data you expect once. Zema checks API responses, form input, Firestore documents and local storage against it, reports every problem with its path and a translated message, and hands you clean, typed values. Pure Dart, works on mobile, desktop, web and server. No code generation.

#links
  :::u-button
  ---
  color: neutral
  size: xl
  to: /getting-started/quick-start
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

  :::u-button
  ---
  color: neutral
  icon: simple-icons-dart
  size: xl
  to: "https://pub.dev/packages/zema"
  variant: ghost
  ---
  pub.dev
  :::
::

::u-page-section
#title
From `fromJson` crashes to useful errors

#description
`User.fromJson(json)` throws a `TypeError` on the first unexpected field, far from where the data came in, with nothing to show the user. A Zema schema reports everything at once:

#default
```dart
final signUp = z.object({
  'email': z.string().email(),
  'password': z.string().min(8),
  'age': z.integer().gte(18).optional(),
});

final result = signUp.safeParse({'email': 'ada@', 'password': '123'});

for (final issue in result.errors) {
  print('${issue.pathString}: ${issue.message}');
}
// email: Invalid email format
// password: Must be at least 8 characters
```
::

::u-page-section
#title
Built for the places where Dart apps break

#features
  :::u-page-feature
  ---
  icon: i-lucide-cloud-download
  to: /getting-started/quick-start
  ---
  #title
  [API responses]{.text-primary}

  #description
  Validate JSON before it reaches your models. Get typed values with `z.objectAs` and an extension type, or pass the clean map to your Freezed / json_serializable `fromJson`.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-text-cursor-input
  to: /plugins/zema_forms
  ---
  #title
  [Flutter forms]{.text-primary}

  #description
  `zema_forms` drives text fields from the same schema: errors after blur, per-field rebuilds, focus on the first invalid field, coercion for numeric inputs.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-flame
  to: /plugins/zema_firestore
  ---
  #title
  [Firestore]{.text-primary}

  #description
  `zema_firestore` plugs into `withConverter`: every document read is validated, with `Timestamp`, `GeoPoint` and `DocumentReference` schemas. Supports `cloud_firestore` 5 to 7.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-hard-drive
  to: /plugins/zema_hive
  ---
  #title
  [Local storage]{.text-primary}

  #description
  `zema_hive` validates Hive CE writes and reads, and migrates documents written by older app versions on read. No TypeAdapters, no code generation.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-languages
  to: /core/validation/error-handling
  ---
  #title
  [Messages for humans]{.text-primary}

  #description
  Each issue carries a code, a path such as `items.[2].email` and a translated message. English and French built in, add any locale, override any message.
  :::

  :::u-page-feature
  ---
  icon: i-lucide-code
  to: /getting-started/coming-from-zod
  ---
  #title
  [Feels like Zod]{.text-primary}

  #description
  `z.object`, `safeParse`, `refine`, `transform`, `pipe`, discriminated unions, coercion. If you know Zod from TypeScript, you already know Zema.
  :::
::

::u-page-section
#title
Why not just Freezed or json_serializable?

#description
They generate models; they do not check values. `email` is a `String`, not a valid email. `age` is an `int`, not "18 or more". Zema covers that layer and composes with them, or replaces code generation entirely with extension types. [Read the full comparison](/getting-started/why-zema).
::
