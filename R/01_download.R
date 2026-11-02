# 01_download.R -- descarga TODAS las fuentes crudas a data/raw/<fecha>/
# Fuentes:
#   * Cook PVI 2026 (Datawrapper embebido en cookpolitical.com; 435 distritos + votos 2020/2024)
#   * Wikipedia (API parse): generic ballot nacional, Camara por estado, Senado
#   * Poliwave: generic ballot, 35 carreras senatoriales, distritos con encuestas
#   * FiveThirtyEight (GitHub): archivo historico raw_polls.csv (1998-2024, con resultado real)
source("R/00_setup.R")

STAMP <- format(Sys.time(), "%Y-%m-%d")
RAW   <- file.path(DIR_RAW, STAMP)
dir.create(RAW, showWarnings = FALSE, recursive = TRUE)
msg("Descargando a %s", RAW)

# ---- 1. Cook PVI 2026 (Datawrapper) ----------------------------------------
http_get("https://datawrapper.dwcdn.net/rAx2t/1/dataset.csv", file.path(RAW, "cook_pvi_2026.tsv"))

# ---- 2. Wikipedia ----------------------------------------------------------
wiki_parse_html("2026_United_States_elections", file.path(RAW, "wiki_us2026.json"))
wiki_parse_html("2026_United_States_House_of_Representatives_elections", file.path(RAW, "wiki_house.json"))
wiki_parse_html("2026_United_States_Senate_elections", file.path(RAW, "wiki_senate.json"))

# ---- 3. FiveThirtyEight historico ------------------------------------------
http_get("https://raw.githubusercontent.com/fivethirtyeight/data/master/pollster-ratings/raw_polls.csv",
         file.path(RAW, "fte_raw_polls.csv"))

# ---- 4. Poliwave -----------------------------------------------------------
PW <- "https://www.poliwave.com"
dir.create(file.path(RAW, "poliwave"), showWarnings = FALSE)
http_get(paste0(PW, "/us/fed/polls"),       file.path(RAW, "poliwave", "generic.html"))
http_get(paste0(PW, "/us/senate"),          file.path(RAW, "poliwave", "senate_index.html"))
http_get(paste0(PW, "/us/fed/polls/house"), file.path(RAW, "poliwave", "house_index.html"))
http_get(paste0(PW, "/us/fed/projection"),  file.path(RAW, "poliwave", "projection.html"))

# carreras senatoriales: enlaces /us/xx/sen-fed en el indice
sen_html <- read_html(file.path(RAW, "poliwave", "senate_index.html"))
sen_links <- html_attr(html_elements(sen_html, "a[href]"), "href") %>%
  str_subset("^/us/[a-z]{2}/sen-fed$") %>% unique() %>% sort()
msg("Carreras senatoriales en Poliwave: %d", length(sen_links))
dir.create(file.path(RAW, "poliwave", "senate"), showWarnings = FALSE)
for (l in sen_links) {
  st <- toupper(str_match(l, "/us/([a-z]{2})/")[, 2])
  http_get(paste0(PW, l), file.path(RAW, "poliwave", "senate", paste0(st, ".html")))
}

# distritos con encuestas: enlaces /us/fed/polls/house/xx-nn
house_html <- read_html(file.path(RAW, "poliwave", "house_index.html"))
house_links <- html_attr(html_elements(house_html, "a[href]"), "href") %>%
  str_subset("^/us/fed/polls/house/[a-z]{2}-[a-z0-9]{2}$") %>% unique() %>% sort()
msg("Distritos con encuestas en Poliwave: %d", length(house_links))
dir.create(file.path(RAW, "poliwave", "house"), showWarnings = FALSE)
for (l in house_links) {
  d <- toupper(basename(l))
  http_get(paste0(PW, l), file.path(RAW, "poliwave", "house", paste0(d, ".html")))
}

# ---- manifiesto con hashes -------------------------------------------------
files <- list.files(RAW, recursive = TRUE, full.names = TRUE)
manifest <- tibble(
  file   = str_remove(files, paste0(RAW, "/")),
  bytes  = file.size(files),
  sha256 = map_chr(files, ~ digest(.x, algo = "sha256", file = TRUE)),
  downloaded_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")
)
write_csv(manifest, file.path(RAW, "MANIFEST.csv"))
msg("Listo: %d archivos, %.1f MB", nrow(manifest), sum(manifest$bytes) / 1e6)
