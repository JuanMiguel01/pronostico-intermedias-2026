# 03_calibrate.R -- calibra las varianzas del modelo jerarquico con el archivo historico de 538
# (encuestas 1998-2022 con resultado real). Descompone el error de las encuestas finales en
# componentes anidados: ciclo (nacional) -> region -> estado -> distrito, que es exactamente la
# estructura de un diseno por conglomerados en cuatro etapas.
#
# Salida: data/frozen/calibration.csv  (parametro, valor, n, fuente)  +  docs/calibracion.md
source("R/00_setup.R")
suppressPackageStartupMessages(library(nlme))

hist <- read_csv(file.path(DIR_FROZEN, "hist_polls_538.csv")) %>%
  filter(!is.na(error_d), time_to_election <= 21, time_to_election >= 0) %>%
  mutate(midterm = cycle %% 4 == 2,
         region  = unname(REGION[state]),
         w = pmin(sqrt(coalesce(samplesize, 600) / 600), 2))   # peso suave por tamano muestral

# ============================================================================
# 1. Error nacional del generic ballot (House-G-US): promedio final de 21 dias vs resultado
# ============================================================================
gen <- hist %>% filter(type == "House-G-US") %>%
  group_by(cycle, midterm) %>%
  summarise(n_polls = n(), avg_poll = weighted.mean(margin_poll_d, w),
            actual = first(margin_actual_d), .groups = "drop") %>%
  mutate(error_nat = avg_poll - actual)        # >0: las encuestas exageraron a D
msg("Generic ballot: error del promedio final por ciclo")
print(as.data.frame(gen), digits = 3)

gen_mid <- gen %>% filter(midterm)
sigma_nat_all <- sqrt(mean(gen$error_nat^2))          # RMS (incluye sesgo)
sigma_nat_mid <- sqrt(mean(gen_mid$error_nat^2))
bias_nat_mid  <- mean(gen_mid$error_nat)
bias_nat_pres <- mean(gen$error_nat[!gen$midterm])
msg("sigma_nac (RMS, todos los ciclos) = %.2f ; intermedias = %.2f ; sesgo medio intermedias = %+.2f ; presidenciales = %+.2f",
    sigma_nat_all, sigma_nat_mid, bias_nat_mid, bias_nat_pres)

# ============================================================================
# 2. Camara por distrito (House-G): ANOVA anidada ciclo/region/estado, residuo = distrito
# ============================================================================
dist <- hist %>% filter(type == "House-G", !is.na(region)) %>%
  group_by(cycle, midterm, region, state, location) %>%
  summarise(n_polls = n(), err = weighted.mean(error_d, w), .groups = "drop")
msg("House-G: %d distrito-ciclos con encuestas finales (%d ciclos)", nrow(dist), n_distinct(dist$cycle))

fit_h <- lme(err ~ 1, random = ~ 1 | cycle / region / state, data = dist,
             control = lmeControl(opt = "optim", msMaxIter = 200))
vc_h <- as.numeric(VarCorr(fit_h)[, "Variance"])
names(vc_h) <- c("cycle_hdr", "cycle", "region_hdr", "region", "state_hdr", "state", "residual")
vc_h <- vc_h[c("cycle", "region", "state", "residual")]
sd_h <- sqrt(vc_h)
msg("House-G  sd: nacional %.2f | region %.2f | estado %.2f | distrito(+ruido encuesta) %.2f | intercepto %+.2f",
    sd_h["cycle"], sd_h["region"], sd_h["state"], sd_h["residual"], fixef(fit_h))

# comparacion: error del promedio de encuestas de distrito vs error nacional del generic
dist_cycle <- dist %>% group_by(cycle, midterm) %>% summarise(err_dist_mean = mean(err), n = n(), .groups = "drop") %>%
  left_join(gen %>% select(cycle, error_nat), by = "cycle")
print(as.data.frame(dist_cycle), digits = 3)

# ============================================================================
# 3. Senado por estado (Sen-G): ciclo/region, residuo = estado
# ============================================================================
sen <- hist %>% filter(type == "Sen-G", !is.na(region)) %>%
  group_by(cycle, midterm, region, state, race) %>%
  summarise(n_polls = n(), err = weighted.mean(error_d, w), .groups = "drop")
fit_s <- lme(err ~ 1, random = ~ 1 | cycle / region, data = sen,
             control = lmeControl(opt = "optim", msMaxIter = 200))
vc_s <- as.numeric(VarCorr(fit_s)[, "Variance"])
names(vc_s) <- c("cycle_hdr", "cycle", "region_hdr", "region", "residual")
sd_s <- sqrt(vc_s[c("cycle", "region", "residual")])
msg("Sen-G    sd: nacional %.2f | region %.2f | estado(+ruido encuesta) %.2f | intercepto %+.2f",
    sd_s["cycle"], sd_s["region"], sd_s["residual"], fixef(fit_s))

# ruido de una encuesta individual de Senado/Camara alrededor del promedio de su carrera
noise <- hist %>% filter(type %in% c("Sen-G", "House-G")) %>%
  group_by(type, cycle, race) %>% filter(n() >= 3) %>%
  mutate(dev = (error_d - mean(error_d)) * sqrt(n() / (n() - 1))) %>% ungroup() %>%   # corrige el sesgo de sd con n pequeno
  group_by(type) %>% summarise(sd_poll_within = sd(dev), n = n(), .groups = "drop")
print(noise)

# ============================================================================
# 4. Error de encuestas de distrito/estado por "dias antes": herding (varianza no baja con n)
# ============================================================================
herd <- dist %>% mutate(k = cut(n_polls, c(0, 1, 2, 4, 100), labels = c("1", "2", "3-4", "5+"))) %>%
  group_by(k) %>% summarise(n = n(), rmse = sqrt(mean(err^2)), .groups = "drop")
msg("House-G: RMSE del promedio segun numero de encuestas (si no baja, hay herding/errores comunes)")
print(as.data.frame(herd), digits = 3)

# ============================================================================
# 5. Parametros finales (preregistrados). Regla: usar la estimacion empirica, acotada a un
#    rango razonable, y documentar. sigma_d para distritos SIN encuesta no se puede estimar
#    con este archivo (no tiene PVI), asi que se fija a priori (literatura: RMSE 6-8 puntos).
# ============================================================================
clamp <- function(x, lo, hi) pmin(pmax(x, lo), hi)
calib <- tribble(
  ~parameter,           ~value,                                   ~n,            ~source,
  "sigma_nat",          clamp(sigma_nat_all, 2.0, 4.0),           nrow(gen),     "RMS error promedio final generic ballot 1998-2022 (todos los ciclos)",
  "sigma_nat_midterm",  sigma_nat_mid,                            nrow(gen_mid), "RMS solo intermedias (informativo)",
  "sd_nat_demeaned",    clamp(sd(gen$error_nat), 2.0, 4.0),       nrow(gen),     "sd del error nacional alrededor de su media (se usa junto con delta)",
  "s_sys_house",        5.0,                                      NA,            "a priori: error sistematico del promedio de encuestas de distrito (no baja con n)",
  "s_sys_senate",       4.5,                                      NA,            "a priori: error sistematico del promedio de encuestas estatales (no baja con n)",
  "partisan_shift",     2.0,                                      NA,            "a priori: encuestas partidistas se corren 2 puntos contra su patrocinador",
  "partisan_weight",    0.5,                                      NA,            "a priori: peso relativo de encuestas partidistas",
  "bias_nat_midterm",   bias_nat_mid,                             nrow(gen_mid), "sesgo medio intermedias (>0 = sobreestimo a D)",
  "bias_nat_pres",      bias_nat_pres,                            sum(!gen$midterm), "sesgo medio presidenciales",
  "sigma_region_house", clamp(sd_h[["region"]], 0.75, 2.5),       nrow(dist),    "ANOVA anidada House-G (nlme)",
  "sigma_state_house",  clamp(sd_h[["state"]], 1.0, 3.0),         nrow(dist),    "ANOVA anidada House-G (nlme)",
  "sigma_dist_polled",  clamp(sd_h[["residual"]], 4.0, 8.0),      nrow(dist),    "residuo distrito: error del promedio de encuestas de distrito",
  "sigma_dist_fund",    6.5,                                      NA,            "a priori: RMSE de modelo fundamentales (PVI+incumbencia) sin encuesta",
  "sigma_region_senate",clamp(sd_s[["region"]], 0.75, 2.5),       nrow(sen),     "ANOVA anidada Sen-G (nlme)",
  "sigma_state_polled", clamp(sd_s[["residual"]], 3.0, 6.0),      nrow(sen),     "residuo estado: error del promedio de encuestas de Senado",
  "sigma_state_fund",   9.0,                                      NA,            "a priori: fundamentales de Senado (PVI estatal + incumbencia) ignoran calidad del candidato; RMSE ~9",
  "sd_poll_within_house", noise$sd_poll_within[noise$type == "House-G"], noise$n[noise$type == "House-G"], "desviacion de una encuesta individual vs promedio de su carrera",
  "sd_poll_within_senate", noise$sd_poll_within[noise$type == "Sen-G"],  noise$n[noise$type == "Sen-G"],  "idem Senado",
  "beta_inc_house",     2.5,                                      NA,            "a priori: ventaja de incumbencia Camara (margen), literatura 2018-2024",
  "beta_inc_senate",    4.0,                                      NA,            "a priori: ventaja de incumbencia Senado (margen)",
  "rv_to_lv_shift",    -1.0,                                      NA,            "a priori: encuestas RV se corren 1 punto hacia R en intermedias",
  "delta_mean",        -1.0,                                      NA,            "preregistrado: hipotesis de sesgo (negativo = encuestas exageran a D)",
  "delta_sd",           2.5,                                      NA,            "preregistrado: incertidumbre sobre el sesgo",
  "pvi_multiplier",     2.0,                                      NA,            "PVI es por cuota: margen = 2*PVI",
  "redistricted_extra_sd", 1.5,                                   NA,            "sd adicional en distritos de estados rediseñados (mapa nuevo)"
)
write_csv(calib, file.path(DIR_FROZEN, "calibration.csv"))

# ---- resumen en markdown ---------------------------------------------------
md <- c("# Calibracion historica (archivo FiveThirtyEight 1998-2022)", "",
        sprintf("Generado: %s. Encuestas de los ultimos 21 dias antes de cada eleccion.", format(Sys.time(), "%Y-%m-%d %H:%M")), "",
        "## Error del promedio final del generic ballot por ciclo (poll - resultado; >0 exagera a D)", "",
        "| ciclo | intermedia | n encuestas | promedio | resultado | error |", "|---|---|---|---|---|---|",
        sprintf("| %d | %s | %d | %+.1f | %+.1f | %+.1f |", gen$cycle, ifelse(gen$midterm, "si", "no"), gen$n_polls, gen$avg_poll, gen$actual, gen$error_nat), "",
        "## Componentes de varianza (desviaciones tipicas, puntos de margen)", "",
        "| componente | Camara (House-G) | Senado (Sen-G) |", "|---|---|---|",
        sprintf("| nacional (ciclo) | %.2f | %.2f |", sd_h["cycle"], sd_s["cycle"]),
        sprintf("| region dentro de ciclo | %.2f | %.2f |", sd_h["region"], sd_s["region"]),
        sprintf("| estado dentro de region | %.2f | (residuo) |", sd_h["state"]),
        sprintf("| residuo (distrito / estado, incluye ruido del promedio de encuestas) | %.2f | %.2f |", sd_h["residual"], sd_s["residual"]), "",
        "## RMSE del promedio de distrito segun numero de encuestas (herding)", "",
        "| encuestas | n | RMSE |", "|---|---|---|", sprintf("| %s | %d | %.2f |", herd$k, herd$n, herd$rmse), "",
        "## Parametros usados por el simulador", "",
        "| parametro | valor | n | fuente |", "|---|---|---|---|",
        sprintf("| %s | %.2f | %s | %s |", calib$parameter, calib$value, ifelse(is.na(calib$n), "-", calib$n), calib$source))
writeLines(md, file.path(DIR_DOCS, "calibracion.md"))
msg("Calibracion escrita: %s", file.path(DIR_FROZEN, "calibration.csv"))
