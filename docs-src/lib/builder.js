/* eslint-disable no-console */

const metalsmith = require('metalsmith');
const config = require('../config.js');
const path = require('path');

module.exports = function builder({ clean = true, middlewares }, cb) {
  console.time('metalsmith build');
  // default source directory ./src
  // https://github.com/metalsmith/metalsmith#sourcepath
  metalsmith(path.join(__dirname, '..'))
    .metadata(config)
    .clean(clean)
    .destination(config.docsDist)
    .use(middlewares)
    .build(err => {
      console.timeEnd('metalsmith build');
      cb(err);
    });
};
