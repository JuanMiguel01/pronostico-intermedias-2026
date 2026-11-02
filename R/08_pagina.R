# 08_pagina.R -- arma la pagina HTML del pronostico (output/pronostico.html) a partir de los entregables:
# inyecta un bloque JSON con los datos en la plantilla docs/plantilla_pagina.html, que dibuja tablas y graficos.
source("R/00_setup.R")

pred <- read_csv(file.path(DIR_OUT, "predicciones.csv"))
rj   <- fromJSON(file.path(DIR_OUT, "resumen.json"))
ms   <- readRDS(file.path(DIR_OUT, "model_state.rds"))
dist <- read_csv(file.path(DIR_OUT, "distribucion_escanos.csv"))
lb   <- read_csv(file.path(DIR_OUT, "lineas_base.csv"))
hashes <- read_lines(file.path(DIR_OUT, "SHA256SUMS.txt"))
snapshot <- read_lines(file.path(DIR_FROZEN, "RAW_SNAPSHOT.txt"))[1]
sen_info <- read_csv(file.path(DIR_FROZEN, "senate_races.csv")) %>% select(race_id, state_name)
last_poll <- max(c(read_csv(file.path(DIR_FROZEN, "polls_generic.csv"))$end,
                   read_csv(file.path(DIR_FROZEN, "polls_senate.csv"))$end), na.rm = TRUE)

res_by <- function(v) as.list(rj$resumen[rj$resumen$version == v, ])
senate <- pred %>% filter(chamber == "Senate") %>% left_join(sen_info, by = "race_id") %>%
  transmute(race_id, state_name, cand = cand_D, cand_R, p_nonR, p_ind, margin = margin_median, lo = margin_lo80, hi = margin_hi80,
            n_polls = coalesce(n_polls, 0), rating = rating_consensus, ind = p_ind > 0, inc_party, open_seat) %>%
  arrange(desc(p_nonR))
house_comp <- pred %>% filter(chamber == "House", !uncontested, p_dem >= .1, p_dem <= .9) %>%
  transmute(district = race_id, p_dem, pvi, incumbent = coalesce(incumbent, "abierto"), inc_party, margin = margin_median,
            lo = margin_lo80, hi = margin_hi80, n_polls = coalesce(n_polls, 0), rating = rating_consensus, cand_D, cand_R) %>%
  arrange(p_dem)
house_counts <- pred %>% filter(chamber == "House") %>%
  summarise(safe_D = sum(p_dem >= .9), lean_D = sum(p_dem >= .6 & p_dem < .9), tossup = sum(p_dem > .4 & p_dem < .6),
            lean_R = sum(p_dem > .1 & p_dem <= .4), safe_R = sum(p_dem <= .1))

data <- list(
  generado = rj$generado_utc, snapshot = snapshot, ultima_encuesta = as.character(last_poll),
  mu_G = ms$mu_G, sigma_mu = ms$sigma_mu, n_sim = ms$n_sim, n_polls_generic = nrow(ms$gen),
  delta = list(mean = unname(ms$params[["delta_mean"]]), sd = unname(ms$params[["delta_sd"]])),
  resumen = list(con_delta = res_by("con_delta"), sin_delta = res_by("sin_delta"), solo_fund = res_by("solo_fundamentales")),
  sensibilidad = ms$sensibilidad,
  dist_house = split(dist %>% filter(chamber == "House") %>% select(version, seats_D, prob), dist$version[dist$chamber == "House"]),
  dist_senate = split(dist %>% filter(chamber == "Senate") %>% select(version, seats_D, prob), dist$version[dist$chamber == "Senate"]),
  senate = senate, house_comp = house_comp, house_counts = as.list(house_counts),
  lineas_base = lb, hashes = hashes, D_not_up = ms$D_NOT_UP,
  n_uncontested = sum(pred$uncontested & pred$chamber == "House"),
  n_polled_house = sum(pred$polled & pred$chamber == "House")
)
json <- toJSON(data, auto_unbox = TRUE, na = "null", digits = 4, dataframe = "rows")

tpl <- read_file(file.path(DIR_DOCS, "plantilla_pagina.html"))
html <- str_replace(tpl, fixed("/*__DATA__*/"), paste0("window.DATA = ", json, ";"))
write_file(html, file.path(DIR_OUT, "pronostico.html"))
msg("Pagina escrita: %s (%.0f KB)", file.path(DIR_OUT, "pronostico.html"), file.size(file.path(DIR_OUT, "pronostico.html")) / 1024)
