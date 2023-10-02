from leafmap.foliumap import *

def add_gdf2(
    self,
    gdf,
    layer_name: Optional[str] = "Untitled",
    zoom_to_layer: Optional[bool] = True,
    info_mode: Optional[str] = "on_hover",
    **kwargs,
):
      """Adds a GeoPandas GeoDataFrame to the map.

      Args:
          gdf (GeoDataFrame): A GeoPandas GeoDataFrame.
          layer_name (str, optional): The layer name to be used. Defaults to "Untitled".
          zoom_to_layer (bool, optional): Whether to zoom to the layer.
          info_mode (str, optional): Displays the attributes by either on_hover or on_click. Any value other than "on_hover" or "on_click" will be treated as None. Defaults to "on_hover".
          **kwargs: Arguments of self.add_geojson2. "style" can be used in-place of "style_function".
      """

      for col in gdf.columns:
          if gdf[col].dtype in ["datetime64[ns]", "datetime64[ns, UTC]"]:
              gdf[col] = gdf[col].astype(str)

      data = gdf_to_geojson(gdf, epsg="4326")

      self.add_geojson2(data, layer_name=layer_name, info_mode=info_mode, **kwargs)

      if zoom_to_layer:
          import numpy as np

          bounds = gdf.to_crs(epsg="4326").bounds
          west = np.min(bounds["minx"])
          south = np.min(bounds["miny"])
          east = np.max(bounds["maxx"])
          north = np.max(bounds["maxy"])
          self.fit_bounds([[south, east], [north, west]])

def add_geojson2(
    self,
    in_geojson: str,
    layer_name: Optional[str] = "Untitled",
    encoding: Optional[str] = "utf-8",
    info_mode: Optional[str] = "on_hover",
    tooltip_fields_remove: Optional[list] = [],
    popup_fields_remove: Optional[list] = [],
    kwargs_tooltip: Optional[dict] = {},
    kwargs_popup: Optional[dict] = {},
    **kwargs,
):
    """Adds a GeoJSON file to the map.

    Args:
        in_geojson (str): The input file path to the GeoJSON.
        layer_name (str, optional): The layer name to be used. Defaults to "Untitled".
        encoding (str, optional): The encoding of the GeoJSON file. Defaults to "utf-8".
        info_mode (str, optional): Displays the attributes by either on_hover or on_click. Any value other than "on_hover" or "on_click" will be treated as None. Defaults to "on_hover".
        tooltip_fields_remove (list, optional): When "fields" kwarg is not set, fields to remove from data["features"][0]["properties"].keys() so that they are not displayed in tooltip
        popup_fields_remove (list, optional): Same as tooltip_fields_remove but for the popup
        kwargs_tooltip (dict, optional): Arguments passed to folium.GeoJsonTooltip
        kwargs_popup (dict, optional): Arguments passed to folium.GeoJsonPopup
        **kwargs: Arguments of folium.GeoJson. "style" can be used in-place of "style_function".
    Raises:
        FileNotFoundError: The provided GeoJSON file could not be found.
    """
    import json
    import requests
    import random

    try:
        if isinstance(in_geojson, str):
            if in_geojson.startswith("http"):
                if is_jupyterlite():
                    import pyodide

                    output = os.path.basename(in_geojson)

                    output = os.path.abspath(output)
                    obj = pyodide.http.open_url(in_geojson)
                    with open(output, "w") as fd:
                        shutil.copyfileobj(obj, fd)
                    with open(output, "r") as fd:
                        data = json.load(fd)
                else:
                    in_geojson = github_raw_url(in_geojson)
                    data = requests.get(in_geojson).json()
            else:
                in_geojson = os.path.abspath(in_geojson)
                if not os.path.exists(in_geojson):
                    raise FileNotFoundError(
                        "The provided GeoJSON file could not be found."
                    )

                with open(in_geojson, encoding=encoding) as f:
                    data = json.load(f)
        elif isinstance(in_geojson, dict):
            data = in_geojson
        else:
            raise TypeError("The input geojson must be a type of str or dict.")
    except Exception as e:
        raise Exception(e)

    # interchangeable parameters between ipyleaflet and folium.
    # sets style_function parameter of folium.GeoJson to a lambda function
    style_dict = {}
    if "style_function" not in kwargs:
        if "style" in kwargs:
            style_dict = kwargs["style"]
            if isinstance(kwargs["style"], dict) and len(kwargs["style"]) > 0:
                kwargs["style_function"] = lambda x: style_dict
            kwargs.pop("style")
        else:
            style_dict = {
                # "stroke": True,
                "color": "#3388ff",
                "weight": 2,
                "opacity": 1,
                # "fill": True,
                # "fillColor": "#ffffff",
                "fillOpacity": 0,
                # "dashArray": "9"
                # "clickable": True,
            }
            kwargs["style_function"] = lambda x: style_dict

    if "style_callback" in kwargs:
        kwargs.pop("style_callback")

    if "hover_style" in kwargs:
        kwargs.pop("hover_style")

    if "fill_colors" in kwargs:
        fill_colors = kwargs["fill_colors"]

        def random_color(feature):
            style_dict["fillColor"] = random.choice(fill_colors)
            return style_dict

        kwargs["style_function"] = random_color
        kwargs.pop("fill_colors")

    if "weight" not in style_dict:
        style_dict["weight"] = 2

    if "highlight_function" not in kwargs:
        kwargs["highlight_function"] = lambda feat: {
            "weight": style_dict["weight"] + 2,
            "fillOpacity": 0,
        }

    tooltip = None
    popup = None
    if info_mode is not None:
        if "fields" in kwargs:
            props = kwargs["fields"]
            kwargs.pop("fields")
        else:
            props = list(data["features"][0]["properties"].keys())
        if info_mode == "on_hover" or info_mode == "both":
            props_t = props
            props_t = [p for p in props_t if p not in tooltip_fields_remove]
            tooltip = folium.GeoJsonTooltip(fields=props_t, **kwargs_tooltip)
        if info_mode == "on_click" or info_mode == "both":
            props_p = props
            props_p = [p for p in props if p not in popup_fields_remove]
            popup = folium.GeoJsonPopup(fields=props_p, **kwargs_popup)

    geojson = folium.GeoJson(
        data=data, name=layer_name, 
        tooltip=tooltip,
        popup=popup,
        **kwargs
    )
    geojson.add_to(self)
