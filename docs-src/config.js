const fs = require('fs');
const path = require('path');
const algoliaComponents = require('algolia-frontend-components');
const headerData = require('./src/data/communityHeader.json');

function readFile(filepath) {
  return fs.readFileSync(path.join(__dirname, filepath), 'utf8').toString();
}

const header = algoliaComponents.communityHeader(headerData, {
  algoliaLogo: readFile('src/assets/images/algolia-logo-whitebg.svg'),
  communityLogo: readFile('src/assets/images/algolia-community-dark.svg'),
});

const environmentConfig = {
  production: {
    docsDist: path.join(__dirname, '..', 'docs'),
  },
  development: {
    docsDist: path.join(__dirname, '..', 'docs-dev'),
  },
};

const sidebarMenu = [
  {
    title: 'Essentials',
    items: [
      { title: 'Getting Started', url: 'getting-started.html' },
      { title: 'How it works', url: 'how-it-works.html' },
    ],
  },
  {
    title: 'Configuration',
    items: [
      { title: 'Options', url: 'options.html' },
      { title: 'Commandline', url: 'commandline.html' },
      { title: 'Hooks', url: 'hooks.html' },
    ],
  },
  {
    title: 'Advanced',
    items: [
      { title: 'Github Pages', url: 'github-pages.html' },
      { title: 'Netlify', url: 'netlify.html' },
      { title: 'Travis', url: 'travis.html' },
    ],
  },
  {
    title: 'Examples',
    items: [
      { title: 'Autocomplete', url: 'autocomplete.html' },
      { title: 'InstantSearch', url: 'instantsearch.html' },
    ],
  },
];

module.exports = {
  ...environmentConfig[process.env.NODE_ENV],
  publicPath: process.env.ROOT_PATH || '/',
  header,
  sidebarMenu
};
