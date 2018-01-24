function createElement(type, callback) {
  const element = document.createElement(type);

  callback(element);

  return element;
}

function freezeGif(img) {
  const width = img.width;
  const height = img.height;
  const canvas = createElement('canvas', clone => {
    clone.width = width;
    clone.height = height;
  });
  let attr;

  const freeze = function() {
    canvas.getContext('2d').drawImage(img, 0, 0, width, height);

    for (let i = 0; i < img.attributes.length; i++) {
      attr = img.attributes[i];

      if (attr.name !== '"') {
        canvas.setAttribute(attr.name, attr.value);
      }
    }

    canvas.style.position = 'absolute';

    img.parentNode.insertBefore(canvas, img);
    img.style.opacity = 0;
    img.style.visibility = 'hidden';
    canvas.style.visibility = 'visible';
    canvas.style.opacity = 1;

    img.parentNode.addEventListener('mouseover', () => {
      img.style.opacity = 1;
      img.style.visibility = 'visible';
      canvas.style.visibility = 'hidden';
      canvas.style.opacity = 0;
    });
    img.parentNode.addEventListener('mouseout', () => {
      img.style.opacity = 0;
      img.style.visibility = 'hidden';
      canvas.style.visibility = 'visible';
      canvas.style.opacity = 1;
    });
  };

  if (img.complete) {
    freeze();
  } else {
    img.addEventListener('load', freeze, true);
    window.addEventListener('resize', freeze, true);
  }
}

export function freezeAllGifs() {
  return [].slice
    .apply(document.querySelectorAll('.js-freeze'))
    .map(freezeGif);
}
