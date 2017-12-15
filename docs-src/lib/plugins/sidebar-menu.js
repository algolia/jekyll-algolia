/* eslint-disable no-param-reassign */
const _ = require('lodash');
const config = require('../../config');

module.exports = function() {
  // All the pages accessible from the menu
  let pagesInMenu = [];
  _.each(config.sidebarMenu, category => {
    pagesInMenu = _.concat(pagesInMenu, _.map(category.items, 'url'));
  });
  return function(files, metalsmith, done) {
    _.each(files, (data, path) => {
      // Skip files that are not in the menu, they don't need a menu
      if (!_.includes(pagesInMenu, path)) {
        return;
      }

      // Overriding the global sidebarMenu var with one with more info on
      // subchild
      const sidebarMenu = _.cloneDeep(config.sidebarMenu);
      _.each(sidebarMenu, category => {
        _.each(category.items, item => {
          // Looping until we find the menu entry
          if (item.url !== path) return;

          item.isActive = true;

          // Adding a subchild entry
          item.items = _.map(data.headings, heading => ({
            title: heading.text,
            url: `${path}#${heading.id}`,
          }));
        });
      });

      data.sidebarMenu = sidebarMenu;
    });
    done();
  };
};
