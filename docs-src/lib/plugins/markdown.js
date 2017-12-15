/* eslint-disable no-param-reassign */
const path = require('path');
const _ = require('lodash');
const MarkdownIt = require('markdown-it');
const markdownItAnchor = require('markdown-it-anchor');
const highlight = require('./syntaxHighlighting.js');
const md = new MarkdownIt('default', {
  highlight: (str, lang) => highlight(str, lang),
  linkify: true,
  typographer: true,
  html: true,
}).use(markdownItAnchor, {
  permalink: true,
  permalinkClass: 'anchor',
  permalinkSymbol: '',
  // generate proper Getting_started.html#install hrefs since we are
  // using the base href trick to handle different base urls (dev, prod)
  permalinkHref: (slug, state) => `${state.env.path}#${slug}`,
});

const isMarkdown = filepath => /\.md|\.markdown/.test(path.extname(filepath));

module.exports = function markdown(files, metalsmith, done) {
  _.each(files, (data, filepath) => {
    // We keep all non-markdown files as-is
    if (!isMarkdown(filepath)) {
      return;
    }

    // We convert markdown path to html path
    const dirname = path.dirname(filepath);
    let htmlpath = `${path.basename(filepath, path.extname(filepath))}.html`;
    if (dirname !== '.') {
      htmlpath = `${dirname}/${htmlpath}`;
    }

    // We convert the markdown content to HTML
    const content = md.render(data.contents.toString(), { path: htmlpath });

    delete files[filepath];
    files[htmlpath] = {
      ...data,
      contents: new Buffer(content),
    };
  });

  done();
};
