top <- 'euler/problem/'
x <- list.files(top, pattern = '*.qmd')
n <- length(x) / 2
d <- grep(x = x, pattern = "_", value = TRUE, invert = TRUE) |>
  gsub(patter = ".qmd", replacement = "")
for (i in d) {
  f <- grep(x = x, pattern = i, value = TRUE)
  fs::file_move(paste0(top, f[1]), paste0(top, i, "/_index.qmd"))
  fs::file_move(paste0(top, f[2]), paste0(top, i, "/index.qmd"))
}