import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  userSidebar: [
    {
      type: 'category',
      label: 'Guide Utilisateur',
      collapsed: false,
      items: [
        'user-guide/introduction',
        'user-guide/installation',
        'user-guide/first-steps',
        'user-guide/models',
        'user-guide/chat',
        'user-guide/documents',
        'user-guide/templates',
        'user-guide/settings',
        'user-guide/faq',
      ],
    },
  ],
  devSidebar: [
    {
      type: 'category',
      label: 'Architecture',
      collapsed: false,
      items: [
        'developer/architecture',
        'developer/project-structure',
        'developer/clean-architecture',
      ],
    },
    {
      type: 'category',
      label: 'Composants',
      collapsed: false,
      items: [
        'developer/gemma-service',
        'developer/rag-service',
        'developer/database',
        'developer/bloc-pattern',
        'developer/dependency-injection',
      ],
    },
    {
      type: 'category',
      label: 'Developpement',
      collapsed: false,
      items: [
        'developer/setup',
        'developer/building',
        'developer/testing',
        'developer/contributing',
      ],
    },
    {
      type: 'category',
      label: 'API Reference',
      collapsed: true,
      items: [
        'developer/api/gemma-service-api',
        'developer/api/rag-service-api',
        'developer/api/chat-bloc-api',
      ],
    },
  ],
};

export default sidebars;
