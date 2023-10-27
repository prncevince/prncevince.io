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
d_sf_us <- d_sf |> filter(! full %in% c('Hawaii', 'Alaska')) |>
  summarise(geometry = st_combine(geometry)) |>
  mutate(geometry = geometry |> st_make_valid() |> st_union()) |>
  st_transform(proj)
d_sf_states <- d_sf |> group_by(full) |> summarise(geometry = st_combine(geometry)) |>
  mutate(geometry = geometry |> st_make_valid() |> st_union(), .by = full) |>
  filter(! full %in% c('Hawaii', 'Alaska')) |>
  st_transform(proj)
d_sf_plot <- d_sf |>
  filter(! full %in% c('Hawaii', 'Alaska')) |>
  st_transform(proj)
## plot object ----
g0 <- list(
  geom_sf(mapping = aes(fill = log(pop_2015)), linewidth=0.1),
  scale_fill_continuous(low = 'yellow', high = 'darkgreen', na.value='yellow', guide = 'none'),
  geom_sf(data = d_sf_states, color = "black", fill = 'transparent'),
  geom_sf_text(aes(geometry = point, label = text)),
  labs(title = 'Population Across America'),
  theme_void(),
  theme(
    text = element_text(family='serif'),
    plot.title = element_text(vjust = 0.01, hjust = 0.5, size = 55)#size = 75)
  )
)
g <- ggplot(data = d_sf_plot) + g0
gb <- ggplot_build(g)
g <- g +
  annotate(
    "text", label = "© Vincent Clemson", family='serif', size = 12/.pt,
    x = gb$layout$panel_params[[1]]$x_range[1]+1100000,
    y = gb$layout$panel_params[[1]]$y_range[1]+500000,
  )

gfx <- ggplot(data = d_sf_plot) +
  with_shadow(
    sigma = 3, x_offset = 3, y_offset = 3,
    geom_sf(data = d_sf_us, color = "black", fill = 'white')
  ) +
  g0

## save ggplot to svg ----
# must write to file - uses {svglite}
fonts <- list(serif = list(plain = list(alias = 'Black Chancery Regular', file = 'about/BLKCHCRY.TTF')))
# mbp 14" height / width in inches
width <- 11.88212
height <- 7.465619
ggsave(plot = g, width = width, height = height, filename = 'about/usapop.svg', user_fonts = fonts)
ggsave(plot = gfx, width = width, height = height, filename = 'about/usapopfx.svg')

# svg editting ----
## read svg as xml document for editting ----
doc <- read_xml('about/usapop.svg')
docfx <- read_xml('about/usapopfx.svg')
ns_d1 <- xml_ns(doc) |> as.list() |> pluck('d1')
xml_ns_strip(doc)
xml_ns_strip(docfx)
## gather svg element data & non-dummy data to edit ----
# then move to new node & remove moved elements
xn_g <- doc |> html_elements('g') |> pluck(2)
xn_txt_use <- xn_g |> html_elements('text') |> rev() |> pluck(1)
xn_img <- docfx |> html_elements('image') |> pluck(1)
doc |> html_elements('g') |> pluck(3) |> xml_add_child(xn_txt_use)
doc |> html_elements('g') |> pluck(1) |> xml_add_child(xn_img)
xml_remove(xn_txt_use)
xn_g_path <- xn_g |> html_elements('path')
xn_g_txt <- xn_g |> html_elements('text')
## hover / popup metadata ----
l_txt <- xn_g_txt |> lapply(function(i) strsplit(html_text(i), '\\|') |> unlist())
xby <- l_txt |> lapply(function(i) pluck(i, 2)) |> unlist() |> as.integer()
txt <- l_txt |> lapply(function(i) pluck(i, 1)) |> unlist()
xby_expand <- lapply(xby, function(x) rep(x, x)) |> unlist()
txt_expand <- map2(txt, xby, \(t, x) rep(t, x)) |> unlist()
d_key <- tibble(xby_expand, txt_expand) |>
  mutate(ID = 1:n())
# identify county paths composed of more than 1 polygon
idx_1 <- d_key |> filter(xby_expand > 1) |>
  reframe(ID = ID[1], .by = txt_expand) |> pull(ID)
for(i in idx_1) {
  for (j in 1:(d_key |> filter(ID == i) |> pull(xby_expand) - 1)) {
    d_at <- xn_g_path[[i]] |> xml_attr('d')
    xn_g_path[[i]] |> xml_attr('d') <- paste(d_at, xn_g_path[[i+j]] |> xml_attr('d'))
  }
}
## removal of dummy layers ----
for(i in idx_1) {
  for (j in 1:(d_key |> filter(ID == i) |> pull(xby_expand) - 1)) {
    xml_remove(xn_g_path[i+j])
  }
}
n_before <- length(xn_g_path)
## create new path list sets with updated nodes ----
xn_g_path <- xn_g |> html_elements('path')
n_after <- length(xn_g_path)
n_removed <- n_before - n_after
n_tobe <- length(xn_g_txt)
n_other <- n_before - n_removed - n_tobe
xn_g_path_1 <- xn_g_path[1:n_tobe]
xn_g_path_2 <- xn_g_path[(n_tobe+1):(n_after)]
## combine individual polygons into group ----
# combines all polygons into same svg path element for counties
map2(xn_g_path_1, txt, \(p, t) xml_attr(p, "title") <- t) |> invisible()
xml_remove(xn_g_txt)
x_tooltip <- read_xml('<g class="tooltip"><rect/><text></text></g>')
## add separate layers to separate nodes ----
xb_g <- read_xml('<g class="borders"></g>')
lapply(xn_g_path_2, function(i) xb_g |> xml_add_child(i)) |> invisible()
xml_remove(xn_g_path_2)
## styling / javascript ----
### gather near equivalent to <head> ----
x_def <- doc |> html_elements('defs') |> pluck(1)
xn_g |> xml_attr('class') <- 'choro'
### css styling ----
x_style <- x_def |> html_element('style')
style_t <- x_style |> html_text()
style <- readLines('about/usapop.css') |> paste0(collapse = '\n')
### fonts ----
fdata <- readBin(fonts$serif$plain$file, what = "raw", n = 1e6)
style_f <- paste0(c(
  'g.tooltip {',
  paste0('font-family:', fonts$serif$plain$alias, ';'),
  '}',
  '@font-face {',
  paste0('font-family:', fonts$serif$plain$alias, ';'),
  paste0('src: url(data:font/ttf;base64,', base64encode(fdata), ') format("truetype");'),
  '}'
), collapse = '\n')
#### javascript ----
x_script <- read_xml('<script></script>')
script <- readLines('about/usapop.js') |> paste0(collapse = '\n')
## add all to xml ----
### uncomment for testing ----
# x_style_l <- read_xml('<link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" href="usapop.css"/>')
# doc |> xml_add_child(x_style_l, .where = 0)
# xml_text(x_style) <- paste0(style_t, '\n', style_f)
# x_script <- read_xml('<script xlink:href="usapop.js"></script>')
### for production - self-contained ----
xml_text(x_style) <- paste0(style_t, '\n', style, '\n', style_f)
xml_text(x_script) <- script
doc |> xml_add_child(xb_g)
doc |> xml_add_child(x_tooltip)
doc |> xml_add_child(x_script)
## output & cleanup ----
# re-add namespace & fix attribute unit
xml_attr(doc, 'xmlns') <- ns_d1
# unset to allow element to take full advantage of viewBox
xml_attr(doc, 'width') <-  NULL
xml_attr(doc, 'height') <- NULL
file.remove('about/usapopfx.svg')
write_xml(doc, 'about/usapop.svg')

toc()
