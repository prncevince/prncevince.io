library(sf)
library(dplyr)
library(usmap)
library(tibble)
library(ggplot2)

d <- left_join(usmap::us_map(regions="county"), usmap::countypop, by = c('fips', 'abbr', 'county')) |>
  as_tibble()

d_sf <- d |> st_as_sf(coords = c("x", "y"), crs = usmap::usmap_crs()) |> st_transform(4326) |>
  group_by(group) |>
  summarise(
    geometry = st_combine(geometry) |> st_cast('POLYGON'),
    across(c(abbr, pop_2015, full, fips), unique)
  )

g <- d_sf |> filter(! full %in% c("Hawaii", "Alaska")) |>
  st_transform("+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs") |>
  ggplot() +
  geom_sf(mapping = aes(fill = log(pop_2015))) +
  scale_fill_continuous(low = "yellow", high = "darkgreen", na.value="yellow", guide = FALSE) +
  theme_void()

ggsave(plot = g, filename = 'about/usapop.png', dpi = 144)
