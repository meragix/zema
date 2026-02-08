import { themes as prismThemes } from "prism-react-renderer";
import type { Config } from "@docusaurus/types";
import type * as Preset from "@docusaurus/preset-classic";

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: "Zema",
  tagline: "Schema-first validation for Dart & Flutter",
  favicon: "img/favicon.ico",

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // GitHub Pages deployment config
  url: "https://meragix.github.io",
  baseUrl: "/zema/",

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: "meragix",
  projectName: "zema",

  onBrokenLinks: "throw",

  i18n: {
    defaultLocale: "en",
    locales: ["en"],
  },

  presets: [
    [
      "classic",
      {
        docs: {
          sidebarPath: "./sidebars.ts",
          editUrl: "https://github.com/your-org/zema/tree/main/docs-site/",
          showLastUpdateAuthor: true,
          showLastUpdateTime: true,
        },
        blog: {
          showReadingTime: true,
          feedOptions: {
            type: ["rss", "atom"],
            xslt: true,
          },
          editUrl: "https://github.com/your-org/zema/tree/main/docs-site/",
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
        {
          to: "/docs/plugins/overview",
          label: "Plugins",
          position: "left",
        },
        {
          to: "/blog",
          label: "Blog",
          position: "left",
        },
        {
          href: "https://pub.dev/packages/zema",
          label: "pub.dev",
          position: "right",
        },
        {
          href: "https://github.com/meragix/zema",
          label: "GitHub",
          position: "right",
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
      copyright: `Copyright © ${new Date().getFullYear()} Meragix. Built with Docusaurus.`,
    },

    // Prism syntax highlighting
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      //additionalLanguages: ["dart", "yaml", "json", "bash"],
    },

    // Announcement bar
    announcementBar: {
      id: "support_us",
      content:
        '⭐️ If you like Zema, give it a star on <a target="_blank" rel="noopener noreferrer" href="https://github.com/meragix/zema">GitHub</a>!',
      backgroundColor: "#fafbfc",
      textColor: "#091E42",
      isCloseable: false,
    },
  } satisfies Preset.ThemeConfig,

  // Plugins supplémentaires
  plugins: [
    [
      "@docusaurus/plugin-content-docs",
      {
        id: "examples",
        path: "examples",
        routeBasePath: "examples",
        sidebarPath: "./sidebarsExamples.js",
      },
    ],
  ],
};

export default config;
