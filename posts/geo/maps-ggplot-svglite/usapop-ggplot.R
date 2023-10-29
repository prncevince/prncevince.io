library(sf)
library(ggfx)
library(dplyr)
library(usmap)
library(tibble)
library(ggplot2)
library(showtext)

# mbp 14" dpi / height / width in inches
dpi <- 254
width <- 11.90157
height <- 7.437008

showtext_opts(dpi = dpi)
showtext_auto(enable = TRUE)
font_add("Black Chancery", "BLKCHCRY.TTF")

g <- ggplot(data = d_sf_plot) +
  with_shadow(
    sigma = 5, x_offset = 5, y_offset = 5,
    geom_sf(data = d_sf_states, color = "black", fill = 'white')
  ) +
  geom_sf(mapping = aes(fill = log(pop_2015)), linewidth=0.1) +
  scale_fill_continuous(low = 'yellow', high = 'darkgreen', na.value='yellow', guide = 'none') +
  geom_sf(data = d_sf_states, color = "black", fill = 'transparent') +
  labs(title = 'Population Across America') +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "white", color = "white"),
    text = element_text(family='Black Chancery'),
    plot.title = element_text(vjust = 0.01, hjust = 0.5, size = 75)
  )
gb <- ggplot_build(g)

g <- g +
  annotate(
    "text", label = "© Vincent Clemson", family='Black Chancery', size = 14/.pt,
    x = gb$layout$panel_params[[1]]$x_range[1]+1100000,
    y = gb$layout$panel_params[[1]]$y_range[1]+500000,
  )
ggsave(plot = g, width = width, height = height, unit = 'in', dpi = dpi, filename = 'usapop-ggplot-ggsave.png')
