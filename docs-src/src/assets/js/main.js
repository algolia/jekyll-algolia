import {
  repositionSidebarOnScroll,
  updateReadLinkOnScroll,
} from './sidebar.js';
import activateClipboard from './activateClipboard.js';
import alg from 'algolia-frontend-components/javascripts.js';
import './editThisPage.js';

const docSearch = {
  apiKey: '5e2de32b362723ffdb03414c5c3d2ec8',
  indexName: 'jekyll_algolia',
  inputSelector: '#searchbox',
};

/* eslint-disable no-unused-vars */
/* eslint-disable new-cap */
const header = new alg.communityHeader(docSearch);

const container = document.querySelector('.documentation-container');
const codeSamples = document.querySelectorAll('.code-sample');

activateClipboard(codeSamples);

if (document.querySelector('.sidebar')) {
  repositionSidebarOnScroll();
  updateReadLinkOnScroll();
}
