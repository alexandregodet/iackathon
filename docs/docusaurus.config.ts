import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'IAckathon',
  tagline: 'Assistant IA local propulse par Gemma',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: 'https://iackathon.github.io',
  baseUrl: '/',

  organizationName: 'iackathon',
  projectName: 'iackathon',

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'fr',
    locales: ['fr'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/iackathon-social-card.png',
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'IAckathon',
      logo: {
        alt: 'IAckathon Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'userSidebar',
          position: 'left',
          label: 'Guide Utilisateur',
        },
        {
          type: 'docSidebar',
          sidebarId: 'devSidebar',
          position: 'left',
          label: 'Documentation Technique',
        },
        {
          href: 'https://github.com/iackathon/iackathon',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Guide Utilisateur',
              to: '/user-guide/introduction',
            },
            {
              label: 'Documentation Technique',
              to: '/developer/architecture',
            },
          ],
        },
        {
          title: 'Ressources',
          items: [
            {
              label: 'Flutter',
              href: 'https://flutter.dev',
            },
            {
              label: 'Google Gemma',
              href: 'https://ai.google.dev/gemma',
            },
          ],
        },
        {
          title: 'Projet',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/iackathon/iackathon',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} IAckathon. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['dart', 'yaml', 'bash'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
