import type { SidebarsConfig } from "@docusaurus/plugin-content-docs";

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */
const sidebars: SidebarsConfig = {
  tutorialSidebar: [
    {
      type: "category",
      label: "Getting Started",
      collapsed: false,
      items: [
        // "getting-started/installation",
        // "getting-started/quick-start",
        // "getting-started/core-concepts",
      ],
    },
    {
      type: "category",
      label: "Core",
      items: [
        // "core/overview",
        // {
        //   type: "category",
        //   label: "Schemas",
        //   items: [
        //     "core/schemas/primitives",
        //     "core/schemas/arrays",
        //     "core/schemas/objects",
        //     "core/schemas/enums",
        //     "core/schemas/unions",
        //     "core/schemas/custom-types",
        //   ],
        // },
        // {
        //   type: "category",
        //   label: "Validation",
        //   items: [
        //     "core/validation/basic-validation",
        //     "core/validation/custom-validators",
        //     "core/validation/async-validation",
        //     "core/validation/error-handling",
        //   ],
        // },
        // {
        //   type: "category",
        //   label: "Extension Types",
        //   items: [
        //     "core/extension-types/what-are-extension-types",
        //     "core/extension-types/creating-extension-types",
        //     "core/extension-types/best-practices",
        //   ],
        // },
        // {
        //   type: "category",
        //   label: "Advanced",
        //   items: [
        //     "core/advanced/transforms",
        //     "core/advanced/refinements",
        //     "core/advanced/composition",
        //   ],
        // },
      ],
    },
    {
      type: "category",
      label: "Plugins",
      items: [
        // "plugins/overview",
        {
          type: "category",
          label: "flutter_zema (Comming Soon)",
          items: [
            // "plugins/flutter_zema/overview",
            // "plugins/flutter_zema/installation",
            // "plugins/flutter_zema/quick-start",
            // {
            //   type: "category",
            //   label: "Guides",
            //   items: [
            //     "plugins/flutter_zema/guides/basic-forms",
            //     "plugins/flutter_zema/guides/validation-modes",
            //     "plugins/flutter_zema/guides/dynamic-arrays",
            //     "plugins/flutter_zema/guides/cross-field-validation",
            //     "plugins/flutter_zema/guides/async-validation",
            //   ],
            // },
          ],
        },
        // {
        //   type: "category",
        //   label: "zema_fetch (Comming Soon)",
        //   items: [
        //     "plugins/zema_fetch/overview",
        //     "plugins/zema_fetch/installation",
        //     "plugins/zema_fetch/quick-start",
        //     {
        //       type: "category",
        //       label: "Guides",
        //       items: [
        //         "plugins/zema_fetch/guides/basic-usage",
        //         "plugins/zema_fetch/guides/error-handling",
        //         "plugins/zema_fetch/guides/retry-logic",
        //         "plugins/zema_fetch/guides/tree-shaking",
        //       ],
        //     },
        //     {
        //       type: "category",
        //       label: "API Reference",
        //       items: [
        //         "plugins/zema_fetch/api/extensions",
        //         "plugins/zema_fetch/api/exceptions",
        //         "plugins/zema_fetch/api/interceptors",
        //       ],
        //     },
        //     {
        //       type: "category",
        //       label: "Examples",
        //       items: [
        //         "plugins/zema_fetch/examples/http-client",
        //         "plugins/zema_fetch/examples/dio-client",
        //         "plugins/zema_fetch/examples/chopper-client",
        //         "plugins/zema_fetch/examples/repository-pattern",
        //       ],
        //     },
        //   ],
        // },
        // {
        //   type: "category",
        //   label: "zema_hive",
        //   items: [
        //     "plugins/zema_hive/overview",
        //     "plugins/zema_hive/quick-start",
        //     {
        //       type: "category",
        //       label: "Guides",
        //       items: [
        //         "plugins/zema_hive/guides/basic-usage",
        //         "plugins/zema_hive/guides/migrations",
        //         "plugins/zema_hive/guides/versioning",
        //       ],
        //     },
        //   ],
        // },
        // {
        //   type: "category",
        //   label: "zema_shared_preferences",
        //   items: [
        //     "plugins/zema_shared_preferences/overview",
        //     "plugins/zema_shared_preferences/quick-start",
        //     {
        //       type: "category",
        //       label: "Guides",
        //       items: [
        //         "plugins/zema_shared_preferences/guides/reactive-settings",
        //         "plugins/zema_shared_preferences/guides/theme-management",
        //       ],
        //     },
        //   ],
        // },
        // {
        //   type: "category",
        //   label: "zema_firestore",
        //   items: [
        //     "plugins/zema_firestore/overview",
        //     "plugins/zema_firestore/quick-start",
        //   ],
        // },
        // {
        //   type: "category",
        //   label: "zema_riverpod",
        //   items: [
        //     "plugins/zema_riverpod/overview",
        //     "plugins/zema_riverpod/quick-start",
        //   ],
        // },
      ],
    },
    {
      type: "category",
      label: "Recipes",
      items: [
        // {
        //   type: "category",
        //   label: "Architecture",
        //   items: [
        //     "recipes/architecture/repository-pattern",
        //     "recipes/architecture/clean-architecture",
        //     "recipes/architecture/mvvm-pattern",
        //   ],
        // },
        // {
        //   type: "category",
        //   label: "Common Patterns",
        //   items: [
        //     "recipes/common-patterns/api-client",
        //     "recipes/common-patterns/offline-first",
        //     "recipes/common-patterns/caching-strategy",
        //   ],
        // },
        // {
        //   type: "category",
        //   label: "Real-World Apps",
        //   items: [
        //     "recipes/real-world-apps/todo-app",
        //     "recipes/real-world-apps/e-commerce",
        //   ],
        // },
      ],
    },
    {
      type: "category",
      label: "Migration",
      items: [
        // "migration/overview",
        // "migration/from-freezed",
        // "migration/from-json-serializable",
      ],
    },
    {
      type: "category",
      label: "Comparison",
      items: [
        // "comparison/vs-freezed",
        // "comparison/vs-json-serializable",
        // "comparison/vs-formz",
      ],
    },
    {
      type: "category",
      label: "Troubleshooting",
      items: [
        // "troubleshooting/common-errors",
        // "troubleshooting/performance-tips",
        // "troubleshooting/debugging",
      ],
    },
  ],
};

export default sidebars;
