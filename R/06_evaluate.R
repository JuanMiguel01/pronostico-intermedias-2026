# 06_evaluate.R -- evaluacion preregistrada (se corre DESPUES de la eleccion)
#
# Entrada: output/resultados.csv con columnas
#   race_id, margin_actual (margen D-R en puntos; para carreras con independiente: no-R menos R), winner (D/R/I)
#   mas una fila nacional: race_id = "US_HOUSE_VOTE", margin_actual = margen del voto popular (dos partidos)
# Uso:  Rscript R/06_evaluate.R                (usa output/resultados.csv)
#       Rscript R/06_evaluate.R --simulado     (autoprueba: toma una replica de la simulacion como "resultado")
source("R/00_setup.R")
suppressPackageStartupMessages(library(nlme))

args <- commandArgs(trailingOnly = TRUE)
pred <- read_csv(file.path(DIR_OUT, "predicciones.csv"))
ms   <- readRDS(file.path(DIR_OUT, "model_state.rds"))
sims <- readRDS(file.path(DIR_OUT, "sims.rds"))
res_file <- file.path(DIR_OUT, "resultados.csv")

if ("--simulado" %in% args) {
  set.seed(1)
  k <- sample(ms$n_sim, 1); s <- sims$sin_delta
  resultados <- bind_rows(
    tibble(race_id = ms$D$district, margin_actual = s$M_house[k, ]),
    tibble(race_id = ms$S$race_id,  margin_actual = s$M_sen[k, ]),
    tibble(race_id = "US_HOUSE_VOTE", margin_actual = s$natvote[k])
  ) %>% mutate(winner = if_else(margin_actual > 0, "D", "R"))
  msg("AUTOPRUEBA con la replica %d (no son resultados reales)", k)
} else {
  if (!file.exists(res_file)) {
    # plantilla para rellenar la noche electoral
    tpl <- pred %>% transmute(race_id, chamber, state, margin_actual = NA_real_, winner = NA_character_) %>%
      bind_rows(tibble(race_id = "US_HOUSE_VOTE", chamber = "National", state = "US", margin_actual = NA_real_, winner = NA_character_))
    write_csv(tpl, res_file)
    stop("No hay resultados. Se creo la plantilla ", res_file, "; rellenala y vuelve a correr.")
  }
  resultados <- read_csv(res_file) %>% filter(!is.na(margin_actual))
}

# Se evaluan solo las carreras competidas: los escanos sin rival mayor (P = 0 o 1 por construccion) no informan
ev <- pred %>% filter(!uncontested) %>% inner_join(resultados %>% select(race_id, margin_actual, winner), by = "race_id") %>%
  mutate(y = as.integer(winner %in% c("D", "I")),          # 1 si gano el lado no republicano
         p = p_nonR,
         p_alt = p_nonR_sin_delta,
         p_fund = p_nonR_solo_fund,
         brier = (p - y)^2, brier_alt = (p_alt - y)^2, brier_fund = (p_fund - y)^2,
         logs = -log(pmax(pmin(if_else(y == 1, p, 1 - p), 1 - 1e-4), 1e-4)),
         resid = margin_actual - margin_median,
         in80 = margin_actual >= margin_lo80 & margin_actual <= margin_hi80)

scores <- ev %>% group_by(chamber) %>%
  summarise(n = n(), brier = mean(brier), brier_sin_delta = mean(brier_alt), brier_solo_fund = mean(brier_fund),
            brier_clima = mean((mean(y) - y)^2), log_score = mean(logs),
            mae_margen = mean(abs(resid), na.rm = TRUE), sesgo_margen = mean(resid, na.rm = TRUE),
            cobertura_IC80 = mean(in80, na.rm = TRUE), aciertos = mean((p > .5) == (y == 1)), .groups = "drop")
msg("Puntajes por camara:"); print(as.data.frame(scores), digits = 3)

# calibracion por deciles
calib <- ev %>% mutate(bin = cut(p, seq(0, 1, .1), include.lowest = TRUE)) %>%
  group_by(bin) %>% summarise(n = n(), p_media = mean(p), frec_obs = mean(y), .groups = "drop")
print(as.data.frame(calib), digits = 3)

# Q1-Q3, Q6 y Q5
us <- resultados %>% filter(race_id == "US_HOUSE_VOTE")
# escanos reales: carreras competidas (ev) + escanos sin rival, que van al unico partido mayor
all_res <- pred %>% inner_join(resultados %>% select(race_id, winner), by = "race_id") %>%
  mutate(y = as.integer(winner %in% c("D", "I")))
seats_D_house <- sum(all_res$y[all_res$chamber == "House"])
sen_ev <- all_res %>% filter(chamber == "Senate")
seats_D_sen   <- ms$D_NOT_UP + sum(sen_ev$y == 1 & !sen_ev$race_id %in% ms$S$race_id[ms$S$challenger_is_ind])
rj <- fromJSON(file.path(DIR_OUT, "resumen.json"))$resumen
r  <- rj[rj$version == "con_delta", ]
q_eval <- tibble(
  cantidad = c("Q1 margen voto popular", "Q2 escanos D Camara", "Q3 escanos D Senado"),
  predicho = c(r$Q1_voto_nacional_margen, r$Q2_camara_D_mediana, r$Q3_senado_D_mediana),
  lo80 = c(r$Q1_lo80, r$Q2_lo80, r$Q3_lo80), hi80 = c(r$Q1_hi80, r$Q2_hi80, r$Q3_hi80),
  real = c(if (nrow(us)) us$margin_actual else NA, seats_D_house, seats_D_sen)
) %>% mutate(dentro_IC80 = real >= lo80 & real <= hi80)
print(as.data.frame(q_eval), digits = 3)
delta_real <- if (nrow(us)) us$margin_actual - ms$mu_G else NA
msg("Q5: delta observado = resultado - promedio final = %+.2f (hipotesis: %+.1f, IC80 [%+.1f, %+.1f])",
    delta_real, r$Q5_delta_media, r$Q5_delta_lo80, r$Q5_delta_hi80)
msg("Q6: ocurrio 'D Camara y R Senado' = %s (P predicha %.3f)", seats_D_house >= 218 & seats_D_sen < 51, r$Q6_P_D_camara_y_R_senado)

# post-mortem multietapico: ANOVA anidada de residuos de margen (region/estado), residuo = distrito
house_ev <- ev %>% filter(chamber == "House", !is.na(resid))
fit <- tryCatch(lme(resid ~ 1, random = ~ 1 | region / state, data = house_ev,
                    control = lmeControl(opt = "optim")), error = function(e) NULL)
if (!is.null(fit)) {
  vc <- as.numeric(VarCorr(fit)[, "Variance"]); vc <- vc[!is.na(vc)]
  comp <- tibble(componente = c("nacional (intercepto)", "region", "estado", "distrito"),
                 valor = c(fixef(fit), sqrt(vc[1]), sqrt(vc[2]), sqrt(vc[3])))
  msg("Descomposicion del error de margen en la Camara (sd por nivel; nacional = media del residuo):")
  print(as.data.frame(comp), digits = 3)
}

dir.create(file.path(DIR_OUT, "evaluacion"), showWarnings = FALSE)
write_csv(ev, file.path(DIR_OUT, "evaluacion", "por_carrera.csv"))
write_csv(scores, file.path(DIR_OUT, "evaluacion", "puntajes.csv"))
write_csv(calib, file.path(DIR_OUT, "evaluacion", "calibracion_deciles.csv"))
write_csv(q_eval, file.path(DIR_OUT, "evaluacion", "Q1_Q3.csv"))
msg("Evaluacion escrita en output/evaluacion/")
