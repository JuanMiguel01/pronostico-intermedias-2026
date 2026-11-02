# Pronóstico de las elecciones intermedias de EE.UU. 2026 — Cámara y Senado

*Forecast of the 2026 U.S. midterm elections (House and Senate). English summary at the end.*

Pronóstico **preregistrado** de las elecciones del 3 de noviembre de 2026, construido a partir de encuestas públicas y fundamentales, con una simulación jerárquica (multietápica: nación → región → estado → distrito) y una hipótesis explícita sobre el sesgo de las encuestas. Las cantidades preregistradas, las decisiones metodológicas y el plan de evaluación están en [PREREGISTRO.md](PREREGISTRO.md). Los resultados numéricos están en [output/resumen.md](output/resumen.md) y, carrera por carrera, en [output/predicciones.csv](output/predicciones.csv).

## Estructura

```
R/00_setup.R        paquetes, rutas, utilidades, regiones censales
R/01_download.R     descarga cruda (Cook PVI 2026, Wikipedia, Poliwave, archivo 538) -> data/raw/<fecha>/ + MANIFEST.csv con SHA-256
R/02_clean.R        parseo -> data/frozen/*.csv (distritos, Senado, encuestas, histórico)
R/03_calibrate.R    varianzas por nivel con el archivo 538 1998-2022 (ANOVA anidada, nlme) -> data/frozen/calibration.csv, docs/calibracion.md
R/04_model.R        promedio generic ballot (efectos de casa + bootstrap en dos etapas), promedios por carrera, simulación 20 000 réplicas
R/05_outputs.R      predicciones.csv, resumen.md/json, distribución de escaños, líneas base, figuras, SHA256SUMS
R/06_evaluate.R     evaluación preregistrada (Brier, log score, calibración, cobertura IC80, ANOVA anidada de residuos)
R/07_resultados.R   carga los resultados desde Wikipedia (llamadas de AP) -> output/resultados.csv; probado con las páginas de 2024
R/utils.R           funciones puras compartidas; pruebas en tests/test_utils.R (Rscript tests/test_utils.R)
run_all.R           corre toda la cadena:  Rscript run_all.R   (o  --sin-descarga)
```

Requisitos: R ≥ 4.3 con `dplyr, tidyr, readr, stringr, purrr, rvest, xml2, httr, jsonlite, lubridate, digest, ggplot2` (y `nlme`, incluido en R).

## Datos

| Fuente | Qué aporta | Acceso |
|---|---|---|
| Cook Political Report, PVI 2026 | 435 distritos: PVI 2026 y 2025, votos Harris/Trump 2024 y Biden/Trump 2020 por distrito nuevo, incumbente | Datawrapper embebido en la página pública (`rAx2t`) |
| Wikipedia (API `action=parse`) | generic ballot completo (fechas, n, LV/RV/A), candidatos por distrito y por escaño senatorial, PVI estatal, promedios de otros agregadores | público |
| Poliwave | encuestas por carrera senatorial (35) y por distrito (119); se usa el historial completo embebido en el JS de cada página, no solo la tabla de 20 | público |
| FiveThirtyEight (GitHub) | `raw_polls.csv`: 18 250 encuestas 1998–2022 con resultado real, para calibrar varianzas; `pollster-ratings-combined.csv` para ponderar por calidad del encuestador | público |
| Wikipedia, páginas por estado (51) | calificaciones por distrito de Cook, Sabato, Inside Elections, DDHQ, Economist, Silver Bulletin; para el Senado, tabla con 12 calificadores | público |
| Polymarket (API gamma) | precio de "qué partido controla la Cámara / el Senado", línea base (d) | público |

FiftyPlusOne ofrece API solo de pago; no se usa. Los HTML crudos (75 MB) no se versionan, pero `data/raw/<fecha>/MANIFEST.csv` guarda su SHA-256 y los CSV congelados en `data/frozen/` sí están en el repositorio.

## Modelo (resumen)

1. **Entorno nacional μ_G:** encuestas de los últimos 21 días (LV y RV; RV −1 hacia R; partidistas −2 y peso 0.5), margen a dos partidos (indecisos proporcionales), peso por recencia, tamaño y calidad del encuestador (notas de 538), efecto de casa por encuestador estimado en 90 días. Incertidumbre por **bootstrap en dos etapas** (encuestadores → encuestas).
2. **Sesgo δ (Q5):** δ ~ N(−1, 2.5²). Se publican dos versiones: con δ (principal) y sin δ, más una tabla de sensibilidad a la media de δ.
3. **Carreras:** fundamentales (μ_G + 2·PVI + incumbencia, reducida a la mitad en mapas nuevos), promedio de encuestas de la carrera y calificación de expertos (Cook, Sabato, Inside Elections, DDHQ) combinados por precisión inversa; la varianza de la encuesta tiene un piso sistemático (herding).
4. **Error por conglomerados:** ε_nac + ε_región + ε_estado + ε_distrito, con desviaciones calibradas en el archivo histórico (ver `docs/calibracion.md`). La Cámara y el Senado comparten ε_nac y ε_región, de modo que Q6 es coherente.
5. **Casos especiales:** 19 distritos sin competencia entre los dos partidos (P = 1); CA‑06 (Kiley, independiente ex‑R, en el lado R); Senado con independientes principales en NE, MT y SD (se cuentan aparte de los escaños D); Missouri vota con el mapa de 2022 porque el nuevo está suspendido por el referendo de veto (Prop. A), así que usa el PVI 2025 y no el 2026 de Cook.

## Cómo reproducir

```r
# desde la carpeta del proyecto
Rscript run_all.R              # descarga + limpieza + calibración + simulación + entregables
Rscript run_all.R --sin-descarga
Rscript R/06_evaluate.R --simulado   # autoprueba de la evaluación
Rscript R/06_evaluate.R              # la noche electoral: crea output/resultados.csv y, una vez relleno, evalúa
```

## Congelación y verificación

`output/SHA256SUMS.txt` contiene los hashes de los entregables; `output/SHA256SUMS_datos.txt`, los de los datos congelados. El procedimiento de anclaje externo (OSF, OpenTimestamps, redes) está en PREREGISTRO.md. Para verificar: `sha256sum -c output/SHA256SUMS.txt` desde `output/`.

## Limitaciones conocidas

- El archivo histórico de 538 termina en 2022; la calibración no incluye 2024.
- Las encuestas de distrito provienen casi todas de Poliwave y muchas son internas/partidistas; el ajuste de ±2 puntos es una convención, no una estimación.
- Los fundamentales de Senado (PVI + incumbencia) ignoran la calidad de los candidatos; por eso su σ es 9 y pesan menos que las encuestas.
- Tres distritos (AK‑AL, CA‑01, NC‑07) usan solo la tabla visible de Poliwave porque su JS embebido usa referencias; AK‑AL además tiene varios candidatos por partido (RCV) y sus encuestas no entran al modelo.
- Alaska y Maine usan voto por orden de preferencia; el modelo trata el duelo D–R final.

---

## English summary

Preregistered forecast of the November 3, 2026 U.S. midterms built in R from public polls (Wikipedia, Poliwave), Cook PVI 2026 fundamentals and the FiveThirtyEight 1998–2022 poll archive for calibration. The simulation is hierarchical (national → region → state → district error components, i.e., a four‑stage cluster design), the generic‑ballot uncertainty comes from a two‑stage bootstrap (pollsters → polls), and the headline version includes an explicit poll‑bias hypothesis δ ~ N(−1, 2.5²) (negative = polls overstate Democrats); a δ = 0 version is published alongside. Preregistered quantities: national House two‑party margin, Democratic House seats and P(majority), Democratic Senate seats and P(≥ 51), 470 race probabilities (`output/predicciones.csv`), the bias hypothesis, and P(D House ∧ R Senate). Evaluation plan (Brier, log score, calibration, interval coverage, nested ANOVA of residuals) is in `R/06_evaluate.R` and PREREGISTRO.md. Hashes of the frozen deliverables are in `output/SHA256SUMS.txt`.
