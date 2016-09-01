function responsiveNavigation() {
    let navigation = document.querySelector('.ac-nav');
    let links = navigation.querySelectorAll('a');
    let navigationAsSelect = document.createElement('select');

    if((navigator.userAgent.match(/iPhone/i)) || (navigator.userAgent.match(/iPod/i))) {
      navigationAsSelect.classList.add('display-on-small', 'device');
    } else {
      navigationAsSelect.classList.add('display-on-small');
    }

    for( let i = 0; i<links.length; i++ ) {
      let option = document.createElement('option');
        option.text = links[i].title;
        option.value = links[i].href;
        option.selected = true;
        navigationAsSelect.appendChild(option);
    }

    navigation.appendChild(navigationAsSelect);
    navigation.addEventListener('change', () => {
        return window.location = e.target.value;
    });
}
responsiveNavigation();