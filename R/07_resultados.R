# 07_resultados.R -- carga los resultados desde Wikipedia (llamadas de AP) y escribe output/resultados.csv
# con el formato que espera 06_evaluate.R: race_id, chamber, state, margin_actual (D-R en puntos; para
# independientes principales: no-R menos R), winner (D/R/I), mas la fila nacional US_HOUSE_VOTE.
#
# Uso:  Rscript R/07_resultados.R              (2026: 51 paginas estatales de la Camara + 35 del Senado)
#       Rscript R/07_resultados.R --prueba2024 (autoprueba con paginas de 2024: TX, AK, NE especial)
# Las tablas de resultados aparecen en Wikipedia pocas horas despues de las llamadas de AP; si un distrito
# aun no tiene tabla, queda fuera y se puede volver a correr mas tarde.
source("R/00_setup.R")

args  <- commandArgs(trailingOnly = TRUE)
PRUEBA <- "--prueba2024" %in% args
YEAR  <- if (PRUEBA) 2024L else 2026L
RAWR  <- file.path(DIR_RAW, paste0("resultados_", format(Sys.Date())))
dir.create(RAWR, showWarnings = FALSE, recursive = TRUE)

norm_p <- function(p) case_when(str_detect(p, "^(Democratic|DFL)") ~ "D", str_detect(p, "^Republican") ~ "R", TRUE ~ "I")
num <- function(x) suppressWarnings(parse_number(x))

parse_result_table <- function(tb) {
  # Filas: [color] Partido | Candidato | (incumbent) | Votos | % | ... ; en RCV hay varias rondas: se usa la ultima
  hdr <- str_squish(xml_text(xml_find_all(tb, ".//tr[1]/th")))
  rcv <- any(str_detect(hdr, "Round"))
  rows <- xml_find_all(tb, ".//tr")
  out <- map_dfr(rows, function(r) {
    cells <- str_squish(xml_text(xml_find_all(r, "./td|./th")))
    cells <- cells[cells != ""]
    if (length(cells) < 4) return(NULL)
    party <- cells[1]
    if (!str_detect(party, "^(Democratic|DFL|Republican|Independent|Libertarian|Green|Independence|Write-in|Constitution|No party|Nonpartisan|Working|Forward|Alaskan)")) return(NULL)
    if (str_detect(party, "^Write-in")) return(NULL)
    is_vote <- str_detect(cells, "^[0-9]{1,3}(,[0-9]{3})*$")
    is_pct  <- str_detect(cells, "^[0-9.]+%?$") & !is_vote & str_detect(cells, "\\.")
    if (!any(is_vote)) return(NULL)
    v_idx <- which(is_vote); p_idx <- which(is_pct)
    k <- if (rcv) length(v_idx) else 1
    votes <- num(cells[v_idx[k]]); pct <- if (length(p_idx) >= k) num(cells[p_idx[k]]) else NA_real_
    if (rcv && any(str_detect(cells, "Eliminated"))) { votes <- 0; pct <- 0 }
    tibble(party_raw = party, party = norm_p(party), candidate = cells[2], votes = votes, pct = pct)
  })
  if (!nrow(out)) return(NULL)
  out
}

summarise_race <- function(res) {
  # margen D-R en puntos porcentuales; si falta un partido mayor, el lado "no R" es el mejor independiente
  top <- res %>% group_by(party) %>% slice_max(votes, n = 1, with_ties = FALSE) %>% ungroup()
  pD <- top$pct[top$party == "D"]; pR <- top$pct[top$party == "R"]; pI <- top$pct[top$party == "I"]
  nonR <- if (length(pD)) pD else if (length(pI)) pI else NA_real_
  winner_row <- res %>% slice_max(votes, n = 1, with_ties = FALSE)
  tibble(margin_actual = coalesce(nonR, 0) - coalesce(if (length(pR)) pR else NA_real_, 0),
         winner = winner_row$party, winner_name = winner_row$candidate,
         votes_D = if (length(pD)) top$votes[top$party == "D"] else 0,
         votes_R = if (length(pR)) top$votes[top$party == "R"] else 0,
         votes_total = sum(res$votes, na.rm = TRUE), pct_D = if (length(pD)) pD else NA, pct_R = if (length(pR)) pR else NA)
}

results_from_page <- function(page, dest, chamber) {
  txt <- wiki_parse_html(page, dest)
  if (is.null(txt)) return(NULL)
  h <- read_html(txt)
  tabs <- xml_find_all(h, "//table[contains(@class,'wikitable')]")
  map_dfr(tabs, function(tb) {
    cap <- str_squish(xml_text(xml_find_first(tb, ".//caption")))
    if (is.na(cap)) return(NULL)
    cap <- clean_ref(cap)
    if (chamber == "House") {
      m <- str_match(cap, sprintf("^%d (.+?)'s (\\d+|at-large)(?:st|nd|rd|th)? congressional district election$", YEAR))
      if (is.na(m[1])) return(NULL)
      st <- unname(STATE_ABBR[m[2]]); if (is.na(st)) return(NULL)
      race_id <- if (m[3] == "at-large") paste0(st, "-AL") else sprintf("%s-%02d", st, as.integer(m[3]))
    } else {
      m <- str_match(cap, sprintf("^%d United States Senate (special )?election in (.+)$", YEAR))
      if (is.na(m[1])) return(NULL)
      st <- unname(STATE_ABBR[str_squish(m[3])]); if (is.na(st)) return(NULL)
      race_id <- paste0(st, if (!is.na(m[2])) "-S" else "")
    }
    res <- parse_result_table(tb)
    if (is.null(res) || sum(res$votes, na.rm = TRUE) == 0) return(NULL)
    bind_cols(tibble(race_id = race_id, chamber = chamber, state = st, caption = cap), summarise_race(res))
  }) %>% distinct(race_id, .keep_all = TRUE)
}

if (PRUEBA) {
  pages <- list(
    list(page = "2024_United_States_House_of_Representatives_elections_in_Texas", chamber = "House"),
    list(page = "2024_United_States_House_of_Representatives_election_in_Alaska", chamber = "House"),
    list(page = "2024_United_States_Senate_election_in_Texas", chamber = "Senate"),
    list(page = "2024_United_States_Senate_special_election_in_Nebraska", chamber = "Senate"))
} else {
  house_pages <- map(names(STATE_NAME), function(st) {
    nm <- str_replace_all(STATE_NAME[[st]], " ", "_")
    if (st == "CA") return(list(
      list(page = sprintf("2026_United_States_House_of_Representatives_elections_in_California_(districts_1%s26)", "–"), chamber = "House"),
      list(page = sprintf("2026_United_States_House_of_Representatives_elections_in_California_(districts_27%s52)", "–"), chamber = "House")))
    list(list(page = sprintf("2026_United_States_House_of_Representatives_election%s_in_%s", if (st %in% AT_LARGE) "" else "s", nm), chamber = "House"))
  }) %>% flatten()
  sen <- read_csv(file.path(DIR_FROZEN, "senate_races.csv"))
  senate_pages <- map(seq_len(nrow(sen)), function(i) {
    nm <- str_replace_all(sen$state_name[i], " ", "_")
    list(page = sprintf("2026_United_States_Senate_%selection_in_%s", if (sen$special[i]) "special_" else "", nm), chamber = "Senate")
  })
  pages <- c(house_pages, senate_pages)
}

res <- map_dfr(pages, function(p) {
  dest <- file.path(RAWR, paste0(str_replace_all(p$page, "[^A-Za-z0-9]+", "_"), ".json"))
  r <- results_from_page(p$page, dest, p$chamber)
  msg("%-80s %s", p$page, if (is.null(r)) "sin tabla" else sprintf("%d carreras", nrow(r)))
  r
})

if (nrow(res)) {
  house <- res %>% filter(chamber == "House")
  nat <- tibble(race_id = "US_HOUSE_VOTE", chamber = "National", state = "US",
                margin_actual = 100 * (sum(house$votes_D) - sum(house$votes_R)) / (sum(house$votes_D) + sum(house$votes_R)),
                winner = NA_character_, n_districts = nrow(house))
  out <- bind_rows(res, nat)
  dest <- if (PRUEBA) file.path(DIR_OUT, "resultados_prueba2024.csv") else file.path(DIR_OUT, "resultados.csv")
  write_csv(out, dest)
  msg("Resultados: %d carreras de la Camara, %d del Senado; voto popular (2 partidos, distritos con tabla) %+.2f -> %s",
      nrow(house), sum(res$chamber == "Senate"), nat$margin_actual, dest)
  print(as.data.frame(res %>% select(race_id, margin_actual, winner, winner_name, pct_D, pct_R) %>% head(12)))
} else msg("Todavia no hay tablas de resultados")
