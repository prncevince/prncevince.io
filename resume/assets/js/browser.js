// Safari
if (navigator.vendor.match(/apple/i)) {
  /*window.onload = function() {*/
    const content = ["'🌪'", "'🌎'", "'🛰'", "'📡'", "'🚀'", "'🗺'", "'💻'"]
    const vars = ['li-disaster-s', 'li-earth-s', 'li-sat-s', 'li-dish-s', 'li-rocket-s', 'li-map-s', 'li-mac-s']
    var style = document.createElement('style');
    style.type = 'text/css';
    style.innerHTML = `
    ul.os > li.content { padding-left: 23.5px; }
    ul:not(os) { list-style-type: '– '; }
    `
    document.getElementsByTagName('head')[0].appendChild(style);
    content.forEach((n, i) => {
      document.documentElement.style.setProperty('--'+vars[i], content[i])
    })
}