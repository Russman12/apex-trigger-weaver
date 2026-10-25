import { defineConfig } from 'vitepress';
import * as sidebar from './sidebar.json';

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Apex Trigger Weaver",
  description: "Take control of your triggers",
  // render raw HTML as text so Apex generics like List<SObject> aren't parsed as Vue tags
  markdown: {
    html: false
  },
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Getting Started', link: '/getting-started' }
    ],

    sidebar: sidebar.default,

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Russman12/apex-trigger-weaver' }
    ]
  }
})
