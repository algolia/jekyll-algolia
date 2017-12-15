import _ from 'lodash';

export function repositionSidebarOnScroll() {
  const documentationContainer = document.querySelector(
    '.documentation-container'
  );
  const sidebar = document.querySelector('.sidebar');
  const headerHeight = document
    .querySelector('.algc-navigation')
    .getBoundingClientRect().height;

  // Reposition the sidebar if we scroll down too far so it does not bleed on
  // the footer
  function __repositionSidebar() {
    const boundingBox = documentationContainer.getBoundingClientRect();
    const scrollFromTop = window.pageYOffset;
    const visibleArea = window.innerHeight - headerHeight;
    const documentationContentHeight = boundingBox.height;
    const lowerBoundary = documentationContentHeight - visibleArea;

    // When we scroll too far below, we fix the position of the sidebar
    if (scrollFromTop >= lowerBoundary) {
      sidebar.classList.remove('sidebar_fixed');
      sidebar.classList.add('sidebar_absolute');
      return;
    }

    sidebar.classList.remove('sidebar_absolute');
    sidebar.classList.add('sidebar_fixed');
  }

  window.addEventListener('load', __repositionSidebar);
  document.addEventListener('DOMContentLoaded', __repositionSidebar);
  document.addEventListener('scroll', __repositionSidebar);
}


// Mark with an active class the subchild that is currently being read
export function updateReadLinkOnScroll() {
  const links = document.querySelectorAll('.sidebar ul ul a');
  const titles = document.querySelectorAll('.documentation-container h2');
  const headerHeight = document
    .querySelector('.algc-navigation')
    .getBoundingClientRect().height;

  function __updateReadLinkOnScroll() {
    // Finding the current read title
    let currentTitle = titles[0];
    _.each(titles, title => {
      const boundingBox = title.getBoundingClientRect();
      const titleHeight = boundingBox.height;
      const titleTop = boundingBox.top;
      const visibleArea = window.innerHeight - headerHeight;
      if (titleTop < headerHeight + titleHeight) currentTitle = title;
      if (titleTop >= visibleArea + titleHeight) return;
    });

    // Marking active the link that matches this header
    let anchor = currentTitle.getAttribute('id');
    _.each(links, link => {
      link.classList.remove('sidebar-element_active');
      if (_.includes(link.getAttribute('href'), anchor)) {
        link.classList.add('sidebar-element_active');
      }
    });
  }

  window.addEventListener('load', __updateReadLinkOnScroll);
  document.addEventListener('DOMContentLoaded', __updateReadLinkOnScroll);
  document.addEventListener('scroll', __updateReadLinkOnScroll);
}
