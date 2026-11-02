# Formulario "OSF Preregistration", campo por campo

Copiar cada bloque en el campo del mismo nombre. Los campos que no aplican llevan la frase indicada para que el formulario no quede vacío.

## Title
Pronóstico preregistrado de las elecciones intermedias de EE.UU. 2026 (Cámara y Senado)

## Authors
Juan Miguel Pérez Martínez

## Description
Pronóstico probabilístico de las elecciones del 3 de noviembre de 2026 a la Cámara de Representantes (435 distritos) y al Senado (35 escaños) de Estados Unidos, construido a partir de encuestas públicas, fundamentales (Cook PVI 2026, incumbencia) y calificaciones de expertos, con una simulación jerárquica del error (nación → región → estado → distrito) y una hipótesis explícita sobre el sesgo de las encuestas. Todo el código, los datos congelados y las predicciones están en https://github.com/JuanMiguel01/pronostico-intermedias-2026 (etiqueta git `congelado-2026-11-02`). El archivo de predicciones tiene SHA-256 a33f9c72b2f77723053940c3d039c5fac369c6e6197817859a5dd40e26b84333 y está sellado con OpenTimestamps el 2 de noviembre de 2026.

## Hypotheses
H1. Las encuestas finales sobreestiman a los demócratas: el sesgo δ = resultado − promedio final del generic ballot (margen D − R a dos partidos) sigue aproximadamente N(−1, 2.5²). En las intermedias de 1998 a 2022 el error medio fue −2.7; se preregistra una media más prudente porque 2026 es el primer ciclo con ponderación generalizada por voto recordado de 2024, que puede sobrecorregir.
H2. Los errores de las 470 carreras están correlacionados por conglomerados (nación → región → estado → distrito). Un modelo que los trate como independientes daría P(mayoría demócrata en la Cámara) ≈ 0.99; el modelo preregistrado da 0.81.
H3. La varianza del promedio de encuestas de una carrera no cae a cero al aumentar el número de encuestas (herding): existe un piso de error sistemático.

## Study type
Other. Estudio de pronóstico observacional: no hay intervención ni recogida propia de datos. Se agregan encuestas y datos públicos ya existentes y se evalúa el pronóstico contra los resultados oficiales.

## Blinding
No blinding is involved in this study.

## Study design
Pronóstico preregistrado con evaluación posterior. Unidades: 435 distritos de la Cámara y 35 escaños del Senado. Para cada unidad se estima el margen D − R combinando por precisión inversa tres fuentes: fundamentales (entorno nacional + 2·PVI + ventaja de incumbencia), promedio de encuestas de la carrera y calificación de expertos. Se simulan 20 000 escenarios con componentes de error anidados cuyas desviaciones se calibraron en 18 250 encuestas de 1998–2022 con resultado real (archivo FiveThirtyEight). Se publican dos versiones: con δ (principal) y con δ = 0.

## Randomization
No randomization. Semilla de simulación preregistrada: 20261103.

## Existing data
Registration prior to analysis of the data. Los datos (encuestas públicas, PVI, calificaciones) fueron descargados y congelados el 2 de noviembre de 2026; los resultados electorales, que son la variable de evaluación, aún no existen.

## Explanation of existing data
Las encuestas y fundamentales son públicos y se descargaron el 2 de noviembre de 2026 (manifiesto con SHA-256 en el repositorio). El pronóstico se generó ese mismo día antes de conocer ningún resultado. Los resultados electorales se recogerán a partir del 3 de noviembre de 2026.

## Data collection procedures
Encuestas nacionales: Wikipedia (tabla de generic ballot) y Poliwave. Encuestas por carrera: Poliwave (35 carreras senatoriales, 119 distritos). Fundamentales: Cook Political Report, PVI 2026, con votos presidenciales 2020 y 2024 por distrito. Calificaciones de expertos (Cook, Sabato, Inside Elections, DDHQ): páginas estatales de Wikipedia. Calibración: archivo histórico de FiveThirtyEight (raw_polls.csv). Resultados: llamadas de AP vía Wikipedia (evaluación provisional el 10 de noviembre de 2026) y resultados certificados (evaluación definitiva).

## Sample size
435 distritos de la Cámara y 35 escaños del Senado (470 carreras). 38 encuestas nacionales de los últimos 21 días, 619 encuestas senatoriales y 335 de distrito en el archivo congelado.

## Sample size rationale
Es el universo completo de carreras en disputa; no hay muestreo.

## Stopping rule
No aplica: la congelación de datos fue el 2 de noviembre de 2026 a las 18:32 UTC y no se incorporan encuestas posteriores.

## Manipulated variables
Ninguna.

## Measured variables
Resultados: Q1 margen del voto popular de la Cámara a dos partidos (D − R); Q2 escaños demócratas en la Cámara; Q3 escaños demócratas en el Senado (incluyendo a King y Sanders); Q4 ganador de cada una de las 470 carreras; Q5 δ observado = margen real del voto popular − promedio final de encuestas; Q6 ocurrencia conjunta de Cámara demócrata y Senado republicano.
Predictores: promedio del generic ballot, PVI 2026, incumbencia, promedios de encuestas por carrera, calificaciones de expertos.

## Indices
Margen a dos partidos: 100·(D − R)/(D + R). Probabilidad por carrera: fracción de simulaciones en que el margen es positivo.

## Statistical models
Modelo de simulación: m_d = m̂_d + (δ + ε_nac) + ε_región + ε_estado + ε_distrito + κ·PVI_d·η, con δ ~ N(−1, 2.5²), ε_nac ~ N(0, 2.7²) más la incertidumbre del promedio (bootstrap en dos etapas: encuestadores → encuestas), ε_región ~ N(0, 1.07²), ε_estado ~ N(0, 2.96²), ε_distrito con desviación 6.5 (fundamentales) o la que resulte de la combinación con encuestas y calificaciones, κ = 0.1, η ~ N(0,1). Senado: mismo esquema con PVI estatal y sin ε_distrito, compartiendo ε_nac, ε_región y la mitad de ε_estado con la Cámara. 20 000 réplicas. Detalle completo en PREREGISTRO.md.

## Transformations
Indecisos repartidos proporcionalmente (margen a dos partidos). Encuestas de votantes registrados corridas 1 punto hacia R. Encuestas partidistas corridas 2 puntos contra su patrocinador y con peso 0.5. Efectos de casa por encuestador estimados en 90 días. Calificaciones convertidas a margen: Toss-up 0, Tilt ±2.5, Lean ±5, Likely ±9, Solid/Safe ±18.

## Inference criteria
Predicciones puntuales: medianas de la simulación; intervalos del 80 % (percentiles 10 y 90). Evaluación: Brier y log score sobre las 470 probabilidades por carrera (solo carreras competidas), calibración por deciles, cobertura empírica de los intervalos del 80 % para Q1–Q3, error absoluto medio del margen por distrito y estado. Comparación con cuatro líneas base preregistradas: swing uniforme sin δ, solo fundamentales, agregadores externos (Poliwave, PollCheck, Silver Bulletin) y Polymarket. H1 se considera respaldada si el δ observado es negativo y la versión con δ obtiene mejor Brier que la versión sin δ.

## Data exclusion
Encuestas de adultos (no votantes) excluidas. Encuestas de carrera en que un partido mayor tiene menos del 15 % excluidas (no son duelos D–R). 19 escaños sin rival de los dos partidos grandes se fijan con probabilidad 1 y no entran en la evaluación.

## Missing data
Distritos sin encuestas (342) usan fundamentales y calificaciones; carreras senatoriales sin encuestas (5) usan fundamentales y calificaciones. Missouri usa el PVI 2025 porque vota con el mapa de 2022.

## Exploratory analysis
Post-mortem multietápico: ANOVA anidada (región/estado) de los residuos de margen para descomponer el error en nacional, regional, estatal y distrital. Tabla de sensibilidad a la media de δ (0, −1, −2, −2.7, −4), ya publicada en el repositorio.

## Other
Hashes SHA-256 de los archivos congelados:
a33f9c72b2f77723053940c3d039c5fac369c6e6197817859a5dd40e26b84333 predicciones.csv
3dbd6a446f1831ac3d1eba136720cc070948af56778b4c371db219c3d0bc9252 resumen.json
83b40a406e30907022be2c5c50f68a1317a1454f85bb43e1572827e54b874472 resumen.md
Pronóstico principal (con δ): Cámara D 231 escaños [212, 254], P(D ≥ 218) = 0.807; Senado D 51 [48, 55], P(D ≥ 51) = 0.597; voto popular D +7.4 [+2.7, +12.2]; P(Cámara D y Senado R) = 0.219.
Página del pronóstico: https://claude.ai/artifact/VukesKW717AewmHnrQUf4P
