# Calibracion historica (archivo FiveThirtyEight 1998-2022)

Generado: 2026-11-02 13:57. Encuestas de los ultimos 21 dias antes de cada eleccion.

## Error del promedio final del generic ballot por ciclo (poll - resultado; >0 exagera a D)

| ciclo | intermedia | n encuestas | promedio | resultado | error |
|---|---|---|---|---|---|
| 1998 | si | 20 | +2.5 | -0.9 | +3.4 |
| 2000 | no | 30 | +1.9 | -0.3 | +2.3 |
| 2002 | si | 25 | +0.8 | -4.7 | +5.5 |
| 2004 | no | 31 | +2.2 | -2.6 | +4.8 |
| 2006 | si | 27 | +14.0 | +7.9 | +6.1 |
| 2008 | no | 21 | +8.6 | +10.5 | -1.9 |
| 2010 | si | 32 | -7.1 | -6.5 | -0.6 |
| 2012 | no | 21 | +0.4 | +1.1 | -0.7 |
| 2014 | si | 15 | -2.4 | -5.6 | +3.3 |
| 2016 | no | 24 | +2.8 | -1.0 | +3.9 |
| 2018 | si | 37 | +7.2 | +8.5 | -1.3 |
| 2020 | no | 26 | +7.8 | +3.0 | +4.8 |
| 2022 | si | 55 | -0.4 | -2.6 | +2.2 |

## Componentes de varianza (desviaciones tipicas, puntos de margen)

| componente | Camara (House-G) | Senado (Sen-G) |
|---|---|---|
| nacional (ciclo) | 2.75 | 2.88 |
| region dentro de ciclo | 1.07 | 0.72 |
| estado dentro de region | 2.96 | (residuo) |
| residuo (distrito / estado, incluye ruido del promedio de encuestas) | 6.44 | 5.54 |

## RMSE del promedio de distrito segun numero de encuestas (herding)

| encuestas | n | RMSE |
|---|---|---|
| 1 | 447 | 8.19 |
| 2 | 189 | 7.14 |
| 3-4 | 111 | 5.89 |
| 5+ | 12 | 6.92 |

## Parametros usados por el simulador

| parametro | valor | n | fuente |
|---|---|---|---|
| sigma_nat | 3.58 | 13 | RMS error promedio final generic ballot 1998-2022 (todos los ciclos) |
| sigma_nat_midterm | 3.71 | 7 | RMS solo intermedias (informativo) |
| sd_nat_demeaned | 2.73 | 13 | sd del error nacional alrededor de su media (se usa junto con delta) |
| s_sys_house | 5.00 | - | a priori: error sistematico del promedio de encuestas de distrito (no baja con n) |
| s_sys_senate | 4.50 | - | a priori: error sistematico del promedio de encuestas estatales (no baja con n) |
| partisan_shift | 2.00 | - | a priori: encuestas partidistas se corren 2 puntos contra su patrocinador |
| partisan_weight | 0.50 | - | a priori: peso relativo de encuestas partidistas |
| bias_nat_midterm | 2.66 | 7 | sesgo medio intermedias (>0 = sobreestimo a D) |
| bias_nat_pres | 2.17 | 6 | sesgo medio presidenciales |
| sigma_region_house | 1.07 | 759 | ANOVA anidada House-G (nlme) |
| sigma_state_house | 2.96 | 759 | ANOVA anidada House-G (nlme) |
| sigma_dist_polled | 6.44 | 759 | residuo distrito: error del promedio de encuestas de distrito |
| sigma_dist_fund | 6.50 | - | a priori: RMSE de modelo fundamentales (PVI+incumbencia) sin encuesta |
| sigma_region_senate | 0.75 | 385 | ANOVA anidada Sen-G (nlme) |
| sigma_state_polled | 5.54 | 385 | residuo estado: error del promedio de encuestas de Senado |
| sigma_state_fund | 9.00 | - | a priori: fundamentales de Senado (PVI estatal + incumbencia) ignoran calidad del candidato; RMSE ~9 |
| sd_poll_within_house | 4.74 | 432 | desviacion de una encuesta individual vs promedio de su carrera |
| sd_poll_within_senate | 4.09 | 2430 | idem Senado |
| beta_inc_house | 2.50 | - | a priori: ventaja de incumbencia Camara (margen), literatura 2018-2024 |
| beta_inc_senate | 4.00 | - | a priori: ventaja de incumbencia Senado (margen) |
| rv_to_lv_shift | -1.00 | - | a priori: encuestas RV se corren 1 punto hacia R en intermedias |
| delta_mean | -1.00 | - | preregistrado: hipotesis de sesgo (negativo = encuestas exageran a D) |
| delta_sd | 2.50 | - | preregistrado: incertidumbre sobre el sesgo |
| pvi_multiplier | 2.00 | - | PVI es por cuota: margen = 2*PVI |
| redistricted_extra_sd | 1.50 | - | sd adicional en distritos de estados rediseñados (mapa nuevo) |
