# Resumen del pronostico (cantidades preregistradas Q1-Q6)

Generado: 2026-11-02 18:32 UTC. Version principal: **con_delta**. Simulaciones: 20000.

Promedio generic ballot (dos partidos, LV, efectos de casa): **D+8.4** (sd bootstrap en dos etapas 0.46).

| Cantidad | con delta (principal) | sin delta |
|---|---|---|
| Q1 margen voto popular Camara (2 partidos) | 7.4 [IC80 2.7, 12.2] | 8.4 [3.8, 13.0] |
| Q2 escanos D Camara | 231 [IC80 212, 254] | 235 [215, 258] |
| Q2 P(D >= 218) | 0.807 | 0.872 |
| Q3 escanos D Senado (con King y Sanders) | 51 [IC80 48, 55] | 52 [48, 55] |
| Q3 P(D >= 51) | 0.597 | 0.688 |
| Q3 P(D + independientes nuevos >= 51) | 0.609 | 0.699 |
| Q5 delta (sesgo de encuestas, negativo = exageran a D) | -1.0 [IC80 -4.2, 2.2] | 0 (fijo) |
| Q6 P(D gana Camara y R retiene Senado) | 0.219 | 0.191 |
| P(D Camara y D Senado) | 0.589 | 0.681 |
| P(R Camara y R Senado) | 0.184 | 0.121 |

Q4 (470 probabilidades por carrera): `output/predicciones.csv`.

## Lineas base

| linea base | Camara D | P(D Camara) | Senado D | P(D Senado) | fuente |
|---|---|---|---|---|---|
| modelo principal (con delta) | 231 | 0.81 | 51 | 0.60 | este repositorio |
| modelo sin delta | 235 | 0.87 | 52 | 0.69 | este repositorio |
| (a) swing uniforme sin delta | 228 | 1.00 | 49 | 0.00 | este repositorio |
| (b) solo fundamentales | 237 | 0.90 | 50 | 0.41 | este repositorio |
| (c) Poliwave | - | 0.89 | 54 | 0.78 | poliwave.com/us/fed/projection (consultado 2026-11-02) |
| (c) PollCheck | 230 | - | 50 | - | PollCheck (Senado: D 50, R 45, 5 sin definir), citado en el plan |
| (c) Silver Bulletin (FLIPR) | 238 | 0.95 | - | - | Silver Bulletin: ~95% Camara, +25 escanos netos sobre 213 actuales, citado en el plan |
| (d) Polymarket (mercado de prediccion) | - | 0.94 | - | 0.73 | gamma-api.polymarket.com (which-party-will-win-the-house/senate-in-2026) |

## Sensibilidad a la hipotesis de sesgo (media de delta; 5 000 replicas cada una)

| media de delta | Camara D mediana | P(D Camara) | Senado D mediana | P(D Senado) | P(D Camara y R Senado) |
|---|---|---|---|---|---|
| 0.0 | 235 | 0.868 | 52 | 0.684 | 0.191 |
| -1.0 | 230 | 0.803 | 51 | 0.597 | 0.215 |
| -2.0 | 226 | 0.722 | 51 | 0.503 | 0.230 |
| -2.7 | 224 | 0.665 | 50 | 0.439 | 0.238 |
| -4.0 | 219 | 0.532 | 49 | 0.318 | 0.229 |

## Carreras senatoriales (version principal)

| carrera | P(no R) | lado no R | margen mediana | IC80 | encuestas | calificacion |
|---|---|---|---|---|---|---|
| MA | 1.000 | Ed Markey | 28.3 | [20.2, 36.3] | 3 | Safe D |
| RI | 1.000 | Jack Reed | 29.5 | [21.6, 37.3] | 3 | Safe D |
| DE | 0.998 | Chris Coons | 22.7 | [12.7, 32.8] | 0 | Safe D |
| OR | 0.998 | Jeff Merkley | 22.7 | [12.7, 32.8] | 0 | Safe D |
| IL | 0.996 | Juliana Stratton | 16.1 | [8.2, 24.1] | 3 | Safe D |
| CO | 0.994 | John Hickenlooper | 16.6 | [8.2, 24.9] | 1 | Safe D |
| NM | 0.994 | Ben Ray Luján | 17.0 | [8.3, 25.7] | 1 | Safe D |
| NJ | 0.991 | Cory Booker | 18.4 | [8.3, 28.4] | 0 | Safe D |
| VA | 0.987 | Mark Warner | 17.3 | [7.3, 27.4] | 0 | Safe D |
| GA | 0.962 | Jon Ossoff | 10.2 | [2.8, 17.4] | 5 | Likely D |
| NH | 0.945 | Chris Pappas | 9.3 | [1.9, 16.7] | 7 | Lean D |
| NC | 0.943 | Roy Cooper | 9.2 | [1.7, 16.5] | 12 | Likely D |
| MN | 0.913 | Peggy Flanagan | 7.5 | [0.4, 14.7] | 14 | Lean D |
| ME | 0.824 | Troy Jackson | 5.2 | [-2.0, 12.3] | 18 | Lean D |
| MI | 0.821 | Abdul El-Sayed | 5.2 | [-2.0, 12.3] | 21 | Likely D |
| TX | 0.600 | James Talarico | 1.4 | [-5.8, 8.4] | 34 | Tossup |
| OH-S | 0.532 | Sherrod Brown | 0.5 | [-6.7, 7.7] | 22 | Tossup |
| AK | 0.436 | Mary Peltola | -0.9 | [-8.2, 6.4] | 6 | Tossup |
| KS | 0.424 | Adam Hamilton | -1.1 | [-8.4, 6.2] | 12 | Tossup |
| IA | 0.400 | Josh Turek | -1.4 | [-8.8, 5.8] | 17 | Tossup |
| SC | 0.191 | Annie Andrews | -4.9 | [-12.2, 2.4] | 10 | Lean R |
| NE | 0.191 | Dan Osborn | -5.2 | [-12.7, 2.4] | 11 | Lean R |
| FL-S | 0.080 | Angie Nixon | -7.8 | [-14.9, -0.6] | 20 | Likely R |
| LA | 0.075 | Jamie Davis | -8.6 | [-16.5, -0.9] | 2 | Likely R |
| MT | 0.045 | Seth Bodnar | -9.8 | [-17.6, -2.4] | 5 | Likely R |
| MS | 0.042 | Scott Colom | -10.4 | [-18.2, -2.6] | 1 | Likely R |
| SD | 0.016 | Brian Bengs | -13.3 | [-21.4, -5.2] | 6 | Solid R |
| KY | 0.007 | Charles Booker | -17.3 | [-26.4, -8.4] | 1 | Solid R |
| AR | 0.006 | Hallie Shoffner | -16.2 | [-24.6, -8.0] | 2 | Safe R |
| AL | 0.001 | Everett Wess | -19.4 | [-27.3, -11.5] | 3 | Safe R |
| OK | 0.001 | N'Kiyla Jasmine Thomas | -25.3 | [-35.7, -15.1] | 0 | Safe R |
| TN | 0.000 | Marquita Bradshaw | -24.5 | [-33.6, -15.5] | 1 | Safe R |
| WY | 0.000 | James W. Byrd | -29.8 | [-40.2, -19.4] | 0 | Safe R |
| ID | 0.000 | - | -100.0 | [-100.0, -100.0] | 0 | Safe R |
| WV | 0.000 | Rachel Fetty Anderson | -29.8 | [-40.2, -19.6] | 0 | Safe R |

## Distritos mas competitivos (P(D) entre 0.2 y 0.8, version principal)

| distrito | P(D) | PVI | incumbente | margen mediana | encuestas | calificacion |
|---|---|---|---|---|---|---|
| AZ-02 | 0.203 | -6.7 | Eli Crane (R) | -5.5 | 3 | Lean R |
| FL-09 | 0.205 | -7.6 | Darren Soto (D) | -5.4 | 2 | Likely R |
| AL-02 | 0.209 | -6.5 | Shomari Figures (D) | -5.3 | 1 | Lean R |
| TX-23 | 0.231 | -6.5 | abierto (R) | -4.9 | 1 | Lean R |
| MN-01 | 0.254 | -5.8 | Brad Finstad (R) | -4.2 | 3 | Lean R |
| CO-05 | 0.264 | -4.8 | Jeff Crank (R) | -4.1 | 1 | Tossup |
| FL-07 | 0.273 | -5.4 | Cory Mills (R) | -4.0 | 1 | Lean R |
| CO-03 | 0.294 | -4.8 | Jeff Hurd (R) | -3.5 | 2 | Likely R |
| SC-01 | 0.299 | -6.1 | abierto (R) | -3.4 | 3 | Lean R |
| OH-15 | 0.313 | -4.7 | Mike Carey (R) | -3.1 | 2 | Lean R |
| TX-15 | 0.314 | -7.1 | Monica De La Cruz (R) | -3.2 | 3 | Lean D |
| MO-02 | 0.321 | -4.0 | Ann Wagner (R) | -3.0 | 3 | Lean R |
| OH-10 | 0.363 | -3.7 | Mike Turner (R) | -2.2 | 1 | Lean R |
| MI-04 | 0.381 | -2.6 | Bill Huizenga (R) | -2.0 | 2 | Tossup |
| WI-01 | 0.405 | -2.0 | Bryan Steil (R) | -1.5 | 3 | Lean R |
| OH-07 | 0.409 | -5.4 | Max Miller (R) | -1.5 | 1 | Tossup |
| KY-06 | 0.410 | -7.1 | abierto (R) | -1.4 | 3 | Tossup |
| VA-01 | 0.421 | -2.8 | Rob Wittman (R) | -1.3 | 3 | Tossup |
| TX-35 | 0.431 | -4.2 | abierto (D) | -1.1 | 3 | Tossup |
| FL-22 | 0.436 | -3.6 | abierto (D) | -1.0 | 2 | Tossup |
| MI-10 | 0.449 | -2.6 | abierto (R) | -0.8 | 1 | Lean D |
| ME-02 | 0.466 | -4.3 | abierto (D) | -0.5 | 3 | Lean R |
| IA-02 | 0.480 | -4.4 | abierto (R) | -0.3 | 1 | Tossup |
| NC-01 | 0.502 | -5.3 | Don Davis (D) | 0.0 | 4 | Lean D |
| FL-14 | 0.535 | -4.3 | Kathy Castor (D) | 0.5 | 2 | Lean D |
| PA-08 | 0.548 | -3.6 | Rob Bresnahan (R) | 0.8 | 3 | Lean D |
| PA-10 | 0.562 | -2.5 | Scott Perry (R) | 0.9 | 3 | Lean D |
| OH-09 | 0.564 | -4.9 | Marcy Kaptur (D) | 1.1 | 2 | Lean D |
| MT-01 | 0.590 | -5.4 | abierto (R) | 1.5 | 4 | Tossup |
| WI-03 | 0.595 | -3.4 | Derrick Van Orden (R) | 1.5 | 0 | Lean D |
| NC-11 | 0.611 | -5.0 | Chuck Edwards (R) | 1.7 | 3 | Lean D |
| PA-01 | 0.621 | 0.7 | Brian Fitzpatrick (R) | 1.9 | 3 | Tossup |
| CO-08 | 0.658 | -0.1 | Gabe Evans (R) | 2.7 | 1 | Lean D |
| FL-25 | 0.664 | -2.8 | Jared Moskowitz (D) | 2.7 | 4 | Lean D |
| NY-17 | 0.672 | 1.5 | Mike Lawler (R) | 2.9 | 3 | Tossup |
| IA-03 | 0.681 | -1.7 | Zach Nunn (R) | 3.0 | 0 | Lean D |
| WA-03 | 0.713 | -1.8 | Marie Gluesenkamp Perez (D) | 3.6 | 1 | Lean D |
| AZ-06 | 0.717 | -0.3 | Juan Ciscomani (R) | 3.6 | 1 | Likely D |
| PA-07 | 0.722 | -1.1 | Ryan Mackenzie (R) | 3.7 | 3 | Lean D |
| MI-07 | 0.730 | -0.4 | Tom Barrett (R) | 4.1 | 1 | Tossup |
| TX-34 | 0.732 | -3.5 | Vicente Gonzalez (D) | 4.0 | 2 | Lean D |
| VA-02 | 0.740 | 0.1 | Jen Kiggans (R) | 4.2 | 1 | Lean D |
| AZ-01 | 0.755 | -1.0 | abierto (R) | 4.4 | 3 | Lean D |
| NJ-07 | 0.790 | 0.0 | Thomas Kean Jr. (R) | 5.3 | 1 | Lean D |
