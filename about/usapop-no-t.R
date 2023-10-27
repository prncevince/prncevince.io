library(sf)
library(ggfx)
library(xml2)
library(dplyr)
library(purrr)
library(rvest)
library(usmap)
library(tibble)
library(tictoc)
library(ggplot2)
library(svglite)
library(base64enc)

tic()

# data load & format ----
d <- left_join(usmap::us_map(regions='county'), usmap::countypop, by = c('fips', 'abbr', 'county')) |>
  as_tibble()
# must create individual polygons first before entire counties of multiple polygons
d_sf <- d |> st_as_sf(coords = c('x', 'y'), crs = usmap::usmap_crs()) |> st_transform(4326) |>
  group_by(group) |>
  summarise(
    geometry = st_combine(geometry) |> st_cast('POLYGON'),
    across(c(abbr, pop_2015, full, county, fips), unique)
  ) |>
  group_by(fips) |>
  summarise(
    geometry = st_combine(geometry),
    across(c(abbr, pop_2015, full, county), unique),
    l_group = list(group)
  ) |>
  mutate(pop_full = sum(pop_2015, na.rm = T), .by = full) |>
  mutate(
    point = lapply(geometry, function(p) p |> st_cast('POINT') |>
        suppressWarnings()) |> st_sfc() |> st_set_crs(4326),
    county = sub(x = county, pattern = ' County', replacement = ''),
    pop_perc = pop_2015/pop_full
  ) |>
  mutate(
    text = paste0(
      sprintf(paste0(county, ', ', full, ' ', '%.2f%%'), 100*pop_perc),
      # for mapping SVG elements
      '|', lapply(geometry, length) |> unlist()
    )
  )

# ggplot ----
## plot format objects ----
proj <- '+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs'
d_sf_states <- d_sf |> group_by(full) |> summarise(geometry = st_combine(geometry)) |>
  mutate(geometry = geometry |> st_make_valid() |> st_union(), .by = full) |>
  filter(! full %in% c('Hawaii', 'Alaska')) |>
  st_transform(proj)
d_sf_plot <- d_sf |>
  filter(! full %in% c('Hawaii', 'Alaska')) |>
  st_transform(proj)

g <- ggplot(data = d_sf_plot) +
  with_shadow(
    sigma = 3, x_offset = 3, y_offset = 3,
    geom_sf(data = d_sf_states, color = "black", fill = 'white')
  ) +
  geom_sf(mapping = aes(fill = log(pop_2015)), linewidth=0.1) +
  scale_fill_continuous(low = 'yellow', high = 'darkgreen', na.value='yellow', guide = 'none') +
  geom_sf(data = d_sf_states, color = "white", fill = 'transparent') +
  theme_void()

ggsave(
  plot = g, width = 11.88212, height = 7.465619, filename = 'about/usapop.png'
)

toc()
