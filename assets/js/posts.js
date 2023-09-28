brandContainer = document.querySelector('.navbar-brand-container')
brandContainer.classList.remove('mx-auto')
title = document.querySelector('.quarto-title-block .title').innerHTML
codeTools = document.querySelectorAll('#quarto-code-tools-menu, .dropdown-menu')
if (codeTools.length > 0) {
  codeTools[0].classList.add('ms-auto')
  codeTools = [...codeTools].reverse()
  d = document.createElement('div')
  d.classList.add('btn-group', 'quarto-code-tools')
  codeTools.forEach(
    (n) => d.insertAdjacentElement(
    'afterbegin', n
    )
  )
  document.querySelector('.navbar-container').insertAdjacentElement(
    'beforeend', d
  )
} else {
  // does something with #quarto-code-tools-source
}
document.querySelector('.navbar-container').insertAdjacentHTML(
  'afterbegin', '<div class="navbar-title-container me-auto"><ul class="navbar-nav navbar-nav-scroll"><li class="nav-item"><span class="nav-link">'+title+'</span></li></ul></div>'
);
