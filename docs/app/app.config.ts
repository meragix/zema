export default defineAppConfig({
   header: {
    title: 'Zema',
    logo: {
      light: '/logo/logo-dark.svg',
      dark: '/logo/logo-light.svg',
      alt: 'Zema Logo',
      // wordmark: {
      //   light: '/logo/wordmark-dark.png',
      //   dark: '/logo/wordmark-light.png',
      // },
      favicon: '/favicon.ico',
    },
  },
  socials: {
    x: 'https://x.com/meragix',
    github: 'https://github.com/meragix/zema',
  },
  ui: {
    colors: {
      primary: 'blue',
      neutral: 'zinc'
    }
  },
})
