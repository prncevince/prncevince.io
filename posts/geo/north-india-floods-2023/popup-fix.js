// For literal {{, we need 2 curly brackets due to python's .format
// L.map variable - replaced with unique Folium widget map name
var m = {m}
// tooltip LayerGroup - replaced with list of unique GeoJSON  
var l_lg_tt = {lg_geo}
l_lg_tt.forEach(addEventListenersLg)
function addEventListenersLg(lg) {{
  lg.on('mouseover', function(e) {{
    if (lg.isPopupOpen()) {{
      tt = lg.getTooltip()
      pu = lg.getPopup()
      // check if ids are the same - if so then close - otherwise allow :)
      if (pu._source._leaflet_id == tt._source._leaflet_id) {{
        m.closeTooltip(tt) // lg.closeTooltip()
      }}
    }}
  }})
}}
