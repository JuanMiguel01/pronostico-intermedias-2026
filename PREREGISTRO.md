# Preregistro: pronóstico de las elecciones intermedias de EE.UU. 2026

**Autor:** Juan Miguel (prensa@wuaramedia.com)
**Congelación:** 3 de noviembre de 2026, 14:00 hora de Caracas (las primeras urnas cierran a las 19:00 Caracas).
**Qué se congela:** `output/predicciones.csv`, `output/resumen.json`, `output/resumen.md` y los datos `data/frozen/*.csv`; sus SHA-256 están en `output/SHA256SUMS.txt` y `output/SHA256SUMS_datos.txt`.

## 1. Cantidades preregistradas

| # | Cantidad | Formato |
|---|---|---|
| Q1 | Margen nacional del voto popular de la Cámara (dos partidos, D − R) | estimación + IC 80 % |
| Q2 | Escaños demócratas en la Cámara | mediana + IC 80 % + P(D ≥ 218) |
| Q3 | Escaños demócratas en el Senado (con King y Sanders; independientes nuevos aparte) | mediana + IC 80 % + P(D ≥ 51) |
| Q4 | Probabilidad del lado no republicano en los 435 distritos y 35 escaños del Senado | `output/predicciones.csv` |
| Q5 | Hipótesis de sesgo δ = resultado − promedio final de encuestas (negativo: las encuestas exageran a D) | δ ~ N(−1, 2.5²) |
| Q6 | P(D gana la Cámara ∧ R retiene el Senado) | probabilidad |

La **versión principal** es la que incluye δ ("con_delta"). Se publica también la versión "sin_delta" (δ = 0, misma varianza total) para que Q5 se evalúe limpiamente: si el error real de las encuestas tiene el signo de δ, la versión principal debe ganar en Brier y log score.

## 2. Hipótesis sustantivas (lo que se está apostando)

1. **No‑respuesta diferencial residual:** los votantes de Trump siguen respondiendo menos; la ponderación por voto recordado 2024 lo corrige solo en parte. Por eso δ tiene media negativa. El archivo histórico (1998–2022) muestra que el promedio final del generic ballot exageró a los demócratas en 2.7 puntos de media en intermedias (ver `docs/calibracion.md`); se usa una media más prudente (−1) porque 2026 es el primer ciclo con ponderación masiva por voto recordado, que puede sobrecorregir hacia R.
2. **Los errores están correlacionados por conglomerados** (nación → región → estado → distrito). Asumir distritos independientes daría P(mayoría D) ≈ 0.99; el diseño multietápico la baja a la cifra publicada.
3. **Herding:** la varianza del promedio de encuestas de una carrera no cae a cero con el número de encuestas; hay un piso sistemático (`s_sys_house`, `s_sys_senate`).

## 3. Decisiones metodológicas fijadas antes de ver resultados

| Decisión | Valor |
|---|---|
| Ventana generic ballot | 21 días; peso de recencia 0.5^(edad/10 días) × min(√(n/600), 2) |
| Ventana carreras | 35 días (ampliable a 75 si hay < 3 encuestas) |
| Indecisos | reparto proporcional (margen a dos partidos) |
| RV → LV | −1 punto hacia R |
| Encuestas partidistas | −2 puntos contra el patrocinador y peso 0.5 |
| Adultos (A) | excluidas |
| Efectos de casa | desviación del encuestador respecto al promedio local (±7 días) de los demás, ventana de 90 días, encogida n/(n+3) |
| Calidad del encuestador | peso 0.6–1.0 según la nota numérica de FiveThirtyEight (2024); desconocidos 0.8 |
| Incertidumbre de μ_G | bootstrap en dos etapas (encuestadores → encuestas), 2000 réplicas |
| Fundamentales Cámara | μ_G + 2·PVI₂₀₂₆ + 2.5·incumbencia (×0.5 en mapas nuevos); σ = 6.5 (+1.5 en estados rediseñados) |
| Fundamentales Senado | μ_G + 2·PVI_estado + 4·incumbencia; σ = 9 |
| Calificaciones de expertos | promedio de Cook, Sabato, Inside Elections, DDHQ (y otros) vía Wikipedia, convertido a margen: Toss‑up 0, Tilt ±2.5, Lean ±5, Likely ±9, Solid/Safe ±18; σ = 6 (10 si Solid/Safe) |
| Combinación | precisión inversa de fundamentales, encuestas y calificación; var. encuesta = s_sys² + s_within²/n_eff |
| Correlación Cámara–Senado | comparten ε_nac, ε_región y la mitad de ε_estado |
| Componentes de error | σ_nac, σ_región, σ_estado, σ_distrito calibrados con 538 1998–2022 (`data/frozen/calibration.csv`) |
| Error diferencial por PVI | κ·PVI·η con κ = 0.1 y η ~ N(0,1) común a todo el país (2016/2020: las encuestas fallaron más en zonas republicanas) |
| Antigüedad de encuestas | la sd del promedio de una carrera crece 0.07 puntos por día desde su encuesta más reciente |
| Calificación con encuestas | varianza ×2 cuando la carrera tiene encuestas (información parcialmente redundante) |
| Réplicas | 20 000, semilla 20261103 |
| Sin competencia | el único partido mayor gana con P = 1 |
| Independientes | NE (Osborn), MT (Bodnar), SD (Bengs): ocupan el lado "no R"; se cuentan aparte de los escaños D |
| CA‑06 | Kiley (independiente, ex‑R) se modela en el lado R con ventaja de incumbencia |
| Missouri | vota con el mapa de 2022 (el mapa de 2025 está suspendido por el referendo de veto, Prop. A): se usa el PVI 2025, no el 2026 de Cook |
| Mapas nuevos en vigor | AL, CA, FL, LA, NC, OH, TN, TX, UT (PVI 2026 de Cook) |

## 4. Evaluación preregistrada (`R/06_evaluate.R`)

- Brier y log score sobre las 470 probabilidades, por cámara, frente a: versión sin δ, solo fundamentales y "clima" (frecuencia base).
- Calibración por deciles.
- MAE y sesgo del margen por distrito/estado; cobertura real de los IC 80 % (¿caen Q1–Q3 dentro?).
- Q5: δ observado = voto popular real − μ_G; se compara con la distribución preregistrada.
- Post‑mortem multietápico: ANOVA anidada (`nlme::lme`) de los residuos de margen región/estado; si la mayor parte del error es nacional, el problema fue sesgo sistemático; si es distrital, información local.
- Líneas base: (a) swing uniforme sin δ, (b) solo fundamentales, (c) Poliwave, PollCheck y Silver Bulletin, (d) Polymarket (precio del contrato "Democratic Party controls" al momento de la descarga) — todas en `output/lineas_base.csv`.
- Sensibilidad: `output/resumen.md` incluye la tabla de P(D Cámara) y P(D Senado) para medias de δ de 0, −1, −2, −2.7 y −4, para que el lector vea cuánto depende el pronóstico de la hipótesis Q5.
- Fechas: evaluación provisional con llamadas de AP el 10 de noviembre; definitiva con certificados.
- Carga de resultados: `Rscript R/07_resultados.R` lee las tablas de resultados de Wikipedia (435 distritos + 35 escaños) y escribe `output/resultados.csv`; luego `Rscript R/06_evaluate.R`. El cargador está probado con las páginas de 2024 (`--prueba2024`).

## 5. Anclaje externo del hash

1. Correr `Rscript run_all.R --sin-descarga` por última vez y copiar `output/SHA256SUMS.txt`.
2. OSF (osf.io): crear registro "Preregistration" con este PDF/MD y el hash; OSF da timestamp inmutable y DOI.
3. OpenTimestamps (opentimestamps.org): subir `predicciones.csv` → se obtiene `.ots` anclado en Bitcoin; guardar el `.ots` en `output/`.
4. Publicar el hash y el enlace al repositorio en redes antes de las 19:00 Caracas.
5. Metaculus/Manifold: someter P(D Cámara), P(D Senado) y, si hay preguntas por carrera, las probabilidades de `predicciones.csv`.

Después de la congelación **no se toca ningún número**; cualquier corrección va en un commit posterior claramente etiquetado y no entra en la evaluación.

## 6. Anexo: la encuesta multietápica que se haría con recursos

Estratos = estado × competitividad (Cook). UPM = condados seleccionados con probabilidad proporcional al tamaño (PPT) por electores registrados. USM = precintos dentro del condado, PPT. UTM = personas del padrón electoral (voter file, con historial de participación como variable auxiliar) o direcciones por ABS. n ≈ 1 500 por estado competitivo; deff esperado 1.5–2. Pesos = inverso de la probabilidad de inclusión × ajuste de no‑respuesta por clases (propensity score con variables del padrón, no solo demografía) × raking a censo y a voto recordado **validado contra el padrón**, que es la única forma de atacar de raíz el sesgo del voto recordado autorreportado.
