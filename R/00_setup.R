# 00_setup.R -- paquetes, rutas y utilidades comunes
# Pronostico de las elecciones intermedias de EE.UU. 2026 (Camara y Senado)
# Autor: Juan Miguel (prensa@wuaramedia.com). Licencia: MIT.

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(stringr)
  library(purrr); library(rvest); library(xml2); library(httr)
  library(jsonlite); library(lubridate); library(digest); library(tibble)
})

options(stringsAsFactors = FALSE, readr.show_col_types = FALSE, warn = 1)

ROOT       <- normalizePath(".", winslash = "/")
DIR_RAW    <- file.path(ROOT, "data", "raw")
DIR_FROZEN <- file.path(ROOT, "data", "frozen")
DIR_OUT    <- file.path(ROOT, "output")
DIR_DOCS   <- file.path(ROOT, "docs")
for (d in c(DIR_RAW, DIR_FROZEN, DIR_OUT, DIR_DOCS)) dir.create(d, showWarnings = FALSE, recursive = TRUE)

UA <- "pronostico-midterms-2026 (script academico; contacto: prensa@wuaramedia.com)"
ELECTION_DAY <- as.Date("2026-11-03")

# Semilla preregistrada
SEED <- 20261103L

# ---- utilidades ------------------------------------------------------------
msg <- function(...) cat(format(Sys.time(), "%H:%M:%S"), "|", sprintf(...), "\n")

http_get <- function(url, dest, sleep = 0.6, retries = 4, skip_existing = TRUE, ua = UA) {
  if (skip_existing && file.exists(dest) && file.size(dest) > 1000) return(TRUE)
  # Descarga con reintentos; devuelve TRUE si se escribio el archivo.
  for (i in seq_len(retries)) {
    r <- tryCatch(GET(url, user_agent(ua), timeout(90)), error = function(e) NULL)
    if (!is.null(r) && status_code(r) == 200) {
      writeBin(content(r, "raw"), dest)
      Sys.sleep(sleep)
      return(TRUE)
    }
    Sys.sleep(2 * i)
  }
  warning("No se pudo descargar: ", url)
  FALSE
}

wiki_parse_html <- function(page, dest) {
  # Devuelve el HTML renderizado por la API action=parse (tablas limpias)
  url <- paste0("https://en.wikipedia.org/w/api.php?action=parse&page=",
                URLencode(page, reserved = TRUE),
                "&prop=text&format=json&formatversion=2&redirects=1")
  ok <- http_get(url, dest)
  if (!ok) return(NULL)
  j <- fromJSON(dest)
  if (is.null(j$parse)) { unlink(dest); return(NULL) }   # pagina inexistente: no dejar un archivo de error
  j$parse$text
}

pvi_to_num <- function(x) {
  # "R+17" -> -17 ; "D+5" -> 5 ; "EVEN" -> 0  (positivo = democrata)
  x <- str_trim(as.character(x))
  out <- rep(NA_real_, length(x))
  out[str_detect(x, "^EVEN$")] <- 0
  m <- str_match(x, "^([DR])\\+(\\d+(?:\\.\\d+)?)")
  idx <- !is.na(m[, 1])
  out[idx] <- as.numeric(m[idx, 3]) * ifelse(m[idx, 2] == "D", 1, -1)
  out
}

# Regiones censales (4) para el componente de error regional
REGION <- c(
  CT="Northeast", ME="Northeast", MA="Northeast", NH="Northeast", RI="Northeast", VT="Northeast",
  NJ="Northeast", NY="Northeast", PA="Northeast",
  IL="Midwest", IN="Midwest", MI="Midwest", OH="Midwest", WI="Midwest",
  IA="Midwest", KS="Midwest", MN="Midwest", MO="Midwest", NE="Midwest", ND="Midwest", SD="Midwest",
  DE="South", FL="South", GA="South", MD="South", NC="South", SC="South", VA="South", WV="South",
  AL="South", KY="South", MS="South", TN="South", AR="South", LA="South", OK="South", TX="South",
  AZ="West", CO="West", ID="West", MT="West", NV="West", NM="West", UT="West", WY="West",
  AK="West", CA="West", HI="West", OR="West", WA="West"
)

STATE_NAME <- c(
  AL="Alabama", AK="Alaska", AZ="Arizona", AR="Arkansas", CA="California", CO="Colorado",
  CT="Connecticut", DE="Delaware", FL="Florida", GA="Georgia", HI="Hawaii", ID="Idaho",
  IL="Illinois", IN="Indiana", IA="Iowa", KS="Kansas", KY="Kentucky", LA="Louisiana",
  ME="Maine", MD="Maryland", MA="Massachusetts", MI="Michigan", MN="Minnesota",
  MS="Mississippi", MO="Missouri", MT="Montana", NE="Nebraska", NV="Nevada",
  NH="New Hampshire", NJ="New Jersey", NM="New Mexico", NY="New York",
  NC="North Carolina", ND="North Dakota", OH="Ohio", OK="Oklahoma", OR="Oregon",
  PA="Pennsylvania", RI="Rhode Island", SC="South Carolina", SD="South Dakota",
  TN="Tennessee", TX="Texas", UT="Utah", VT="Vermont", VA="Virginia", WA="Washington",
  WV="West Virginia", WI="Wisconsin", WY="Wyoming"
)
STATE_ABBR <- setNames(names(STATE_NAME), STATE_NAME)

# Estados que redisenaron sus mapas para 2026 (Cook PVI 2026)
REDISTRICTED_2026 <- c("AL","CA","FL","LA","MO","NC","OH","TN","TX","UT")
