if (document.querySelector('.documentation-container')) {
  const $edit = document.createElement('a');
  $edit.classList.add('editThisPage');
  $edit.textContent = 'Edit this page';

  let href = 'https://github.com/algolia/jekyll-algolia/edit/develop/';
  const doc = 'docs-src/src';

  let pathname = document.location.pathname.replace('/jekyll-algolia', '');

  if (/\/$/.test(pathname)) pathname += 'index.html';
  href += `${doc}${pathname.replace('.html', '.md')}`;

  pathname = pathname.replace('.html', '.md');
  $edit.href = href;
  document.querySelector('.documentation-container').appendChild($edit);
}
