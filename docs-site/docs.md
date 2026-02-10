# Zema Documentation

Welcome to the official documentation for Zema, the powerful schema validation library for Dart. Whether you're new to Zema or looking to deepen your understanding, this guide will walk you through everything you need to know to get started and master Zema's features.

## Table of Contents

- [Getting Started](getting-started/overview.md)
  - [Installation](getting-started/installation.md)
  - [Quick Start Guide](getting-started/quick-start.md)
  - [Core Concepts](getting-started/core-concepts.md)
  - [Why Zema?](getting-started/why-zema.md)
- [Core Concepts](core/overview.md)
  - [Schemas](core/schemas/overview.md)
  - [Validation](core/validation/overview.md)
  - [Extension Types](core/extension-types/overview.md)
  - [Transformations](core/transformations/overview.md)
  - [Composition](core/composition/overview.md)
  - [Advanced Topics](core/advanced/overview.md)
- [Plugins](plugins/overview.md)
  - [zema_http](plugins/zema_http/overview.md)
  - [zema_form](plugins/zema_form/overview.md)
  - [zema_hive](plugins/zema_hive/overview.md)
  - [zema_firestore](plugins/zema_firestore/overview.md)
  - [zema_riverpod](plugins/zema_riverpod/overview.md)
- [Migration Guides](migration/overview.md)
- [Real-World Examples](examples/overview.md)
- [API Reference](api/overview.md)

---

## Final structure of the docs-site

zema/
├── packages/
│   ├── zema/
│   ├── zema_http/
│   ├── zema_form/
│   ├── zema_hive/
│   ├── zema_shared_preferences/
│   ├── zema_firestore/
│   └── zema_riverpod/
│
├── docs-site/                              # 🆕 Site Docusaurus
│   ├── docs/
│   │   ├── getting-started/
│   │   ├── core/
│   │   ├── plugins/
│   │   ├── recipes/
│   │   └── migration/
│   ├── blog/
│   ├── src/
│   │   ├── components/
│   │   ├── css/
│   │   └── pages/
│   ├── static/
│   │   ├── img/
│   │   └── code-examples/
│   ├── docusaurus.config.js
│   ├── sidebars.js
│   ├── package.json
│   └── README.md
│
├── examples/
├── melos.yaml
└── README.md

## Core Concepts

docs-site/docs/
├── getting-started/
│   ├── installation.md
│   ├── quick-start.md
│   ├── core-concepts.md
│   └── why-zema.md
│
├── core/
│   ├── overview.md
│   │
│   ├── schemas/
│   │   ├── primitives.md          # string, number, boolean, date
│   │   ├── arrays.md              # z.array()
│   │   ├── objects.md             # z.object()
│   │   ├── enums.md               # z.enum(), z.union()
│   │   ├── optional-nullable.md   # .optional(), .nullable()
│   │   ├── refinements.md         # .refine(), custom validation
│   │   └── custom-types.md        # z.custom()
│   │
│   ├── validation/
│   │   ├── basic-validation.md    # parse(), safeParse()
│   │   ├── error-handling.md      # ZemaResult, ZemaIssue
│   │   ├── custom-validators.md   # Custom validation logic
│   │   └── async-validation.md    # refineAsync()
│   │
│   ├── extension-types/
│   │   ├── what-are-extension-types.md
│   │   ├── creating-extension-types.md
│   │   ├── vs-classes.md
│   │   └── best-practices.md
│   │
│   ├── transformations/
│   │   ├── transforms.md          # .transform()
│   │   ├── preprocess.md          # .preprocess()
│   │   └── coercion.md            # Type coercion
│   │
│   ├── composition/
│   │   ├── merging-schemas.md     # .merge(), .extend()
│   │   ├── picking-omitting.md    # .pick(), .omit()
│   │   └── discriminated-unions.md
│   │
│   └── advanced/
│       ├── lazy-schemas.md        # z.lazy() for recursive
│       ├── branded-types.md       # Brand types
│       └── performance.md         # Optimization tips