# 04_model.R -- simulacion jerarquica (multietapica) de Camara y Senado 2026
#
# Margen simulado del distrito d (estado s, region r):
#   m_d = m_hat_d + (delta + eps_nac + eps_mu) + eps_r + eps_s + eps_d
# donde m_hat_d combina fundamentales (mu_G + 2*PVI_d + beta_inc*Inc_d) y el promedio de encuestas
# del distrito por precision inversa. Las cuatro etapas de error (nacion, region, estado, distrito)
# son las de un diseno por conglomerados; sus sigmas vienen de 03_calibrate.R.
# Senado: mismo esquema con PVI estatal, sin eps_d, y comparte eps_nac/eps_r/eps_s con la Camara
# (asi la probabilidad conjunta Q6 es coherente).
#
# Se corren dos versiones: "con_delta" (delta ~ N(delta_mean, delta_sd^2), hipotesis Q5) y
# "sin_delta" (delta = 0). Ambas se publican.
source("R/00_setup.R")

N_SIM   <- 20000L
N_BOOT  <- 2000L
set.seed(SEED)

cal <- read_csv(file.path(DIR_FROZEN, "calibration.csv"))
P <- setNames(cal$value, cal$parameter)

districts <- read_csv(file.path(DIR_FROZEN, "districts.csv"))
senate    <- read_csv(file.path(DIR_FROZEN, "senate_races.csv"))
pg        <- read_csv(file.path(DIR_FROZEN, "polls_generic.csv"))
ps        <- read_csv(file.path(DIR_FROZEN, "polls_senate.csv"))
ph        <- read_csv(file.path(DIR_FROZEN, "polls_house.csv"))

# ---- decisiones preregistradas sobre encuestas ------------------------------
WINDOW_GENERIC <- 21     # dias antes de la eleccion
WINDOW_RACE    <- 35     # distritos y estados (menos encuestas)
WINDOW_RACE_MAX <- 75    # si hay < 3 encuestas en 35 dias se amplia hasta aqui
HALF_LIFE      <- 10     # dias: peso de recencia 0.5^(edad/HALF_LIFE)
MIN_TWO_PARTY  <- 15     # una encuesta de carrera con D o R < 15% no es un duelo D-R util

two_party_margin <- function(dem, rep) 100 * (dem - rep) / (dem + rep)

prep_polls <- function(df) {
  # ajustes comunes: dos partidos (reparto proporcional de indecisos), RV->LV, partidistas
  df %>%
    filter(!is.na(dem), !is.na(rep), pop %in% c("LV", "RV") | is.na(pop)) %>%
    mutate(pop = coalesce(pop, "RV"),
           margin2p = two_party_margin(dem, rep),
           margin_adj = margin2p +
             if_else(pop == "RV", P[["rv_to_lv_shift"]], 0) +
             case_when(partisan == "D" ~ -P[["partisan_shift"]], partisan == "R" ~ P[["partisan_shift"]], TRUE ~ 0),
           age = as.numeric(ELECTION_DAY - end),
           w = 0.5^(age / HALF_LIFE) * pmin(sqrt(coalesce(n, 600) / 600), 2) *
             if_else(!is.na(partisan), P[["partisan_weight"]], 1))
}

# ============================================================================
# 1. Entorno nacional: mu_G con efectos de casa y bootstrap en dos etapas
# ============================================================================
gen <- pg %>% filter(end >= ELECTION_DAY - WINDOW_GENERIC, end <= ELECTION_DAY) %>% prep_polls()
msg("Generic ballot: %d encuestas en los ultimos %d dias (%d encuestadores)", nrow(gen), WINDOW_GENERIC, n_distinct(gen$pollster))

house_effect_mean <- function(d, k = 3) {
  # media ponderada con efecto de casa (empirical Bayes: desviacion del encuestador encogida hacia 0)
  mu0 <- weighted.mean(d$margin_adj, d$w)
  he <- d %>% group_by(pollster) %>%
    summarise(dev = weighted.mean(margin_adj - mu0, w), np = n(), .groups = "drop") %>%
    mutate(he = dev * np / (np + k))
  d2 <- d %>% left_join(he %>% select(pollster, he), by = "pollster")
  list(mu = weighted.mean(d2$margin_adj - d2$he, d2$w), he = he)
}
hm <- house_effect_mean(gen)
mu_G <- hm$mu
msg("mu_G (margen D-R, dos partidos, LV, con efectos de casa) = %+.2f", mu_G)

# bootstrap en dos etapas: encuestadores -> encuestas dentro de cada encuestador
by_pollster <- split(gen, gen$pollster)
boot <- replicate(N_BOOT, {
  ps_ <- sample(names(by_pollster), replace = TRUE)
  d <- bind_rows(lapply(ps_, function(p) { x <- by_pollster[[p]]; x[sample(nrow(x), replace = TRUE), ] }))
  house_effect_mean(d)$mu
})
sigma_mu <- sd(boot)
msg("sd bootstrap (2 etapas) de mu_G = %.2f  [IC80: %+.2f, %+.2f]", sigma_mu, quantile(boot, .1), quantile(boot, .9))

# ============================================================================
# 2. Promedios de encuestas por carrera (distritos y estados)
# ============================================================================
race_poll_avg <- function(df, id, s_sys, s_within) {
  df <- df %>% filter(end <= ELECTION_DAY, end >= ELECTION_DAY - WINDOW_RACE_MAX) %>% prep_polls() %>%
    filter(dem >= MIN_TWO_PARTY, rep >= MIN_TWO_PARTY)
  if (!nrow(df)) return(tibble())
  df %>% group_by(.id = .data[[id]]) %>%
    group_modify(function(x, k) {
      recent <- x %>% filter(age <= WINDOW_RACE)
      use <- if (nrow(recent) >= 3) recent else x %>% arrange(age) %>% slice_head(n = max(3, nrow(recent)))
      n_eff <- sum(use$w) / max(use$w)                     # encuestas "efectivas" (<= n)
      tibble(poll_margin = weighted.mean(use$margin_adj - coalesce(hm$he$he[match(use$pollster, hm$he$pollster)], 0), use$w),
             n_polls = nrow(use), n_eff = n_eff, last_poll = max(use$end),
             poll_var = s_sys^2 + s_within^2 / n_eff)
    }) %>% ungroup() %>% rename(!!id := .id)
}
# CA-06: Kiley (independiente, ex-R) ocupa el lado "R" del duelo (ver 02_clean.R)
ph2 <- ph %>% mutate(rep = if_else(district == "CA-06" & is.na(rep), ind, rep))
# Senado: si el independiente promedia mas que el demócrata (MT: Bodnar; NE: Osborn ya viene como "dem"),
# el independiente es el retador principal y ocupa el lado "no R"
ind_races <- ps %>% filter(end >= ELECTION_DAY - WINDOW_RACE_MAX) %>% group_by(race_id) %>%
  summarise(m_dem = mean(dem, na.rm = TRUE), m_ind = mean(ind, na.rm = TRUE), .groups = "drop") %>%
  filter(!is.na(m_ind), is.na(m_dem) | m_ind > m_dem) %>% pull(race_id)
ps2 <- ps %>% mutate(dem = if_else(race_id %in% ind_races, ind, dem))
if (length(ind_races)) msg("Retador independiente principal en: %s", paste(ind_races, collapse = ", "))

hp <- race_poll_avg(ph2, "district", P[["s_sys_house"]], P[["sd_poll_within_house"]])
sp <- race_poll_avg(ps2, "race_id",  P[["s_sys_senate"]], P[["sd_poll_within_senate"]])
msg("Promedios: %d distritos y %d carreras senatoriales con encuestas utiles", nrow(hp), nrow(sp))

# ============================================================================
# 3. Estimacion puntual por carrera (fundamentales + encuestas por precision inversa)
# ============================================================================
pvi_mult <- P[["pvi_multiplier"]]

D <- districts %>%
  left_join(hp, by = "district") %>%
  mutate(inc = case_when(open_seat ~ 0, inc_party_model == "D" ~ 1, inc_party_model == "R" ~ -1, TRUE ~ 0),
         fund_margin = mu_G + pvi_mult * pvi_2026 + P[["beta_inc_house"]] * inc,
         fund_var = P[["sigma_dist_fund"]]^2 + if_else(redistricted, P[["redistricted_extra_sd"]]^2, 0),
         polled = !is.na(poll_margin),
         w_poll = if_else(polled, (1 / poll_var) / (1 / poll_var + 1 / fund_var), 0),
         m_hat = if_else(polled, w_poll * poll_margin + (1 - w_poll) * fund_margin, fund_margin),
         sd_d = sqrt(if_else(polled, 1 / (1 / poll_var + 1 / fund_var), fund_var)),
         # sin competencia: el unico partido mayor gana
         m_hat = case_when(uncontested & has_D ~ 100, uncontested & has_R ~ -100, TRUE ~ m_hat),
         sd_d  = if_else(uncontested, 0, sd_d))

# Senado --------------------------------------------------------------------
S <- senate %>%
  left_join(sp, by = "race_id") %>%
  mutate(inc = case_when(open_seat ~ 0, inc_party == "D" ~ 1, inc_party == "R" ~ -1, TRUE ~ 0),
         # lado "no republicano": el demócrata, o el independiente principal (sin demócrata, o si encuesta mejor)
         challenger_is_ind = (!has_D & !is.na(poll_margin)) | race_id %in% ind_races,
         fund_margin = mu_G + pvi_mult * pvi + P[["beta_inc_senate"]] * inc,
         fund_var = if_else(challenger_is_ind, 12^2, P[["sigma_state_fund"]]^2),   # sin D en la boleta, fundamentales casi no informan
         polled = !is.na(poll_margin),
         w_poll = if_else(polled, (1 / poll_var) / (1 / poll_var + 1 / fund_var), 0),
         m_hat = if_else(polled, w_poll * poll_margin + (1 - w_poll) * fund_margin, fund_margin),
         sd_s_extra = sqrt(if_else(polled, 1 / (1 / poll_var + 1 / fund_var), fund_var)),
         # carreras sin demócrata ni encuestas: el republicano gana (ID, SD si no hubiera encuestas)
         m_hat = if_else(!has_D & !polled, -100, m_hat),
         sd_s_extra = if_else(!has_D & !polled, 0, sd_s_extra))

# ============================================================================
# 4. Simulacion
# ============================================================================
simulate <- function(version = c("con_delta", "sin_delta", "solo_fundamentales"), n_sim = N_SIM) {
  version <- match.arg(version)
  set.seed(SEED + match(version, c("con_delta", "sin_delta", "solo_fundamentales")) - 1L)
  if (version == "solo_fundamentales") {
    # linea base (b): sin encuestas de carrera, sin delta
    D <- D %>% mutate(m_hat = if_else(uncontested, m_hat, fund_margin), sd_d = if_else(uncontested, 0, sqrt(fund_var)))
    S <- S %>% mutate(m_hat = if_else(!has_D, -100, fund_margin), sd_s_extra = if_else(!has_D, 0, sqrt(P[["sigma_state_fund"]]^2)),
                      polled = FALSE, challenger_is_ind = FALSE)
  }
  delta <- if (version == "con_delta") rnorm(n_sim, P[["delta_mean"]], P[["delta_sd"]]) else rep(0, n_sim)
  sd_nat <- if (version == "con_delta") P[["sd_nat_demeaned"]] else P[["sigma_nat"]]
  e_nat <- rnorm(n_sim, 0, sd_nat) + rnorm(n_sim, 0, sigma_mu)
  regions <- sort(unique(c(D$region, S$region)))
  states  <- sort(unique(c(D$state, S$state)))
  e_reg <- matrix(rnorm(n_sim * length(regions), 0, P[["sigma_region_house"]]), n_sim, dimnames = list(NULL, regions))
  e_st  <- matrix(rnorm(n_sim * length(states),  0, P[["sigma_state_house"]]),  n_sim, dimnames = list(NULL, states))
  common <- delta + e_nat                                   # error nacional comun (encuestas vs urnas)

  # Camara: matriz n_sim x 435
  e_d <- matrix(rnorm(n_sim * nrow(D), 0, 1), n_sim) * rep(D$sd_d, each = n_sim)
  M_house <- rep(D$m_hat, each = n_sim) + common + e_reg[, D$region] + e_st[, D$state] + e_d
  M_house[, D$uncontested] <- rep(D$m_hat[D$uncontested], each = n_sim)
  seats_house <- rowSums(M_house > 0)

  # Senado: sin eps_d; comparte common, e_reg, e_st
  e_s <- matrix(rnorm(n_sim * nrow(S), 0, 1), n_sim) * rep(S$sd_s_extra, each = n_sim)
  M_sen <- rep(S$m_hat, each = n_sim) + common + e_reg[, S$region] * (P[["sigma_region_senate"]] / P[["sigma_region_house"]]) +
           e_st[, S$state] * 0 + e_s      # el error estatal del Senado ya esta en sd_s_extra (residuo Sen-G)
  M_sen[, !S$has_D & !S$polled] <- -100
  win_nonR <- M_sen > 0
  wins_D   <- rowSums(win_nonR[, !S$challenger_is_ind, drop = FALSE])
  wins_I   <- rowSums(win_nonR[, S$challenger_is_ind, drop = FALSE])

  list(version = version, delta = delta, common = common, M_house = M_house, M_sen = M_sen,
       seats_house = seats_house, wins_D = wins_D, wins_I = wins_I,
       natvote = mu_G + common)
}

# composicion del Senado que no se renueva (D incluye a King y Sanders)
D_NOT_UP <- 47 - sum(senate$inc_party %in% c("D", "I"))
R_NOT_UP <- 53 - sum(senate$inc_party == "R")
stopifnot(D_NOT_UP + R_NOT_UP == 65)

sims <- list(con_delta = simulate("con_delta"), sin_delta = simulate("sin_delta"),
             solo_fundamentales = simulate("solo_fundamentales"))
# linea base (a): swing uniforme determinista sin delta ni encuestas
swing_uniforme <- list(house_D = sum(if_else(D$uncontested, D$m_hat, D$fund_margin) > 0),
                       senate_D = D_NOT_UP + sum(S$has_D & S$fund_margin > 0))
msg("Linea base swing uniforme: Camara D %d, Senado D %d", swing_uniforme$house_D, swing_uniforme$senate_D)
saveRDS(sims, file.path(DIR_OUT, "sims.rds"))
saveRDS(list(D = D, S = S, mu_G = mu_G, sigma_mu = sigma_mu, boot = boot, house_effects = hm$he, gen = gen,
             D_NOT_UP = D_NOT_UP, R_NOT_UP = R_NOT_UP, swing_uniforme = swing_uniforme, ind_races = ind_races,
             params = P, n_sim = N_SIM, n_boot = N_BOOT, windows = c(generic = WINDOW_GENERIC, race = WINDOW_RACE, race_max = WINDOW_RACE_MAX, half_life = HALF_LIFE)),
        file.path(DIR_OUT, "model_state.rds"))
# diagnostico por carrera
S_diag <- S %>% transmute(race_id, pvi, inc_party, open_seat, has_D, polled, n_polls, poll_margin = round(poll_margin, 1),
                          fund_margin = round(fund_margin, 1), w_poll = round(w_poll, 2), m_hat = round(m_hat, 1),
                          sd = round(sd_s_extra, 1), challenger_is_ind)
print(as.data.frame(S_diag))
D_diag <- D %>% filter(!uncontested) %>% arrange(abs(m_hat)) %>% slice_head(n = 40) %>%
  transmute(district, pvi = round(pvi_2026, 1), inc_party_model, open_seat, polled, n_polls, poll_margin = round(poll_margin, 1),
            fund_margin = round(fund_margin, 1), w_poll = round(w_poll, 2), m_hat = round(m_hat, 1), sd = round(sd_d, 1))
print(as.data.frame(D_diag))
msg("Simulaciones guardadas (%d x 2 versiones)", N_SIM)
for (v in names(sims)) {
  s <- sims[[v]]
  msg("[%s] Camara D: mediana %d, IC80 [%d, %d], P(D>=218)=%.3f | Senado D: mediana %d, P(D>=51)=%.3f | voto nacional %+.1f",
      v, median(s$seats_house), quantile(s$seats_house, .1), quantile(s$seats_house, .9), mean(s$seats_house >= 218),
      median(D_NOT_UP + s$wins_D), mean(D_NOT_UP + s$wins_D >= 51), median(s$natvote))
}
