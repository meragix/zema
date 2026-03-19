export default defineNuxtConfig({
  extends: ['docus'],
  site: {
    name: 'Zema',
  },
  compatibilityDate: '2025-07-18',
  content: {
    build: {
      markdown: {
        highlight: {
          langs: [
            'dart',
            'mermaid',
          ]
        }
      }
    }
  }
})