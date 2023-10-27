svgChoro = document.querySelector('svg.svglite > g.choro')
svgBords = document.querySelector('svg.svglite > g.borders')
svgBordE = document.querySelector('svg.svglite > g.borders > path.end')
tooltipG = document.querySelector('svg.svglite g.tooltip')
tooltipR = document.querySelector('svg.svglite g.tooltip rect')
tooltipT = document.querySelector('svg.svglite g.tooltip text')
tooltipT.innerHTML = 'A'
const pad = 4
const xR = 0.5 // for width of path
const yR = 0.5
let tooltipTBox = tooltipT.getBBox()
let hT = tooltipTBox.height
let wT = tooltipTBox.width
let hR = hT+pad*3+xR
let wR = wT+pad*2.5+yR
let xT = wR/2
let yT = hR/2
tooltipR.setAttribute('x', xR)
tooltipR.setAttribute('y', yR)
tooltipT.setAttribute('x', xT)
tooltipT.setAttribute('y', yT)
tooltipR.setAttribute('width', `${wR}px`)
tooltipR.setAttribute('height', `${hR}px`)
// right & bottom pixel offseft
const mouseOffset = [0,0]
const svgBox = document.querySelector('svg.svglite').getBBox()

// element to be replaced by hovered element
svgBords.insertAdjacentHTML('beforeend', '<path class="end"></path>')

svgChoro.onmouseover = function(e) {
  if (e.target.nodeName == 'path') {
    const bbox = e.target.getBBox()
    e.target.classList.add('hover', 'end')
    bordersGEnd = document.querySelector('svg.svglite > g.borders > path.end')
    // replacement of elements
    const dummy = document.createComment('')
    bordersGEnd.replaceWith(dummy)
    e.target.replaceWith(bordersGEnd)
    dummy.replaceWith(e.target)
    showTooltip(bbox.x, bbox.y, bbox.width, bbox.height, e.target.getAttribute('title'))
    // remove hover and put path elements back in original groups
    e.target.onmouseout = function(e) {
      e.target.classList.remove('hover', 'end')
      svgChoro.appendChild(e.target)
      svgBords.appendChild(bordersGEnd)
    }
  }
}

svgBords.onmouseleave = hideTooltip
// Chrome compatibility
svgChoro.onmouseleave = hideTooltip

function hideTooltip(e) {
  tooltipG.style.visibility = 'hidden'
}
function showTooltip(x, y, w, h, text) {
  tooltipT.innerHTML = text
  tooltipTBox = tooltipT.getBBox()
  hT = tooltipTBox.height
  wT = tooltipTBox.width
  hR = hT+pad*2
  wR = wT+pad*2
  xT = wR/2
  yT = hR/2
  tooltipT.setAttribute('x', xT)
  tooltipT.setAttribute('y', yT)
  tooltipR.setAttribute('width', `${wR}px`)
  tooltipR.setAttribute('height', `${hR}px`)
  const bottom_target = [x-w/2-mouseOffset[0], y+h+mouseOffset[1]]
  let xG = bottom_target[0]
  let yG = bottom_target[1]
  const tooltipRBox = tooltipR.getBBox()
  // uses max tooltip size to not going over right edge
  if (xG > svgBox.width - tooltipRBox.width) { xG = x - (tooltipRBox.width < 150 ? tooltipRBox.width : 150) }
  // keeps from going over left edge
  if (xG < 0) { xG = 0 }
  // keeps from going over bottom
  if (yG > svgBox.height - tooltipRBox.height) { yG = y - tooltipRBox.height - mouseOffset[1] }
  // tooltips will always be under top
  tooltipG.setAttribute('transform', `translate(${xG},${yG})`)
  tooltipG.style.visibility = 'visible'
}
