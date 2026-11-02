# 05_outputs.R -- a partir de las simulaciones produce los entregables preregistrados:
#   output/predicciones.csv        470 carreras: P(D), margen mediana e IC80 (version principal y alternativa)
#   output/resumen.json / .md      Q1..Q6 para cada version
#   output/distribucion_escanos.csv
#   output/lineas_base.csv         swing uniforme, solo fundamentales y agregadores externos
#   output/figuras/*.png
#   output/SHA256SUMS.txt          hashes para el preregistro (OSF / OpenTimestamps)
source("R/00_setup.R")
suppressPackageStartupMessages(library(ggplot2))

sims <- readRDS(file.path(DIR_OUT, "sims.rds"))
ms   <- readRDS(file.path(DIR_OUT, "model_state.rds"))
D <- ms$D; S <- ms$S
PRIMARY <- "con_delta"      # version principal preregistrada (hipotesis Q5); "sin_delta" es la alternativa
dir.create(file.path(DIR_OUT, "figuras"), showWarnings = FALSE)

q <- function(x, p) unname(quantile(x, p))

# ============================================================================
# 1. Resumen Q1..Q6 por version
# ============================================================================
summarise_version <- function(s) {
  seats_sen_D <- ms$D_NOT_UP + s$wins_D
  seats_sen_D_plus_I <- seats_sen_D + s$wins_I
  tibble(
    version = s$version,
    Q1_voto_nacional_margen = median(s$natvote), Q1_lo80 = q(s$natvote, .1), Q1_hi80 = q(s$natvote, .9),
    Q2_camara_D_mediana = median(s$seats_house), Q2_lo80 = q(s$seats_house, .1), Q2_hi80 = q(s$seats_house, .9),
    Q2_P_D_mayoria = mean(s$seats_house >= 218),
    Q3_senado_D_mediana = median(seats_sen_D), Q3_lo80 = q(seats_sen_D, .1), Q3_hi80 = q(seats_sen_D, .9),
    Q3_P_D_51 = mean(seats_sen_D >= 51),
    Q3_P_D_51_con_independientes = mean(seats_sen_D_plus_I >= 51),
    Q3_P_independiente_gana_alguno = mean(s$wins_I >= 1),
    Q5_delta_media = mean(s$delta), Q5_delta_lo80 = q(s$delta, .1), Q5_delta_hi80 = q(s$delta, .9),
    Q6_P_D_camara_y_R_senado = mean(s$seats_house >= 218 & seats_sen_D < 51),
    P_D_camara_y_D_senado = mean(s$seats_house >= 218 & seats_sen_D >= 51),
    P_R_camara_y_R_senado = mean(s$seats_house < 218 & seats_sen_D < 51),
    P_R_camara_y_D_senado = mean(s$seats_house < 218 & seats_sen_D >= 51)
  )
}
resumen <- map_dfr(sims, summarise_version)
print(as.data.frame(t(resumen)), right = FALSE)

# ============================================================================
# 2. Predicciones por carrera (Q4)
# ============================================================================
race_table <- function(s) {
  ph <- colMeans(s$M_house > 0); psn <- colMeans(s$M_sen > 0)
  bind_rows(
    tibble(race_id = D$district, chamber = "House", state = D$state, region = D$region,
           p_nonR = ph, p_dem = ph,
           margin_median = apply(s$M_house, 2, median), margin_lo80 = apply(s$M_house, 2, q, .1), margin_hi80 = apply(s$M_house, 2, q, .9)),
    tibble(race_id = S$race_id, chamber = "Senate", state = S$state, region = S$region,
           p_nonR = psn, p_dem = if_else(S$challenger_is_ind, 0, psn), p_ind = if_else(S$challenger_is_ind, psn, 0),
           margin_median = apply(s$M_sen, 2, median), margin_lo80 = apply(s$M_sen, 2, q, .1), margin_hi80 = apply(s$M_sen, 2, q, .9))
  ) %>% mutate(p_ind = coalesce(p_ind, 0), p_rep = 1 - p_dem - p_ind)
}
main <- race_table(sims[[PRIMARY]])
# p_nonR: probabilidad del lado no republicano (D, o el independiente principal); es lo que se evalua en 06
alt  <- race_table(sims[["sin_delta"]]) %>% select(race_id, p_nonR_sin_delta = p_nonR, margin_median_sin_delta = margin_median)
fund <- race_table(sims[["solo_fundamentales"]]) %>% select(race_id, p_nonR_solo_fund = p_nonR)

info <- bind_rows(
  D %>% transmute(race_id = district, pvi = round(pvi_2026, 2), incumbent, inc_party = inc_party_model, open_seat, uncontested,
                  cand_D, cand_R, polled, n_polls, poll_margin = round(poll_margin, 2),
                  rating_consensus, rating_margin = round(rating_margin, 2), n_raters,
                  fund_margin = round(fund_margin, 2), w_poll = round(w_poll, 3), w_rating = round(w_rating, 3),
                  m_hat = round(m_hat, 2), redistricted),
  S %>% transmute(race_id, pvi, incumbent = senator, inc_party, open_seat, uncontested = !has_D & !polled,
                  cand_D = if_else(challenger_is_ind, cand_I, cand_D), cand_R, polled, n_polls, poll_margin = round(poll_margin, 2),
                  rating_consensus, rating_margin = round(rating_margin, 2), n_raters,
                  fund_margin = round(fund_margin, 2), w_poll = round(w_poll, 3), w_rating = round(w_rating, 3),
                  m_hat = round(m_hat, 2), redistricted = FALSE)
)
predicciones <- main %>% left_join(alt, by = "race_id") %>% left_join(fund, by = "race_id") %>% left_join(info, by = "race_id") %>%
  mutate(across(c(p_nonR, p_dem, p_ind, p_rep, p_nonR_sin_delta, p_nonR_solo_fund), ~ round(.x, 4)),
         across(c(margin_median, margin_lo80, margin_hi80, margin_median_sin_delta), ~ round(.x, 2)),
         version_principal = PRIMARY, generado_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ")) %>%
  arrange(chamber, race_id)
stopifnot(nrow(predicciones) == 470)
write_csv(predicciones, file.path(DIR_OUT, "predicciones.csv"))

# ============================================================================
# 3. Distribuciones de escanos y lineas base
# ============================================================================
dist_seats <- map_dfr(sims, function(s) bind_rows(
  tibble(version = s$version, chamber = "House",  seats_D = as.integer(names(table(s$seats_house))), prob = as.numeric(table(s$seats_house)) / length(s$seats_house)),
  tibble(version = s$version, chamber = "Senate", seats_D = as.integer(names(table(ms$D_NOT_UP + s$wins_D))), prob = as.numeric(table(ms$D_NOT_UP + s$wins_D)) / length(s$wins_D))))
write_csv(dist_seats, file.path(DIR_OUT, "distribucion_escanos.csv"))

bench_gen <- read_csv(file.path(DIR_FROZEN, "benchmark_generic_aggregators.csv"))
lineas_base <- bind_rows(
  tibble(linea_base = "modelo principal (con delta)", camara_D = resumen$Q2_camara_D_mediana[resumen$version == "con_delta"],
         P_D_camara = resumen$Q2_P_D_mayoria[resumen$version == "con_delta"], senado_D = resumen$Q3_senado_D_mediana[resumen$version == "con_delta"],
         P_D_senado = resumen$Q3_P_D_51[resumen$version == "con_delta"], fuente = "este repositorio", fecha = as.character(Sys.Date())),
  tibble(linea_base = "modelo sin delta", camara_D = resumen$Q2_camara_D_mediana[resumen$version == "sin_delta"],
         P_D_camara = resumen$Q2_P_D_mayoria[resumen$version == "sin_delta"], senado_D = resumen$Q3_senado_D_mediana[resumen$version == "sin_delta"],
         P_D_senado = resumen$Q3_P_D_51[resumen$version == "sin_delta"], fuente = "este repositorio", fecha = as.character(Sys.Date())),
  tibble(linea_base = "(a) swing uniforme sin delta", camara_D = ms$swing_uniforme$house_D, P_D_camara = as.numeric(ms$swing_uniforme$house_D >= 218),
         senado_D = ms$swing_uniforme$senate_D, P_D_senado = as.numeric(ms$swing_uniforme$senate_D >= 51), fuente = "este repositorio", fecha = as.character(Sys.Date())),
  tibble(linea_base = "(b) solo fundamentales", camara_D = resumen$Q2_camara_D_mediana[resumen$version == "solo_fundamentales"],
         P_D_camara = resumen$Q2_P_D_mayoria[resumen$version == "solo_fundamentales"], senado_D = resumen$Q3_senado_D_mediana[resumen$version == "solo_fundamentales"],
         P_D_senado = resumen$Q3_P_D_51[resumen$version == "solo_fundamentales"], fuente = "este repositorio", fecha = as.character(Sys.Date())),
  tibble(linea_base = "(c) Poliwave", camara_D = NA, P_D_camara = 0.89, senado_D = 54, P_D_senado = 0.78,
         fuente = "poliwave.com/us/fed/projection (consultado 2026-11-02)", fecha = "2026-11-02"),
  tibble(linea_base = "(c) PollCheck", camara_D = 230, P_D_camara = NA, senado_D = 50, P_D_senado = NA,
         fuente = "PollCheck (Senado: D 50, R 45, 5 sin definir), citado en el plan", fecha = "2026-11-01"),
  tibble(linea_base = "(c) Silver Bulletin (FLIPR)", camara_D = 213 + 25, P_D_camara = 0.95, senado_D = NA, P_D_senado = NA,
         fuente = "Silver Bulletin: ~95% Camara, +25 escanos netos sobre 213 actuales, citado en el plan", fecha = "2026-11-01")
)
pm <- read_csv(file.path(DIR_FROZEN, "benchmark_polymarket.csv"))
if (nrow(pm) && any(!is.na(pm$p_dem))) {
  lineas_base <- bind_rows(lineas_base,
    tibble(linea_base = "(d) Polymarket (mercado de prediccion)", camara_D = NA, P_D_camara = pm$p_dem[pm$chamber == "House"],
           senado_D = NA, P_D_senado = pm$p_dem[pm$chamber == "Senate"], fuente = pm$source[1], fecha = as.character(pm$fetched[1])))
}
write_csv(lineas_base, file.path(DIR_OUT, "lineas_base.csv"))
write_csv(bench_gen %>% mutate(nota = "promedios generic ballot de otros agregadores (Wikipedia, 1 nov 2026)"),
          file.path(DIR_OUT, "lineas_base_generic_ballot.csv"))

# ============================================================================
# 4. Figuras
# ============================================================================
theme_set(theme_minimal(base_size = 12))
p1 <- ggplot(dist_seats %>% filter(chamber == "House", version != "solo_fundamentales"), aes(seats_D, prob, fill = version)) +
  geom_col(position = "identity", alpha = .55, width = 1) + geom_vline(xintercept = 217.5, linetype = 2) +
  labs(title = "Camara: escanos democratas simulados (20 000 replicas)", x = "Escanos D", y = "Probabilidad", fill = NULL) +
  scale_fill_manual(values = c(con_delta = "#1f77b4", sin_delta = "#ff7f0e"))
ggsave(file.path(DIR_OUT, "figuras", "camara_escanos.png"), p1, width = 8, height = 4.5, dpi = 150)
p2 <- ggplot(dist_seats %>% filter(chamber == "Senate", version != "solo_fundamentales"), aes(seats_D, prob, fill = version)) +
  geom_col(position = "dodge", alpha = .8) + geom_vline(xintercept = 50.5, linetype = 2) +
  labs(title = "Senado: escanos democratas (incl. King y Sanders; sin independientes nuevos)", x = "Escanos D", y = "Probabilidad", fill = NULL) +
  scale_fill_manual(values = c(con_delta = "#1f77b4", sin_delta = "#ff7f0e"))
ggsave(file.path(DIR_OUT, "figuras", "senado_escanos.png"), p2, width = 8, height = 4.5, dpi = 150)
comp <- predicciones %>% filter(chamber == "House", !uncontested, p_dem > .05, p_dem < .95) %>% arrange(p_dem)
p3 <- ggplot(comp, aes(x = reorder(race_id, p_dem), y = p_dem, colour = polled)) + geom_point() + coord_flip() +
  geom_hline(yintercept = .5, linetype = 2) + labs(title = "Distritos competitivos: P(D gana), version principal", x = NULL, y = "P(D)") +
  theme(axis.text.y = element_text(size = 6))
ggsave(file.path(DIR_OUT, "figuras", "distritos_competitivos.png"), p3, width = 7, height = 11, dpi = 150)
gen <- ms$gen
p4 <- ggplot(gen, aes(end, margin_adj, size = w)) + geom_point(alpha = .5) + geom_hline(yintercept = ms$mu_G, colour = "red") +
  labs(title = sprintf("Generic ballot, ultimos 21 dias: mu_G = %+.1f (IC80 bootstrap %+.1f a %+.1f)", ms$mu_G, q(ms$boot, .1), q(ms$boot, .9)),
       x = "fin de campo", y = "margen D-R (2 partidos, ajustado)")
ggsave(file.path(DIR_OUT, "figuras", "generic_ballot.png"), p4, width = 8, height = 4.5, dpi = 150)

# ============================================================================
# 5. Resumen legible y hashes
# ============================================================================
write_json(list(generado_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%dT%H:%M:%SZ"), version_principal = PRIMARY,
                mu_G = ms$mu_G, sigma_mu_bootstrap = ms$sigma_mu, n_sim = ms$n_sim, parametros = as.list(ms$params),
                resumen = resumen, lineas_base = lineas_base),
           file.path(DIR_OUT, "resumen.json"), auto_unbox = TRUE, pretty = TRUE, digits = 4)

fmt <- function(x, d = 1) ifelse(is.na(x), "-", formatC(x, format = "f", digits = d))
r <- resumen %>% filter(version == PRIMARY); r2 <- resumen %>% filter(version == "sin_delta")
md <- c(
  "# Resumen del pronostico (cantidades preregistradas Q1-Q6)", "",
  sprintf("Generado: %s UTC. Version principal: **%s**. Simulaciones: %d.", format(Sys.time(), tz = "UTC", "%Y-%m-%d %H:%M"), PRIMARY, ms$n_sim), "",
  sprintf("Promedio generic ballot (dos partidos, LV, efectos de casa): **D%+.1f** (sd bootstrap en dos etapas %.2f).", ms$mu_G, ms$sigma_mu), "",
  "| Cantidad | con delta (principal) | sin delta |", "|---|---|---|",
  sprintf("| Q1 margen voto popular Camara (2 partidos) | %s [IC80 %s, %s] | %s [%s, %s] |", fmt(r$Q1_voto_nacional_margen), fmt(r$Q1_lo80), fmt(r$Q1_hi80), fmt(r2$Q1_voto_nacional_margen), fmt(r2$Q1_lo80), fmt(r2$Q1_hi80)),
  sprintf("| Q2 escanos D Camara | %s [IC80 %s, %s] | %s [%s, %s] |", fmt(r$Q2_camara_D_mediana, 0), fmt(r$Q2_lo80, 0), fmt(r$Q2_hi80, 0), fmt(r2$Q2_camara_D_mediana, 0), fmt(r2$Q2_lo80, 0), fmt(r2$Q2_hi80, 0)),
  sprintf("| Q2 P(D >= 218) | %s | %s |", fmt(r$Q2_P_D_mayoria, 3), fmt(r2$Q2_P_D_mayoria, 3)),
  sprintf("| Q3 escanos D Senado (con King y Sanders) | %s [IC80 %s, %s] | %s [%s, %s] |", fmt(r$Q3_senado_D_mediana, 0), fmt(r$Q3_lo80, 0), fmt(r$Q3_hi80, 0), fmt(r2$Q3_senado_D_mediana, 0), fmt(r2$Q3_lo80, 0), fmt(r2$Q3_hi80, 0)),
  sprintf("| Q3 P(D >= 51) | %s | %s |", fmt(r$Q3_P_D_51, 3), fmt(r2$Q3_P_D_51, 3)),
  sprintf("| Q3 P(D + independientes nuevos >= 51) | %s | %s |", fmt(r$Q3_P_D_51_con_independientes, 3), fmt(r2$Q3_P_D_51_con_independientes, 3)),
  sprintf("| Q5 delta (sesgo de encuestas, negativo = exageran a D) | %s [IC80 %s, %s] | 0 (fijo) |", fmt(r$Q5_delta_media), fmt(r$Q5_delta_lo80), fmt(r$Q5_delta_hi80)),
  sprintf("| Q6 P(D gana Camara y R retiene Senado) | %s | %s |", fmt(r$Q6_P_D_camara_y_R_senado, 3), fmt(r2$Q6_P_D_camara_y_R_senado, 3)),
  sprintf("| P(D Camara y D Senado) | %s | %s |", fmt(r$P_D_camara_y_D_senado, 3), fmt(r2$P_D_camara_y_D_senado, 3)),
  sprintf("| P(R Camara y R Senado) | %s | %s |", fmt(r$P_R_camara_y_R_senado, 3), fmt(r2$P_R_camara_y_R_senado, 3)), "",
  "Q4 (470 probabilidades por carrera): `output/predicciones.csv`.", "",
  "## Lineas base", "", "| linea base | Camara D | P(D Camara) | Senado D | P(D Senado) | fuente |", "|---|---|---|---|---|---|",
  sprintf("| %s | %s | %s | %s | %s | %s |", lineas_base$linea_base, coalesce(as.character(lineas_base$camara_D), "-"),
          coalesce(fmt(lineas_base$P_D_camara, 2), "-"), coalesce(as.character(lineas_base$senado_D), "-"),
          coalesce(fmt(lineas_base$P_D_senado, 2), "-"), lineas_base$fuente), "",
  "## Sensibilidad a la hipotesis de sesgo (media de delta; 5 000 replicas cada una)", "",
  "| media de delta | Camara D mediana | P(D Camara) | Senado D mediana | P(D Senado) | P(D Camara y R Senado) |", "|---|---|---|---|---|---|",
  with(ms$sensibilidad, sprintf("| %s | %s | %s | %s | %s | %s |", fmt(delta_mean), fmt(camara_D_mediana, 0), fmt(P_D_camara, 3), fmt(senado_D_mediana, 0), fmt(P_D_senado, 3), fmt(P_D_camara_R_senado, 3))), "",
  "## Carreras senatoriales (version principal)", "", "| carrera | P(no R) | lado no R | margen mediana | IC80 | encuestas | calificacion |", "|---|---|---|---|---|---|---|",
  with(predicciones %>% filter(chamber == "Senate") %>% arrange(desc(p_dem + p_ind)),
       sprintf("| %s | %s | %s | %s | [%s, %s] | %s | %s |", race_id, fmt(p_dem + p_ind, 3), coalesce(cand_D, "-"), fmt(margin_median), fmt(margin_lo80), fmt(margin_hi80), coalesce(as.character(n_polls), "0"), coalesce(rating_consensus, "-"))), "",
  "## Distritos mas competitivos (P(D) entre 0.2 y 0.8, version principal)", "", "| distrito | P(D) | PVI | incumbente | margen mediana | encuestas | calificacion |", "|---|---|---|---|---|---|---|",
  with(predicciones %>% filter(chamber == "House", p_dem >= .2, p_dem <= .8) %>% arrange(p_dem),
       sprintf("| %s | %s | %s | %s (%s) | %s | %s | %s |", race_id, fmt(p_dem, 3), fmt(pvi), coalesce(incumbent, "abierto"), inc_party, fmt(margin_median), coalesce(as.character(n_polls), "0"), coalesce(rating_consensus, "-")))
)
writeLines(md, file.path(DIR_OUT, "resumen.md"))

hash_files <- c("predicciones.csv", "resumen.json", "resumen.md", "distribucion_escanos.csv", "lineas_base.csv")
hashes <- map_chr(hash_files, ~ digest(file.path(DIR_OUT, .x), algo = "sha256", file = TRUE))
# write_lines escribe LF (no CRLF): asi `sha256sum -c` funciona en cualquier sistema
write_lines(sprintf("%s  %s", hashes, hash_files), file.path(DIR_OUT, "SHA256SUMS.txt"))
frozen_hash <- map_chr(list.files(DIR_FROZEN, full.names = TRUE), ~ digest(.x, algo = "sha256", file = TRUE))
write_lines(sprintf("%s  data/frozen/%s", frozen_hash, list.files(DIR_FROZEN)), file.path(DIR_OUT, "SHA256SUMS_datos.txt"))
msg("Entregables escritos en %s", DIR_OUT)
cat(readLines(file.path(DIR_OUT, "SHA256SUMS.txt")), sep = "\n")
