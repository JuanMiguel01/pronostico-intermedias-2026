# Acta de congelación

- **Fecha de congelación:** 2 de noviembre de 2026 (entregables generados a las 18:32:41 UTC, 14:32 Caracas).
- **Datos:** encuestas con trabajo de campo hasta el 1 de noviembre de 2026; descarga cruda del 2 de noviembre (`data/raw/2026-11-02/MANIFEST.csv`).
- **Commit etiquetado:** `congelado-2026-11-02`.
- **Qué no se toca desde ahora:** `output/predicciones.csv`, `output/resumen.json`, `output/resumen.md`, `output/distribucion_escanos.csv`, `output/lineas_base.csv` y todo `data/frozen/`.

## Hashes SHA-256 (los que se anclan)

```
a33f9c72b2f77723053940c3d039c5fac369c6e6197817859a5dd40e26b84333  predicciones.csv
3dbd6a446f1831ac3d1eba136720cc070948af56778b4c371db219c3d0bc9252  resumen.json
83b40a406e30907022be2c5c50f68a1317a1454f85bb43e1572827e54b874472  resumen.md
704ffbea4932c2c16008277e60c2edc4b523d9620876aed9777c38e16381f18d  distribucion_escanos.csv
94a64e7068c8cf9080bbc6c19b74aab3655657c29856ac6d8acbc708c140391d  lineas_base.csv
```

Verificación: desde `output/`, `sha256sum -c SHA256SUMS.txt`.

## Cantidades preregistradas (versión principal, con δ)

| # | Cantidad | Valor |
|---|---|---|
| Q1 | Margen del voto popular de la Cámara (dos partidos, D − R) | +7.4 [IC 80 %: +2.7, +12.2] |
| Q2 | Escaños demócratas en la Cámara | 231 [212, 254]; P(D ≥ 218) = 0.807 |
| Q3 | Escaños demócratas en el Senado (con King y Sanders) | 51 [48, 55]; P(D ≥ 51) = 0.597 |
| Q4 | 470 probabilidades por carrera | `predicciones.csv`, columna `p_nonR` |
| Q5 | Sesgo de las encuestas δ (resultado − promedio final) | N(−1, 2.5²); IC 80 % [−4.2, +2.2] |
| Q6 | P(D gana la Cámara ∧ R retiene el Senado) | 0.219 |

Versión sin δ: P(D Cámara) 0.872, P(D Senado) 0.688.

## Texto para OSF (formulario "Preregistration")

**Título:** Pronóstico preregistrado de las elecciones intermedias de EE.UU. 2026 (Cámara y Senado) con simulación jerárquica y una hipótesis explícita de sesgo de encuestas.

**Hipótesis:** (1) Las encuestas finales sobreestiman a los demócratas: δ = resultado − promedio final ~ N(−1, 2.5²) en el margen del voto popular de la Cámara. (2) Los errores de las 470 carreras están correlacionados por conglomerados (nación → región → estado → distrito); por eso P(mayoría D) es 0.81 y no 0.99. (3) La varianza del promedio de encuestas de una carrera no baja a cero con el número de encuestas (herding).

**Diseño:** agregación de encuestas públicas (Wikipedia, Poliwave), fundamentales (Cook PVI 2026, incumbencia) y calificaciones de expertos, combinados por precisión inversa; 20 000 simulaciones con componentes de error calibrados en 18 250 encuestas 1998–2022 (FiveThirtyEight). Todas las decisiones están en `PREREGISTRO.md`; el código completo en el repositorio.

**Variables de resultado:** Q1–Q6 arriba. **Análisis preregistrado:** Brier y log score por cámara frente a cuatro líneas base (swing uniforme, solo fundamentales, agregadores externos, Polymarket), calibración por deciles, cobertura de los intervalos del 80 %, δ observado frente a la hipótesis, y descomposición del error de margen por nivel (ANOVA anidada). Evaluación provisional el 10 de noviembre con llamadas de AP; definitiva con certificados.

**Archivos adjuntos:** `PREREGISTRO.md`, `predicciones.csv`, `SHA256SUMS.txt`.

## Post para redes (antes de las 19:00 de Caracas del 3 de noviembre)

**Español**

> Pronóstico preregistrado de las intermedias de EE.UU. 2026, congelado el 2 de noviembre:
> Cámara: 81 % demócrata, 231 escaños [212–254]. Senado: 60 % demócrata, 51 escaños [48–55]. Congreso dividido (Cámara D, Senado R): 22 %.
> Hipótesis explícita: las encuestas exageran a los demócratas ~1 punto.
> SHA-256 de predicciones.csv: a33f9c72b2f77723053940c3d039c5fac369c6e6197817859a5dd40e26b84333
> Código, datos y 470 probabilidades por carrera: https://github.com/JuanMiguel01/pronostico-intermedias-2026 · Página: https://claude.ai/artifact/VukesKW717AewmHnrQUf4P

**English**

> Preregistered forecast of the 2026 U.S. midterms, frozen Nov 2:
> House: 81% Democratic, 231 seats [212–254]. Senate: 60% Democratic, 51 seats [48–55]. Split Congress (D House, R Senate): 22%.
> Explicit hypothesis: polls overstate Democrats by ~1 point.
> SHA-256 of predicciones.csv: a33f9c72b2f77723053940c3d039c5fac369c6e6197817859a5dd40e26b84333
> Code, data and all 470 race probabilities: https://github.com/JuanMiguel01/pronostico-intermedias-2026 · Page: https://claude.ai/artifact/VukesKW717AewmHnrQUf4P

## Metaculus / Manifold

- ¿Qué partido controla la Cámara tras 2026? Demócratas **0.81**.
- ¿Qué partido controla el Senado tras 2026? Demócratas (con independientes que ya caucusan) **0.60**; si la pregunta cuenta a un independiente nuevo como "no republicano", 0.61.
- Carreras senatoriales (probabilidad del lado no republicano): ver la tabla "Carreras senatoriales" en `resumen.md` o la columna `p_nonR` de `predicciones.csv`.

## Pasos de hoy

1. `git push` del repositorio (público) con la etiqueta: `git push origin congelado-2026-11-02` (hecho).
2. OSF: hecho el 2 de noviembre de 2026 a las 15:15 Caracas, plantilla "OSF Preregistration", proyecto asociado https://osf.io/35xdw.
3. OpenTimestamps: opentimestamps.org → arrastrar `predicciones.csv` → guardar el `.ots` en `output/` y hacer commit.
4. Publicar el post con el hash y los enlaces.
5. Metaculus/Manifold con las probabilidades.
6. No volver a correr `run_all.R` hasta después de la elección.
