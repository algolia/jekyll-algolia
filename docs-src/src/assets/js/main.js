import {
  repositionSidebarOnScroll,
  updateReadLinkOnScroll,
} from './sidebar.js';
import activateClipboard from './activateClipboard.js';
import alg from 'algolia-frontend-components/javascripts.js';
import './editThisPage.js';
import { freezeAllGifs } from './freezeGifs.js';

const docSearch = {
  apiKey: '5e2de32b362723ffdb03414c5c3d2ec8',
  indexName: 'jekyll_algolia',
  inputSelector: '#searchbox'
};


document.querySelector('#searchbox').addEventListener('focus', function (e) {
  document.querySelector('.algolia-autocomplete').classList.add('opened')
});
document.querySelector('#searchbox').addEventListener('blur', function (e) {
  document.querySelector('.algolia-autocomplete').classList.remove('opened')
});
window.addEventListener('autocomplete:opened', function (e) {
  document.querySelector('.algolia-autocomplete').classList.add('opened')
});


/* eslint-disable no-unused-vars */
/* eslint-disable new-cap */
const header = new alg.communityHeader(docSearch);

const container = document.querySelector('.documentation-container');
const codeSamples = document.querySelectorAll('.code-sample');

activateClipboard(codeSamples);
freezeAllGifs();

const myImgs = document.querySelectorAll('.animate-me');

const observer = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.intersectionRatio > 0) {
      [...myImgs].forEach(visual => {
        visual.classList.add('animate')
      })
    } else {
      [...myImgs].forEach(visual => {
        visual.classList.remove('animate')
      })
    }
  });
});

myImgs.forEach(image => {
  observer.observe(image);
});

if (document.querySelector('.sidebar')) {
  repositionSidebarOnScroll();
  updateReadLinkOnScroll();
}
