# utils.R -- funciones puras compartidas por 02_clean.R y 04_model.R (probadas en tests/test_utils.R)
# Se carga desde 00_setup.R. No tiene efectos secundarios.

MONTHS <- c("January","February","March","April","May","June","July","August",
            "September","October","November","December")

clean_ref <- function(x) str_squish(str_remove_all(x, "\\[[^\\]]*\\]"))

# ---- partidos y candidatos (Wikipedia) ---------------------------------------
norm_party <- function(p) {
  # Democratic / DFL (Minnesota) / Democratic-NPL (Dakota del Norte) -> Democratic ; etc.
  case_when(is.na(p) ~ NA_character_,
            str_detect(p, "^Democratic|^DFL") ~ "Democratic",
            str_detect(p, "^Republican") ~ "Republican",
            str_detect(p, "^Independent|^Nonpartisan|^No party") ~ "Independent",
            TRUE ~ str_squish(p))
}
parties_in <- function(cands) {
  # "▌Jerry Carl (Republican)\n▌Clyde Jones Jr. (Democratic)" -> lista de partidos normalizados
  norm_party(str_match_all(clean_ref(cands), "\\(([^()]+)\\)")[[1]][, 2])
}
cand_by_party <- function(cands, party) {
  lines <- str_split(clean_ref(cands), "▌|\\n")[[1]] %>% str_squish() %>% discard(~ .x == "")
  lp <- norm_party(str_match(lines, "\\(([^()]+)\\)\\s*$")[, 2])
  hit <- lines[!is.na(lp) & lp == party]
  if (!length(hit)) NA_character_ else paste(str_remove(hit, "\\s*\\([^()]*\\)\\s*$"), collapse = "; ")
}

# ---- fechas de Wikipedia -------------------------------------------------------
parse_wiki_dates <- function(x) {
  # "October 22–30, 2026" | "October 29 – November 1, 2026" | "October 26, 2026"
  x <- str_squish(str_replace_all(x, "[–—−-]", "-"))
  # el ano de referencia es el ULTIMO que aparece (el del fin de campo)
  yr <- as.integer(map_chr(str_extract_all(x, "\\d{4}"), ~ if (length(.x)) .x[length(.x)] else NA_character_))
  body <- str_squish(str_remove_all(str_remove_all(x, ",?\\s*\\d{4}"), ","))
  parts <- str_split_fixed(body, "\\s*-\\s*", 2)
  left <- str_squish(parts[, 1]); right <- str_squish(parts[, 2])
  lm <- str_extract(left, paste(MONTHS, collapse = "|")); ld <- as.integer(str_extract(left, "\\d+"))
  rm_ <- str_extract(right, paste(MONTHS, collapse = "|")); rd <- as.integer(str_extract(right, "\\d+"))
  end_m <- coalesce(rm_, lm); end_d <- coalesce(rd, ld)
  start <- suppressWarnings(make_date(yr, match(lm, MONTHS), ld))
  end   <- suppressWarnings(make_date(yr, match(end_m, MONTHS), end_d))
  # rangos que cruzan el ano ("December 28, 2025 - January 4, 2026"): el ano capturado es el del final
  cross <- !is.na(start) & !is.na(end) & start > end
  start[cross] <- suppressWarnings(make_date(yr[cross] - 1L, match(lm[cross], MONTHS), ld[cross]))
  tibble(start = start, end = end)
}

# ---- calificaciones de expertos -------------------------------------------------
rating_to_margin <- function(x) {
  # "Lean D (flip)" -> +5 ; "Tossup" -> 0 ; "Safe R" -> -18 ; "Tilt I" -> +2.5 (independiente = lado no R)
  x <- str_to_lower(str_squish(str_remove_all(x, "\\(.*?\\)|\\[.*?\\]")))
  lvl <- str_extract(x, "solid|safe|likely|lean|tilt|toss-?up")
  party <- str_extract(x, "\\b[dri]$")
  val <- case_when(lvl %in% c("solid", "safe") ~ 18, lvl == "likely" ~ 9, lvl == "lean" ~ 5, lvl == "tilt" ~ 2.5,
                   str_detect(coalesce(lvl, ""), "toss") ~ 0, TRUE ~ NA_real_)
  sgn <- case_when(party == "d" ~ 1, party == "i" ~ 1, party == "r" ~ -1, TRUE ~ 0)
  val * sgn
}

# ---- Poliwave: colores, claves y emparejamiento de candidatos ----------------------
color_to_party <- function(style) {
  hex <- tolower(str_match(style, "--party-color:\\s*#([0-9a-fA-F]{6})")[, 2])
  r <- strtoi(substr(hex, 1, 2), 16L); g <- strtoi(substr(hex, 3, 4), 16L); b <- strtoi(substr(hex, 5, 6), 16L)
  case_when(is.na(hex) ~ NA_character_,
            abs(r - g) < 25 & abs(g - b) < 25 ~ "UND",     # grises (indecisos) antes que los morados
            r > 170 & b < 110 & g < 110 ~ "R",
            b > 150 & r < 120 ~ "D",
            r > 120 & b > 150 ~ "I",
            TRUE ~ "OTH")
}
option_key <- function(x) {
  # "James Talarico" -> "JAMES_TALARICO" (como las claves de `options` en el JS embebido de Poliwave)
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT", sub = "")
  toupper(str_replace_all(str_squish(x), "[^A-Za-z0-9]+", "_"))
}
key_tokens <- function(k) {
  # "TOM_KEAN_JR" -> c("TOM","KEAN"); quita sufijos y tokens vacios
  t <- str_split(k, "_")[[1]]; t <- t[t != ""]
  t[!t %in% c("JR", "SR", "II", "III", "IV")]
}
match_key_to_header <- function(keys, hdr) {
  # Las claves del JS ("MATT_DUNLAP", "TOM_KEAN_JR", "MAR_A_ELVIRA_SALAZAR") no siempre coinciden con
  # el nombre visible ("Matthew Dunlap", "Thomas Kean Jr.", "Maria Elvira Salazar"): se empareja por
  # apellido (ultimo token) y, si hay ambiguedad, por la inicial del primer token.
  if (is.null(hdr) || !nrow(hdr)) return(rep(NA_character_, length(keys)))
  htok <- map(hdr$key, key_tokens)
  map_chr(keys, function(k) {
    exact <- which(hdr$key == k); if (length(exact)) return(hdr$party[exact[1]])
    kt <- key_tokens(k); if (!length(kt)) return(NA_character_)
    last <- kt[length(kt)]
    cand <- which(map_lgl(htok, ~ length(.x) > 0 && .x[length(.x)] == last))
    if (length(cand) == 1) return(hdr$party[cand])
    if (length(cand) > 1) {
      cand2 <- cand[map_lgl(htok[cand], ~ substr(.x[1], 1, 1) == substr(kt[1], 1, 1))]
      if (length(cand2) >= 1) return(hdr$party[cand2[1]])
    }
    NA_character_
  })
}

# ---- modelo -----------------------------------------------------------------------
two_party_margin <- function(dem, rep) 100 * (dem - rep) / (dem + rep)

combine3 <- function(m_f, v_f, m_p, v_p, m_r, v_r) {
  # media ponderada por precision de hasta tres fuentes (NA = fuente ausente)
  w_f <- 1 / v_f; w_p <- if_else(is.na(m_p), 0, 1 / v_p); w_r <- if_else(is.na(m_r), 0, 1 / v_r)
  tot <- w_f + w_p + w_r
  tibble(m_hat = (w_f * m_f + w_p * coalesce(m_p, 0) + w_r * coalesce(m_r, 0)) / tot,
         sd = sqrt(1 / tot), w_poll = w_p / tot, w_rating = w_r / tot)
}
