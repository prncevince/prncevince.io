x <- commandArgs(trailingOnly = TRUE)
p <- "euler/.template/"
f <- c("index.qmd", "_index.qmd")
fi <- paste0(p, f)
z <- rep(0, 4 - nchar(x[1])) |> paste0(collapse = "")
po <- paste0("euler/problem/", z, x[1], "/")
fo <- paste0(po, f)
l <- list(p = x[1], n = x[2], d = Sys.Date())
if (! dir.exists(po)) dir.create(po)
jinjar::render(fs::path(fi[1]), l = l) |>
  writeLines(con = fo[1])
fs::file_copy(fi[2], fo[2])