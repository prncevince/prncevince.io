// displays cards appropriately
quartoTitle = document.querySelector('div.quarto-title')
eulerImg = document.querySelector('img.euler')
quartoTitle.insertAdjacentElement('afterbegin', eulerImg)
quartoGridItemEnd = document.querySelectorAll('div.quarto-listing .quarto-grid-item .card-body .card-attribution.end')
quartoGridItemEnd.forEach((n) => {
  n.classList.add('card-footer', 'euler')
  n.parentElement.parentElement.insertAdjacentElement('beforeend', n)
})
// sorts grid by 'listing-title'
window.addEventListener("DOMContentLoaded", () => {
  window['quarto-listings']['listing-listing'].sort('listing-title', {order: 'asc'})
});