# 02_clean.R -- convierte las fuentes crudas en CSV limpios y congelados (data/frozen/)
# Salidas:
#   districts.csv        435 distritos: PVI 2026, votos 2020/2024, incumbencia, candidatos
#   senate_races.csv     35 escanos: PVI estatal, incumbente, candidatos
#   polls_generic.csv    encuestas nacionales (Wikipedia + Poliwave)
#   polls_senate.csv     encuestas por carrera senatorial (Poliwave)
#   polls_house.csv      encuestas por distrito (Poliwave)
#   hist_polls_538.csv   archivo historico 1998-2024 con resultado real (calibracion)
#   benchmark_*.csv      promedios de otros agregadores (lineas base)
source("R/00_setup.R")

args  <- commandArgs(trailingOnly = TRUE)
STAMP <- if (length(args)) args[1] else max(list.files(DIR_RAW))
RAW   <- file.path(DIR_RAW, STAMP)
msg("Limpiando %s", RAW)

# ============================================================================
# 1. Cook PVI 2026
# ============================================================================
cook <- read_tsv(file.path(RAW, "cook_pvi_2026.tsv"), col_types = cols(.default = "c")) %>%
  filter(str_detect(DIST, "^[A-Z]{2}-(\\d{2}|AL)$")) %>%
  transmute(
    district     = DIST,
    state        = str_sub(DIST, 1, 2),
    incumbent_raw = Incumbent,
    biden_2020   = parse_number(`Biden 2020`),
    trump_2020   = parse_number(`Trump 2020`),
    harris_2024  = parse_number(`Harris 2024`),
    trump_2024   = parse_number(`Trump 2024`),
    pvi_2026_lab = `2026 PVI`,
    pvi_2026     = as.numeric(`2026 Raw PVI`),
    pvi_2025     = as.numeric(`2025 Raw PVI`),
    pvi_shift    = as.numeric(`Raw PVI Shift`)
  ) %>%
  mutate(
    region       = unname(REGION[state]),
    inc_party    = str_match(incumbent_raw, "\\(([DRI])\\)\\s*$")[, 2],
    open_seat    = str_detect(incumbent_raw, "^(OPEN|VACANT|NEW)"),
    incumbent    = if_else(open_seat, NA_character_,
                           str_trim(str_remove(incumbent_raw, "\\s*\\([DRI]\\)\\s*$"))),
    margin_2024  = 100 * (harris_2024 - trump_2024) / (harris_2024 + trump_2024),
    margin_2020  = 100 * (biden_2020 - trump_2020) / (biden_2020 + trump_2020),
    redistricted = state %in% REDISTRICTED_2026 | (abs(pvi_shift) > 0.05 & !is.na(pvi_shift))
  )
# Missouri vota con el mapa de 2022 (ver 00_setup.R): se usa el PVI 2025 y no cuenta como rediseñado
cook <- cook %>%
  mutate(pvi_2026_lab = if_else(state %in% OLD_MAP_STATES,
                                if_else(pvi_2025 >= 0, sprintf("D+%.0f", pvi_2025), sprintf("R+%.0f", -pvi_2025)), pvi_2026_lab),
         pvi_2026     = if_else(state %in% OLD_MAP_STATES, pvi_2025, pvi_2026),
         pvi_shift    = if_else(state %in% OLD_MAP_STATES, 0, pvi_shift),
         redistricted = if_else(state %in% OLD_MAP_STATES, FALSE, redistricted))
stopifnot(nrow(cook) == 435, all(!is.na(cook$pvi_2026)))
msg("Cook: %d distritos, %d abiertos, %d en estados rediseñados",
    nrow(cook), sum(cook$open_seat), sum(cook$state %in% REDISTRICTED_2026))

# ============================================================================
# 2. Wikipedia -- utilidades
# ============================================================================
wiki_tables <- function(json_file) {
  txt <- fromJSON(json_file)$parse$text
  html_elements(read_html(txt), "table.wikitable")
}


# ============================================================================
# 3. Wikipedia -- Camara: candidatos por distrito
# ============================================================================
house_tabs <- wiki_tables(file.path(RAW, "wiki_house.json"))
house_cands <- map_dfr(house_tabs, function(tb) {
  hdr <- html_text2(html_elements(tb, "tr:first-child th"))
  if (!any(str_detect(hdr, "^District")) || !any(str_detect(hdr, "^Candidates"))) return(NULL)
  df <- as.data.frame(html_table(tb, fill = TRUE), check.names = FALSE)
  sub <- str_squish(as.character(df[1, ]))
  names(df) <- make.unique(sub); df <- df[-1, , drop = FALSE]
  loc_col  <- which(str_detect(names(df), "^Location"))[1]
  cand_col <- which(str_detect(names(df), "^Candidates"))[1]
  stat_col <- which(str_detect(names(df), "^Status"))[1]
  if (any(is.na(c(loc_col, cand_col)))) return(NULL)
  tibble(location = str_squish(df[[loc_col]]),
         status = if (is.na(stat_col)) NA_character_ else clean_ref(df[[stat_col]]),
         candidates = df[[cand_col]])
}) %>%
  mutate(m = str_match(location, "^(.*?)\\s+(\\d+|at-large)$"),
         state = unname(STATE_ABBR[m[, 2]]),
         num   = if_else(m[, 3] == "at-large", "AL", sprintf("%02d", suppressWarnings(as.integer(m[, 3])))),
         district = paste0(state, "-", num)) %>%
  filter(!is.na(state), !is.na(num)) %>%
  select(-m, -location) %>%
  distinct(district, .keep_all = TRUE) %>%
  mutate(parties = map(candidates, parties_in),
         has_D = map_lgl(parties, ~ any(.x == "Democratic")),
         has_R = map_lgl(parties, ~ any(.x == "Republican")),
         n_cands = map_int(parties, length),
         cand_D = map_chr(candidates, cand_by_party, party = "Democratic"),
         cand_R = map_chr(candidates, cand_by_party, party = "Republican"),
         wiki_status = status) %>%
  select(district, has_D, has_R, n_cands, cand_D, cand_R, wiki_status, wiki_candidates = candidates)
msg("Wikipedia Camara: %d distritos con candidatos (%d sin D, %d sin R)",
    nrow(house_cands), sum(!house_cands$has_D), sum(!house_cands$has_R))

districts <- cook %>%
  left_join(house_cands, by = "district") %>%
  mutate(has_D = coalesce(has_D, TRUE), has_R = coalesce(has_R, TRUE),
         uncontested = xor(has_D, has_R) & !(has_D & has_R)) %>%
  arrange(district)
# Casos especiales documentados (ver README):
#  CA-06: el incumbente Kevin Kiley (ex-R) compite como independiente contra Richard Pan (D) en el mapa nuevo.
#         Se modela como carrera competida con Kiley en el lado "R" (caucus republicano) y con ventaja de incumbencia.
districts <- districts %>%
  mutate(inc_party_model = inc_party,
         has_R = if_else(district == "CA-06", TRUE, has_R),
         uncontested = if_else(district == "CA-06", FALSE, uncontested),
         cand_R = if_else(district == "CA-06", paste0(incumbent, " (independiente, ex-R)"), cand_R),
         inc_party_model = if_else(district == "CA-06", "R", inc_party_model))
missing_wiki <- districts$district[is.na(districts$n_cands)]
if (length(missing_wiki)) msg("Sin candidatos en Wikipedia (se asume D vs R): %s", paste(missing_wiki, collapse = " "))

# ============================================================================
# 4. Wikipedia -- Senado
# ============================================================================
sen_tabs <- wiki_tables(file.path(RAW, "wiki_senate.json"))
sen_tab <- keep(sen_tabs, function(tb) {
  hdr <- html_text2(html_elements(tb, "tr:first-child th"))
  any(str_detect(hdr, "^Constituency")) && any(str_detect(hdr, "^(Results|Status)")) && any(str_detect(hdr, "^Candidates"))
})
stopifnot(length(sen_tab) >= 1)
senate_races <- map_dfr(sen_tab, function(tb) {
  hdr <- html_text2(html_elements(tb, "tr:first-child th"))
  is_special_tab <- any(str_detect(hdr, "^Status")) && !any(str_detect(hdr, "^Results"))
  sdf <- as.data.frame(html_table(tb, fill = TRUE), check.names = FALSE)
  sub <- str_squish(as.character(sdf[1, ])); names(sdf) <- make.unique(sub); sdf <- sdf[-1, , drop = FALSE]
  col <- function(pat) {
    i <- which(str_detect(names(sdf), pat))[1]
    if (is.na(i)) rep(NA_character_, nrow(sdf)) else as.character(sdf[[i]])
  }
  tibble(
    state_raw   = str_squish(col("^State")),
    pvi_lab     = clean_ref(col("^PVI")),
    senator     = clean_ref(col("^Senator")),
    inc_party_name = str_squish(col("^Party")),
    last_race   = clean_ref(col("^Last race")),
    results     = clean_ref(col("^(Results|Status)")),
    candidates  = col("^Candidates"),
    from_special_table = is_special_tab
  )
}) %>%
  mutate(special    = from_special_table | str_detect(state_raw, regex("special", ignore_case = TRUE)),
         state_name = str_squish(str_remove(state_raw, "\\(.*\\)")),
         state      = unname(STATE_ABBR[state_name]),
         race_id    = paste0(state, if_else(special, "-S", "")),
         pvi        = pvi_to_num(pvi_lab),
         inc_party  = case_when(str_detect(inc_party_name, "Democrat|DFL") ~ "D",
                                str_detect(inc_party_name, "Republican") ~ "R",
                                TRUE ~ "I"),
         open_seat  = str_detect(results, regex("retir|not seeking|lost|resign|defeated|did not", ignore_case = TRUE)),
         region     = unname(REGION[state]),
         parties    = map(candidates, parties_in),
         has_D      = map_lgl(parties, ~ any(.x == "Democratic")),
         has_R      = map_lgl(parties, ~ any(.x == "Republican")),
         cand_D     = map_chr(candidates, cand_by_party, party = "Democratic"),
         cand_R     = map_chr(candidates, cand_by_party, party = "Republican"),
         cand_I     = map_chr(candidates, cand_by_party, party = "Independent"),
         last_margin_dir = str_extract(last_race, "[DRI]$"),
         last_pct   = suppressWarnings(parse_number(last_race))) %>%
  filter(!is.na(state)) %>%
  select(race_id, state, state_name, special, region, pvi, pvi_lab, senator, inc_party, open_seat,
         has_D, has_R, cand_D, cand_R, cand_I, last_pct, last_margin_dir, results, wiki_candidates = candidates) %>%
  arrange(race_id)
msg("Wikipedia Senado: %d carreras (%d especiales, %d abiertas)",
    nrow(senate_races), sum(senate_races$special), sum(senate_races$open_seat))
stopifnot(nrow(senate_races) == 35)

# ============================================================================
# 5. Wikipedia -- generic ballot nacional
# ============================================================================

us_tabs <- wiki_tables(file.path(RAW, "wiki_us2026.json"))
gb_tabs <- keep(us_tabs, function(tb) {
  hdr <- html_text2(html_elements(tb, "tr:first-child th"))
  any(str_detect(hdr, "^Poll source")) && any(str_detect(hdr, "^Democratic"))
})
polls_generic_wiki <- map_dfr(gb_tabs, function(tb) {
  df <- as.data.frame(html_table(tb, fill = TRUE), check.names = FALSE)
  names(df) <- str_squish(str_remove_all(names(df), "\\[.*?\\]"))
  tibble(pollster_raw = df[["Poll source"]],
         dates = df[[which(str_detect(names(df), "^Date"))[1]]],
         sample = df[[which(str_detect(names(df), "^Sample"))[1]]],
         dem = df[["Democratic"]], rep = df[["Republican"]])
}) %>%
  mutate(pollster = clean_ref(pollster_raw),
         partisan = str_match(pollster, "\\(([DR])\\)")[, 2],
         pollster = str_squish(str_remove(pollster, "\\s*\\([DR]\\)")),
         n   = parse_number(str_remove(sample, "\\(.*\\)")),
         pop = str_match(sample, "\\((LV|RV|A|V)\\)")[, 2],
         pop = if_else(pop == "V", "RV", pop),            # "(V)" = votantes sin filtro: se trata como RV
         dem = parse_number(as.character(dem)), rep = parse_number(as.character(rep)),
         source = "wikipedia") %>%
  bind_cols(parse_wiki_dates(.$dates)) %>%
  filter(!is.na(dem), !is.na(rep), !is.na(end)) %>%
  mutate(margin = dem - rep) %>%
  select(source, pollster, partisan, start, end, n, pop, dem, rep, margin)
msg("Wikipedia generic ballot: %d filas (%d LV, %d RV, %d A)", nrow(polls_generic_wiki),
    sum(polls_generic_wiki$pop == "LV", na.rm = TRUE), sum(polls_generic_wiki$pop == "RV", na.rm = TRUE),
    sum(polls_generic_wiki$pop == "A", na.rm = TRUE))

# agregadores (linea base)
agg_tab <- keep(us_tabs, function(tb) any(str_detect(html_text2(html_elements(tb, "tr:first-child th")), "aggregation")))
benchmark_generic <- if (length(agg_tab)) {
  df <- as.data.frame(html_table(agg_tab[[1]], fill = TRUE), check.names = FALSE)
  names(df) <- c("aggregator", "dates", "updated", "rep", "dem", "other", "margin")[seq_len(ncol(df))]
  df %>% transmute(aggregator = clean_ref(aggregator), updated = clean_ref(updated),
                   rep = parse_number(as.character(rep)), dem = parse_number(as.character(dem)), margin = dem - rep)
} else tibble()

# ============================================================================
# 6. Poliwave -- generic, Senado, Camara
# ============================================================================
parse_pw_dates <- function(x) {
  x <- str_replace_all(x, "[–—]", "-")
  parts <- str_split_fixed(x, "\\s*-\\s*", 2)
  end <- suppressWarnings(mdy(if_else(parts[, 2] == "", parts[, 1], parts[, 2])))
  start <- suppressWarnings(mdy(parts[, 1]))
  tibble(start = start, end = end)
}
parse_pw_header <- function(file) {
  # tabla visible: candidatos (th con --party-color) -> partido
  h <- read_html(file); xml_remove(xml_find_all(h, "//comment()"))
  tbs <- html_elements(h, "table"); if (!length(tbs)) return(NULL)
  ths <- html_elements(tbs[[1]], "thead th")
  th_txt <- str_squish(html_text2(ths)); th_sty <- html_attr(ths, "style")
  idx <- which(!is.na(th_sty) & str_detect(th_sty, "party-color"))
  if (!length(idx)) return(NULL)
  tibble(candidate = th_txt[idx], party = color_to_party(th_sty[idx])) %>%
    mutate(party = case_when(candidate == "DEM" ~ "D", candidate == "REP" ~ "R",
                             candidate %in% c("N/A", "UND") ~ "UND", candidate == "WILL_NOT_VOTE" ~ "WNV",
                             TRUE ~ party),
           key = option_key(candidate))
}
parse_poliwave_embedded <- function(file) {
  # Poliwave incrusta en la pagina (SvelteKit) el historial completo de encuestas de la carrera,
  # no solo las 20 visibles. Se extraen con una expresion regular sobre el objeto JS.
  g <- paste(readLines(file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  rx <- paste0('\\{date:"(\\d{4}-\\d{2}-\\d{2})",pollster:"([^"]*)",pollsterID:\\d+,question:"([^"]*)",',
               'demoFilter:"([^"]*)",regionFilter:"([^"]*)",options:\\{([^}]*)\\},sampleSize:(\\d+|null),serialID:(\\d+),',
               'pollUrl:(?:"[^"]*"|null),startDate:("[^"]*"|null),endDate:"([^"]*)",method:"[^"]*",moe:[^,]*,',
               'isRolling:[^,]*,rollingPeriod:[^,]*,weight:[^,]*,ratingWeight:[^,]*,population:"([^"]*)"\\}')
  m <- str_match_all(g, rx)[[1]]
  if (!nrow(m)) return(NULL)
  d <- tibble(pollster_raw = m[, 3], question = m[, 4], demo = m[, 5], region_f = m[, 6],
              options = m[, 7], n = suppressWarnings(as.numeric(m[, 8])),
              start = ymd(str_remove_all(m[, 10], '"'), quiet = TRUE), end = ymd(m[, 11], quiet = TRUE),
              pop_raw = m[, 12]) %>%
    filter(demo == "All", region_f == "All") %>%
    distinct(pollster_raw, start, end, options, pop_raw, .keep_all = TRUE) %>%
    mutate(poll_id = row_number())
  opts <- str_match_all(d$options, "([A-Z0-9_]+):(-?[0-9.]+)")
  d %>%
    mutate(opt = map(opts, ~ tibble(key = str_remove(.x[, 2], "^CAND_"), pct = as.numeric(.x[, 3])))) %>%
    select(-options, -demo, -region_f) %>%
    unnest(opt) %>%
    mutate(pop = case_when(str_detect(pop_raw, "^(LV|Likely)") ~ "LV",
                           str_detect(pop_raw, "^(RV|Registered|V\\b|Voters)") ~ "RV",
                           str_detect(pop_raw, "^(A\\b|Adults?)") ~ "A", TRUE ~ NA_character_),
           partisan = str_match(pollster_raw, "\\(([DR])\\)")[, 2],
           pollster = str_squish(str_remove(pollster_raw, "\\s*\\([DR]\\).*$"))) %>%
    select(-pop_raw, -pollster_raw)
}
parse_pw_table <- function(file, hdr) {
  # respaldo: filas visibles de la tabla (20 mas recientes) cuando el JS embebido usa referencias
  h <- read_html(file); xml_remove(xml_find_all(h, "//comment()"))
  tbs <- html_elements(h, "table"); if (!length(tbs) || is.null(hdr)) return(NULL)
  tb <- tbs[[1]]; ths <- html_elements(tb, "thead th")
  th_txt <- str_squish(html_text2(ths)); th_sty <- html_attr(ths, "style")
  cand_idx <- which(!is.na(th_sty) & str_detect(th_sty, "party-color"))
  rows <- html_elements(tb, "tbody tr")
  out <- map_dfr(seq_along(rows), function(i) {
    tds <- html_elements(rows[[i]], "td"); if (length(tds) != length(ths)) return(NULL)
    txt <- str_squish(html_text2(tds))
    pollster_raw <- str_squish(html_text2(html_element(tds[[which(th_txt == "Pollster")]], "a")))
    if (is.na(pollster_raw)) pollster_raw <- txt[th_txt == "Pollster"][1]
    sample <- txt[th_txt == "Sample"][1]
    dates <- str_split_fixed(str_replace_all(txt[th_txt == "Date"][1], "[\u2013\u2014]", "-"), "\\s*-\\s*", 2)
    tibble(poll_id = i, question = NA_character_,
           start = suppressWarnings(mdy(dates[1])),
           end   = suppressWarnings(mdy(if (dates[2] == "") dates[1] else dates[2])),
           n = parse_number(str_extract(sample, "^[0-9,]+")), pop = str_extract(sample, "\\b(LV|RV|A)\\b"),
           partisan = str_match(pollster_raw, "\\(([DR])\\)")[, 2],
           pollster = str_squish(str_remove(pollster_raw, "\\s*\\([DR]\\).*$")),
           key = hdr$key, party = hdr$party,
           pct = suppressWarnings(as.numeric(str_extract(txt[cand_idx], "[0-9.]+"))))
  })
  if (!nrow(out)) NULL else out
}
pw_race_polls <- function(file) {
  hdr <- parse_pw_header(file)
  emb <- parse_poliwave_embedded(file)
  if (is.null(emb) || !nrow(emb)) return(parse_pw_table(file, hdr))
  emb %>%
    mutate(party = match_key_to_header(key, hdr),
           party = case_when(!is.na(party) ~ party,
                             key == "DEM" ~ "D", key == "REP" ~ "R",
                             key %in% c("OTH", "UND", "N_A", "WILL_NOT_VOTE", "EXHAUSTED") ~ "OTH",
                             TRUE ~ "UNKNOWN"))
}
pw_wide <- function(df) {
  # una fila por encuesta: dem, rep, ind (suma de independientes), oth
  if (is.null(df) || !nrow(df)) return(tibble())
  df %>%
    mutate(party = if_else(party %in% c("D", "R", "I"), party, "OTH")) %>%
    group_by(poll_id, pollster, partisan, question, start, end, n, pop, party) %>%
    summarise(pct = sum(pct, na.rm = TRUE), .groups = "drop") %>%
    pivot_wider(names_from = party, values_from = pct) %>%
    mutate(dem = if ("D" %in% names(.)) D else NA_real_,
           rep = if ("R" %in% names(.)) R else NA_real_,
           ind = if ("I" %in% names(.)) I else NA_real_) %>%
    select(pollster, partisan, question, start, end, n, pop, dem, rep, ind) %>%
    mutate(margin = dem - rep)
}

pw_generic <- pw_race_polls(file.path(RAW, "poliwave", "generic.html")) %>% pw_wide() %>%
  mutate(source = "poliwave", .before = 1) %>% select(-question)
msg("Poliwave generic: %d encuestas (historial embebido)", nrow(pw_generic))

# union Wikipedia + Poliwave, eliminando duplicados (misma fecha final, poblacion y cifras)
polls_generic <- bind_rows(polls_generic_wiki, pw_generic) %>%
  mutate(key = paste(end, pop, round(dem), round(rep))) %>%
  group_by(key) %>% arrange(source != "wikipedia") %>% slice(1) %>% ungroup() %>%
  select(-key) %>% arrange(desc(end), pollster)
msg("Generic ballot combinado: %d encuestas unicas", nrow(polls_generic))

sen_files <- list.files(file.path(RAW, "poliwave", "senate"), full.names = TRUE)
polls_senate_long <- map_dfr(sen_files, function(f) {
  d <- pw_race_polls(f); if (is.null(d) || !nrow(d)) return(NULL)
  d %>% mutate(state = str_remove(basename(f), "\\.html$"), .before = 1)
})
# candidatos por carrera (nombre y partido) segun Poliwave
senate_cands_pw <- polls_senate_long %>% filter(!key %in% c("OTH", "UND", "N_A", "WILL_NOT_VOTE")) %>%
  distinct(state, key, party) %>%
  group_by(state) %>% summarise(pw_candidates = paste0(key, " (", party, ")", collapse = "; "), .groups = "drop")
polls_senate_wide <- polls_senate_long %>% group_by(state) %>% group_modify(~ pw_wide(.x)) %>% ungroup() %>%
  # Poliwave no distingue la especial de Florida/Ohio en la URL: es la unica carrera del estado en 2026
  mutate(race_id = if_else(state %in% senate_races$state[senate_races$special], paste0(state, "-S"), state), .before = 1) %>%
  arrange(race_id, desc(end))
msg("Poliwave Senado: %d encuestas en %d carreras", nrow(polls_senate_wide), n_distinct(polls_senate_wide$race_id))

house_files <- list.files(file.path(RAW, "poliwave", "house"), full.names = TRUE)
polls_house_long <- map_dfr(house_files, function(f) {
  d <- pw_race_polls(f); if (is.null(d) || !nrow(d)) return(NULL)
  d %>% mutate(district = str_remove(basename(f), "\\.html$"), .before = 1)
}) %>%
  # CA-06: Kiley (independiente, ex-R) ocupa el lado R del duelo (ver nota en la seccion 3)
  mutate(party = if_else(district == "CA-06" & str_detect(key, "KILEY"), "R", party))
polls_house_wide <- polls_house_long %>% group_by(district) %>% group_modify(~ pw_wide(.x)) %>% ungroup() %>%
  arrange(district, desc(end))

msg("Poliwave Camara: %d encuestas en %d distritos", nrow(polls_house_wide), n_distinct(polls_house_wide$district))

# benchmark Poliwave Senado (promedio y pronostico por estado)
pw_sen_idx <- read_html(file.path(RAW, "poliwave", "senate_index.html"))
xml_remove(xml_find_all(pw_sen_idx, "//comment()"))
pw_sen_tabs <- html_elements(pw_sen_idx, "table")
benchmark_pw_senate <- map_dfr(pw_sen_tabs, function(tb) {
  cap <- html_text2(html_element(tb, "caption"))
  if (is.na(cap) || !str_detect(cap, "Polling in each")) return(NULL)
  df <- as.data.frame(html_table(tb, fill = TRUE), check.names = FALSE)
  names(df) <- c("state_name", "dem", "ind", "rep", "poll_lead", "forecast", "n_polls", "newest")[seq_len(ncol(df))]
  df %>% transmute(state = unname(STATE_ABBR[state_name]), dem = parse_number(as.character(dem)), ind = parse_number(as.character(ind)),
                   rep = parse_number(as.character(rep)), poll_lead, forecast, n_polls = parse_number(as.character(n_polls)), newest)
})

# ============================================================================
# 7. FiveThirtyEight historico
# ============================================================================
hist <- read_csv(file.path(RAW, "fte_raw_polls.csv"), col_types = cols(.default = "c")) %>%
  filter(type_simple %in% c("House-G", "House-G-US", "Sen-G", "Gov-G", "Pres-G")) %>%
  transmute(cycle = as.integer(cycle), location, type = type_simple, race, pollster, partisan,
            methodology, polldate = ymd(polldate), electiondate = ymd(electiondate),
            time_to_election = as.integer(time_to_election), samplesize = as.numeric(samplesize),
            cand1_party, cand2_party, cand1_pct = as.numeric(cand1_pct), cand2_pct = as.numeric(cand2_pct),
            cand1_actual = as.numeric(cand1_actual), cand2_actual = as.numeric(cand2_actual),
            margin_poll = as.numeric(margin_poll), margin_actual = as.numeric(margin_actual)) %>%
  mutate(# margen D-R (positivo = D), independientemente del orden de candidatos
         sgn = case_when(cand1_party == "DEM" & cand2_party == "REP" ~ 1,
                         cand1_party == "REP" & cand2_party == "DEM" ~ -1, TRUE ~ NA_real_),
         margin_poll_d = sgn * margin_poll, margin_actual_d = sgn * margin_actual,
         error_d = margin_poll_d - margin_actual_d,          # >0: la encuesta exagero a D
         state = if_else(type == "House-G-US", "US", str_sub(location, 1, 2)))
msg("538 historico: %d encuestas, ciclos %s", nrow(hist), paste(range(hist$cycle), collapse = "-"))

# ============================================================================
# 7b. Calificaciones de expertos (Cook, Sabato, Inside Elections, DDHQ...) via Wikipedia
# ============================================================================
AT_LARGE <- c("AK", "DE", "ND", "SD", "VT", "WY")
parse_state_ratings <- function(file, st) {
  # recorre encabezados y tablas en orden; cada tabla "Source | Ranking | As of" pertenece al ultimo "District N"
  txt <- fromJSON(file)$parse$text
  h <- read_html(txt)
  nodes <- xml_find_all(h, "//h2|//h3|//h4|//table[contains(@class,'wikitable')]")
  cur <- if (st %in% AT_LARGE) paste0(st, "-AL") else NA_character_
  out <- list()
  for (nd in nodes) {
    nm <- xml_name(nd)
    if (nm %in% c("h2", "h3", "h4")) {
      t <- str_squish(xml_text(nd))
      if (str_detect(t, regex("^District \\d+$|at-large", ignore_case = TRUE))) {
        num <- str_extract(t, "\\d+")
        cur <- if (is.na(num)) paste0(st, "-AL") else sprintf("%s-%02d", st, as.integer(num))
      } else if (nm == "h2" && !st %in% AT_LARGE) cur <- NA_character_
    } else {
      hdr <- str_squish(xml_text(xml_find_all(nd, ".//tr[1]/th")))
      if (length(hdr) >= 2 && hdr[1] == "Source" && str_detect(hdr[2], "^Ranking")) {
        for (r in xml_find_all(nd, ".//tr[position()>1]")) {
          cells <- str_squish(xml_text(xml_find_all(r, "./td|./th")))
          if (length(cells) >= 3)
            out[[length(out) + 1]] <- tibble(district = cur, source = cells[1], ranking = cells[2], as_of = cells[length(cells)])
        }
      }
    }
  }
  bind_rows(out)
}
state_files <- list.files(file.path(RAW, "wiki_states"), full.names = TRUE)
ratings_house_long <- map_dfr(state_files, ~ parse_state_ratings(.x, str_sub(basename(.x), 1, 2))) %>%
  filter(!is.na(district)) %>%
  mutate(source = clean_ref(source), ranking = clean_ref(ranking), as_of = clean_ref(as_of),
         rating_margin = rating_to_margin(ranking),
         as_of_date = suppressWarnings(mdy(as_of, quiet = TRUE))) %>%
  filter(!is.na(rating_margin))
ratings_house <- ratings_house_long %>% group_by(district) %>%
  summarise(rating_margin = mean(rating_margin), n_raters = n(),
            rating_consensus = names(sort(table(str_remove(ranking, "\\s*\\(flip\\)")), decreasing = TRUE))[1],
            rating_latest = suppressWarnings(max(as_of_date, na.rm = TRUE)),
            raters = paste(source, collapse = "; "), .groups = "drop")
msg("Calificaciones Camara: %d distritos (%d calificadores distintos)", nrow(ratings_house), n_distinct(ratings_house_long$source))

# Senado: tabla de Wikipedia con ~12 calificadores
sen_rat_tab <- keep(sen_tabs, function(tb) { tt <- html_text2(tb); str_detect(tt, "Sabato") && str_detect(tt, "Cook") && str_detect(tt, "Tossup|Toss-up") })
ratings_senate_long <- if (length(sen_rat_tab)) {
  rows <- html_elements(sen_rat_tab[[1]], "tr")
  hdr <- str_squish(html_text2(html_elements(rows[[2]], "th")))
  # las 4 primeras columnas son State, PVI, Senator, Last election; el resto son calificadores "Cook Oct 30,2026[29]"
  raters <- clean_ref(str_remove(hdr[-(1:4)], "\\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec).*$"))
  map_dfr(rows[-(1:2)], function(r) {
    cells <- str_squish(html_text2(html_elements(r, "td, th")))
    nr <- length(cells)
    if (nr != length(raters) + 4 || str_detect(cells[1], "^Overall")) return(NULL)
    tibble(state_raw = clean_ref(cells[1]), source = raters, ranking = clean_ref(cells[5:nr]))
  })
} else tibble()
ratings_senate <- ratings_senate_long %>%
  mutate(state_name = str_squish(str_remove(state_raw, "\\(.*\\)")), state = unname(STATE_ABBR[state_name]),
         special = str_detect(state_raw, regex("special", ignore_case = TRUE)) | state %in% senate_races$state[senate_races$special],
         race_id = if_else(special, paste0(state, "-S"), state),
         rating_margin = rating_to_margin(ranking)) %>%
  filter(!is.na(state), !is.na(rating_margin)) %>%
  group_by(race_id) %>%
  summarise(rating_margin = mean(rating_margin), n_raters = n(),
            rating_consensus = names(sort(table(str_remove(ranking, "\\s*\\(flip\\)")), decreasing = TRUE))[1], .groups = "drop")
msg("Calificaciones Senado: %d carreras", nrow(ratings_senate))

# ============================================================================
# 7c. Calidad de encuestadores (ratings de 538, 2024) emparejada por nombre
# ============================================================================
pr <- read_csv(file.path(RAW, "fte_pollster_ratings.csv"), col_types = cols(.default = "c")) %>%
  transmute(fte_pollster = pollster, numeric_grade = as.numeric(numeric_grade), pollscore = as.numeric(POLLSCORE),
            n_polls_fte = as.numeric(number_polls_pollster_total))
STOP_TOKENS <- c("the", "and", "inc", "llc", "news", "poll", "polls", "polling", "research", "group", "college", "university",
                 "insights", "strategies", "strategy", "public", "opinion", "survey", "surveys", "center", "institute",
                 "associates", "partners", "communications", "media", "for", "company", "analytics", "data", "political", "report")
name_tokens <- function(x) {
  x <- str_to_lower(iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT", sub = ""))
  t <- str_split(str_squish(str_replace_all(x, "[^a-z0-9 ]", " ")), " ")[[1]]
  unique(t[nchar(t) >= 3 & !t %in% STOP_TOKENS])
}
pr_tokens <- map(pr$fte_pollster, name_tokens)
match_pollster <- function(name) {
  t <- name_tokens(name); if (!length(t)) return(NA_integer_)
  shared <- map_int(pr_tokens, ~ length(intersect(t, .x)))
  score  <- map_dbl(pr_tokens, ~ if (!length(.x)) 0 else length(intersect(t, .x)) / length(union(t, .x)))
  single <- map_lgl(pr_tokens, ~ length(.x) == 1)
  cand <- which(shared >= 1 & (score >= 0.5 | shared >= 2 | length(t) == 1 | single))
  if (!length(cand)) return(NA_integer_)
  cand[which.max(score[cand] + coalesce(pr$n_polls_fte[cand], 0) / 1e5)]
}
all_pollsters <- sort(unique(c(polls_generic$pollster, polls_senate_wide$pollster, polls_house_wide$pollster)))
pollster_quality <- tibble(pollster = all_pollsters, idx = map_int(all_pollsters, match_pollster)) %>%
  mutate(fte_pollster = pr$fte_pollster[idx], numeric_grade = pr$numeric_grade[idx], pollscore = pr$pollscore[idx],
         # peso de calidad: 0.6 (grado 0) a 1.0 (grado 3); desconocidos 0.8
         w_quality = if_else(is.na(numeric_grade), 0.8, 0.6 + 0.4 * numeric_grade / 3)) %>% select(-idx)
msg("Calidad de encuestadores: %d de %d emparejados con 538", sum(!is.na(pollster_quality$fte_pollster)), nrow(pollster_quality))

# ============================================================================
# 7d. Mercados de prediccion (Polymarket) como linea base (d)
# ============================================================================
pm_price <- function(file) {
  if (!file.exists(file)) return(NA_real_)
  ev <- fromJSON(file, simplifyVector = FALSE)
  if (!length(ev)) return(NA_real_)
  m <- keep(ev[[1]]$markets, ~ str_detect(.x$question %||% "", "Democratic Party"))
  if (!length(m)) return(NA_real_)
  as.numeric(fromJSON(m[[1]]$outcomePrices)[1])
}
benchmark_polymarket <- tibble(chamber = c("House", "Senate"),
                               p_dem = c(pm_price(file.path(RAW, "polymarket_house.json")), pm_price(file.path(RAW, "polymarket_senate.json"))),
                               fetched = STAMP, source = "gamma-api.polymarket.com (which-party-will-win-the-house/senate-in-2026)")
print(benchmark_polymarket)

# ============================================================================
# 8. Guardar
# ============================================================================
write_csv(ratings_house,      file.path(DIR_FROZEN, "ratings_house.csv"))
write_csv(ratings_house_long, file.path(DIR_FROZEN, "ratings_house_long.csv"))
write_csv(ratings_senate,     file.path(DIR_FROZEN, "ratings_senate.csv"))
write_csv(pollster_quality,   file.path(DIR_FROZEN, "pollster_quality.csv"))
write_csv(benchmark_polymarket, file.path(DIR_FROZEN, "benchmark_polymarket.csv"))
write_csv(districts %>% select(-wiki_candidates), file.path(DIR_FROZEN, "districts.csv"))
write_csv(senate_races %>% left_join(senate_cands_pw, by = "state") %>% select(-wiki_candidates),
          file.path(DIR_FROZEN, "senate_races.csv"))
write_csv(polls_generic,      file.path(DIR_FROZEN, "polls_generic.csv"))
write_csv(polls_senate_wide,  file.path(DIR_FROZEN, "polls_senate.csv"))
write_csv(polls_house_wide,   file.path(DIR_FROZEN, "polls_house.csv"))
write_csv(hist,               file.path(DIR_FROZEN, "hist_polls_538.csv"))
write_csv(benchmark_generic,  file.path(DIR_FROZEN, "benchmark_generic_aggregators.csv"))
write_csv(benchmark_pw_senate, file.path(DIR_FROZEN, "benchmark_poliwave_senate.csv"))
writeLines(STAMP, file.path(DIR_FROZEN, "RAW_SNAPSHOT.txt"))
msg("CSV congelados escritos en %s", DIR_FROZEN)
