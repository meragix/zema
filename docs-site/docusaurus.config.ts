import { themes as prismThemes } from "prism-react-renderer";
import type { Config } from "@docusaurus/types";
import type * as Preset from "@docusaurus/preset-classic";

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: "Zema",
  tagline:
    "Type-safe, composable, and zero-cost abstraction. Designed for high-performance Flutter and Server-side apps.",
  favicon: "img/favicon.ico",

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    // Turns Docusaurus v4 future flags on to make it easier to upgrade later
    v4: true,
    // experimental_faster: true, // Enable experimental optimizations for faster builds
  },

  // GitHub Pages deployment config
  url: "https://meragix.github.io",
  baseUrl: "/zema/",

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: "Meragix",
  projectName: "zema",

  onBrokenLinks: "ignore",

  i18n: {
    defaultLocale: "en",
    locales: ["en"],
  },

  headTags: [
    {
      tagName: "script",
      attributes: {
        type: "application/ld+json",
      },
      innerHTML: JSON.stringify({
        "@context": "https://schema.org/",
        "@type": "WebPage",
        "@id": "https://zema.meragix.dev/",
        url: "https://zema.meragix.dev/",
        name: "Zema - Type-safe validation for Dart and Flutter",
        description:
          "Zema is a Dart package that provides type-safe, composable, and zero-cost validation for Flutter and server-side applications.",
        logo: "https://zema.meragix.dev/img/pwa/manifest-icon-192.png",
        inLanguage: "en-US",
      }),
    },
  ],

  presets: [
    [
      "classic",
      {
        docs: {
          sidebarPath: "./sidebars.ts",
          editUrl: "https://github.com/meragix/zema/tree/main/docs-site/",
          showLastUpdateAuthor: true,
          showLastUpdateTime: true,
        },
        blog: {
          showReadingTime: true,
          feedOptions: {
            type: ["rss", "atom"],
            xslt: true,
          },
          editUrl: "https://github.com/meragix/zema/tree/main/docs-site/",
          onInlineTags: "warn",
          onInlineAuthors: "warn",
          onUntruncatedBlogPosts: "warn",
        },
        theme: {
          customCss: "./src/css/custom.css",
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: "img/zema-social-card.jpg",
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: "Zema",
      // logo: {
      //   alt: "Zema Logo",
      //   src: "img/logo.svg",
      // },
      items: [
        {
          type: "docSidebar",
          sidebarId: "tutorialSidebar",
          position: "left",
          label: "Docs",
        },
        // {
        //   to: "/docs/plugins/overview",
        //   label: "Plugins",
        //   position: "left",
        // },
        // {
        //   to: "/blog",
        //   label: "Blog",
        //   position: "left",
        // },
        {
          href: "https://pub.dev/packages/zema",
          className: "header-pubdev-link",
          "aria-label": "Pub.dev registry",
          position: "right",
          title: "Zema on Pub.dev",
        },
        {
          href: "https://github.com/meragix/zema",
          className: "header-github-link",
          "aria-label": "GitHub repository",
          position: "right",
          title: "Zema on GitHub",
        },
      ],
    },

    // Footer
    footer: {
      style: "dark",
      links: [
        {
          title: "Docs",
          items: [
            {
              label: "Getting Started",
              to: "/docs/getting-started/installation",
            },
            {
              label: "Core Concepts",
              to: "/docs/core/overview",
            },
            {
              label: "Plugins",
              to: "/docs/plugins/overview",
            },
          ],
        },
        {
          title: "Community",
          items: [
            {
              label: "Discord",
              href: "https://discord.gg/meragix",
            },
            {
              label: "Twitter",
              href: "https://x.com/meragix",
            },
            {
              label: "GitHub Discussions",
              href: "https://github.com/meragix/zema/discussions",
            },
          ],
        },
        {
          title: "More",
          items: [
            {
              label: "Blog",
              to: "/blog",
            },
            {
              label: "GitHub",
              href: "https://github.com/meragix/zema",
            },
            {
              label: "pub.dev",
              href: "https://pub.dev/packages/zema",
            },
          ],
        },
      ],
      copyright: `
  <div class="footer__custom">
    <div class="footer__brand">
      <strong>Zema</strong> by <a href="https://meragix.dev" target="_blank" rel="noopener noreferrer">Meragix</a>
    </div>
    <div class="footer__copy">
      Copyright © ${new Date().getFullYear()} — Built with passion for the Dart ecosystem.
    </div>
  </div>
`,
    },

    // Prism syntax highlighting
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ["dart", "yaml", "json", "bash"],
    },

    // Announcement bar
    // announcementBar: {
    //   id: "support_us",
    //   content:
    //     '⭐️ If you like Zema, give it a star on <a target="_blank" rel="noopener noreferrer" href="https://github.com/meragix/zema">GitHub</a>!',
    //   backgroundColor: "#fafbfc",
    //   textColor: "#091E42",
    //   isCloseable: false,
    // },
  } satisfies Preset.ThemeConfig,

  // Plugins supplémentaires
  // plugins: [
  //   [
  //     "@docusaurus/plugin-content-docs",
  //     {
  //       id: "examples",
  //       path: "examples",
  //       routeBasePath: "examples",
  //       sidebarPath: "./sidebarsExamples.js",
  //     },
  //   ],
  // ],
};

export default config;
