loadCache <- function(f, labels = NULL) {
  top <- ifelse(f == "index", "index", paste0("book/", f))
  if (is.null(labels)) {
    labels <- readLines(paste0("chunk-labels/", f, ".txt"))
  }
  load_cache_labels(
    path = paste0(top, '_cache/html'), labels = labels
  )
}

# a fix for `quarps2::lazyload_cache_labels`
# this will also load cached chunks that have set the `cache.lazy` chunk option to false
load_cache_labels <- function(
    labels, path = './cache/', envir = .GlobalEnv, verbose = TRUE, filter, full.names = TRUE, ...)
{
  # first find lazy loadable objects
  lazy_files <- do.call(
    list.files,
    list(
      path = path,
      pattern = paste0("^(", paste(labels, collapse = "|"), ")_[0-9a-f]{32}\\.rdx$"),
      full.names = full.names,
      ...
    )
  )
  lazy_files <- gsub("\\.rdx$", "", lazy_files)
  lazy_labels <- lazy_files %>% strsplit('/') %>% lapply(pluck, -1) %>% unlist() %>% gsub("(^.*)_.*$", "\\1", .)
  # order label files in order that appear within document
  # this allows us to override variables correctly when loaded sequentially
  i_lazy <- lapply(labels[which(labels %in% lazy_labels)], function(i) which(i == lazy_labels)) %>% unlist()
  lazy_files <- lazy_files[i_lazy]
  files <- lazy_files
  lfound <- sapply(lapply(labels, grepl, x = files), any)
  # all lazyload cached objects have been checked, now check where cache.lazy set to FALSE
  if (!all(lfound)) {
    unlazy_files <- do.call(
      list.files,
      list(
        path = path,
        pattern = paste0("^(", paste(labels[!lfound], collapse = "|"), ")_[0-9a-f]{32}\\.RData$"),
        full.names = full.names,
        ...
      )
    )
    unlazy_labels <- unlazy_files %>% strsplit('/') %>% lapply(pluck, -1) %>% unlist() %>% gsub("(^.*)_.*$", "\\1", .)
    # order label files in order that appear within document
    # this allows us to override variables correctly when loaded sequentially
    i_unlazy <- lapply(labels[which(labels %in% unlazy_labels)], function(i) which(i == unlazy_labels)) %>% unlist()
    unlazy_files <- unlazy_files[i_unlazy]
    files <- c(files, unlazy_files)
  }
  lfound <- sapply(lapply(labels, grepl, x = files), any)
  # if labels are not found - nothing is loaded by default
  if (!all(lfound)) {
    files <- do.call(
      list.files, list(path = path, pattern = ")_[0-9a-f]{32}\\.rdx$", full.names = FALSE, ...)
    )
    files <- gsub(")_[0-9a-f]{32}\\.rdx$", "", files)
    # all lazyload cached objects have been checked now check where cache.lazy set to FALSE
    message(paste0(
      "label(s)\n", paste(paste0("  ", labels[!lfound]), collapse = "\n"),
      "\nnot found in path '", path,
      "\n\n", "Available labels:\n", paste(paste0("  ", files), collapse = "\n")
    ))
    warning("Nothing loaded", call. = FALSE)
  }
  # if all labels are found - load them
  else {
    # lazy loading
    if (exists('lazy_files')) {
      if (!is.null(lazy_files)) {
        if (!verbose) {
          sapply(lazy_files, lazyLoad, envir = envir, filter = filter)
        } else {
          sapply(lazy_files, function(x, envir, filter) {
            message(paste("Lazyloading", x))
            lazyLoad(x, envir = envir, filter = filter)
          }, envir = envir, filter = filter)
        }
      }
    }
    # non lazy loading
    if (exists('unlazy_files')) {
      if (!is.null(unlazy_files)) {
        if (!verbose) {
          sapply(unlazy_files, load, envir = envir)
        } else {
          sapply(unlazy_files, function(x, envir) {
            message(paste("Loading", x))
            load(x, envir = envir)
          }, envir = envir)
        }
      }
    }
  }
  invisible()
}
