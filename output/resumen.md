# Resumen del pronostico (cantidades preregistradas Q1-Q6)

Generado: 2026-11-02 17:59 UTC. Version principal: **con_delta**. Simulaciones: 20000.

Promedio generic ballot (dos partidos, LV, efectos de casa): **D+8.4** (sd bootstrap en dos etapas 0.45).

| Cantidad | con delta (principal) | sin delta |
|---|---|---|
| Q1 margen voto popular Camara (2 partidos) | 7.4 [IC80 2.7, 12.2] | 8.4 [3.8, 13.0] |
| Q2 escanos D Camara | 230 [IC80 210, 253] | 233 [214, 257] |
| Q2 P(D >= 218) | 0.780 | 0.849 |
| Q3 escanos D Senado (con King y Sanders) | 51 [IC80 48, 55] | 52 [48, 55] |
| Q3 P(D >= 51) | 0.602 | 0.694 |
| Q3 P(D + independientes nuevos >= 51) | 0.609 | 0.700 |
| Q5 delta (sesgo de encuestas, negativo = exageran a D) | -1.0 [IC80 -4.2, 2.2] | 0 (fijo) |
| Q6 P(D gana Camara y R retiene Senado) | 0.190 | 0.166 |
| P(D Camara y D Senado) | 0.591 | 0.683 |
| P(R Camara y R Senado) | 0.209 | 0.140 |

Q4 (470 probabilidades por carrera): `output/predicciones.csv`.

## Lineas base

| linea base | Camara D | P(D Camara) | Senado D | P(D Senado) | fuente |
|---|---|---|---|---|---|
| modelo principal (con delta) | 230 | 0.78 | 51 | 0.60 | este repositorio |
| modelo sin delta | 233 | 0.85 | 52 | 0.69 | este repositorio |
| (a) swing uniforme sin delta | 227 | 1.00 | 49 | 0.00 | este repositorio |
| (b) solo fundamentales | 236 | 0.89 | 50 | 0.40 | este repositorio |
| (c) Poliwave | - | 0.89 | 54 | 0.78 | poliwave.com/us/fed/projection (consultado 2026-11-02) |
| (c) PollCheck | 230 |  NA | 50 |  NA | PollCheck (Senado: D 50, R 45, 5 sin definir), citado en el plan |
| (c) Silver Bulletin (FLIPR) | 238 | 0.95 | - |  NA | Silver Bulletin: ~95% Camara, +25 escanos netos sobre 213 actuales, citado en el plan |
| (d) Polymarket (mercado de prediccion) | - | 0.94 | - | 0.73 | gamma-api.polymarket.com (which-party-will-win-the-house/senate-in-2026) |

## Sensibilidad a la hipotesis de sesgo (media de delta; 5 000 replicas cada una)

| media de delta | Camara D mediana | P(D Camara) | Senado D mediana | P(D Senado) | P(D Camara y R Senado) |
|---|---|---|---|---|---|
| 0.0 | 233 | 0.836 | 52 | 0.692 | 0.156 |
| -1.0 | 229 | 0.769 | 51 | 0.600 | 0.184 |
| -2.0 | 225 | 0.687 | 51 | 0.507 | 0.195 |
| -2.7 | 222 | 0.624 | 50 | 0.434 | 0.206 |
| -4.0 | 217 | 0.492 | 49 | 0.313 | 0.196 |

## Carreras senatoriales (version principal)

| carrera | P(no R) | lado no R | margen mediana | IC80 | encuestas | calificacion |
|---|---|---|---|---|---|---|
| MA | 1.000 | Ed Markey | 27.3 | [19.8, 34.8] | 3 | Safe D |
| RI | 1.000 | Jack Reed | 28.3 | [20.8, 35.9] | 3 | Safe D |
| OR | 0.998 | Jeff Merkley | 22.8 | [12.6, 32.9] | 0 | Safe D |
| DE | 0.998 | Chris Coons | 22.9 | [12.8, 32.8] | 0 | Safe D |
| NM | 0.997 | Ben Ray Luján | 16.7 | [8.9, 24.5] | 1 | Safe D |
| IL | 0.996 | Juliana Stratton | 16.0 | [8.4, 23.5] | 3 | Safe D |
| CO | 0.996 | John Hickenlooper | 16.2 | [8.4, 24.0] | 1 | Safe D |
| NJ | 0.991 | Cory Booker | 18.4 | [8.4, 28.4] | 0 | Safe D |
| VA | 0.985 | Mark Warner | 17.3 | [7.3, 27.2] | 0 | Safe D |
| GA | 0.971 | Jon Ossoff | 10.1 | [3.2, 17.0] | 5 | Likely D |
| NC | 0.953 | Roy Cooper | 9.2 | [2.1, 16.0] | 12 | Likely D |
| NH | 0.948 | Chris Pappas | 8.9 | [1.9, 15.9] | 7 | Lean D |
| MN | 0.914 | Peggy Flanagan | 7.4 | [0.5, 14.2] | 14 | Lean D |
| MI | 0.819 | Abdul El-Sayed | 4.9 | [-1.9, 11.7] | 21 | Likely D |
| ME | 0.809 | Troy Jackson | 4.7 | [-2.3, 11.6] | 18 | Lean D |
| TX | 0.612 | James Talarico | 1.5 | [-5.3, 8.3] | 34 | Tossup |
| OH-S | 0.542 | Sherrod Brown | 0.6 | [-6.2, 7.5] | 22 | Tossup |
| AK | 0.462 | Mary Peltola | -0.5 | [-7.4, 6.3] | 6 | Tossup |
| KS | 0.434 | Adam Hamilton | -0.9 | [-7.8, 6.0] | 12 | Tossup |
| IA | 0.384 | Josh Turek | -1.6 | [-8.6, 5.3] | 17 | Tossup |
| SC | 0.179 | Annie Andrews | -4.9 | [-11.8, 1.9] | 10 | Lean R |
| NE | 0.159 | Dan Osborn | -5.4 | [-12.5, 1.5] | 11 | Lean R |
| FL-S | 0.060 | Angie Nixon | -8.2 | [-15.0, -1.4] | 20 | Likely R |
| LA | 0.046 | Jamie Davis | -9.4 | [-16.7, -2.2] | 2 | Likely R |
| MS | 0.030 | Scott Colom | -10.6 | [-17.7, -3.4] | 1 | Likely R |
| MT | 0.029 | Seth Bodnar | -10.4 | [-17.5, -3.2] | 4 | Likely R |
| SD | 0.010 | Brian Bengs | -13.7 | [-21.2, -6.1] | 6 | Solid R |
| AR | 0.004 | Hallie Shoffner | -16.1 | [-23.9, -8.5] | 2 | Safe R |
| KY | 0.003 | Charles Booker | -16.5 | [-24.4, -8.8] | 1 | Solid R |
| AL | 0.000 | Everett Wess | -19.3 | [-26.7, -11.9] | 3 | Safe R |
| OK | 0.000 | N'Kiyla Jasmine Thomas | -25.4 | [-35.3, -15.4] | 0 | Safe R |
| TN | 0.000 | Marquita Bradshaw | -24.4 | [-32.2, -16.7] | 1 | Safe R |
| ID | 0.000 | - | -100.0 | [-100.0, -100.0] | 0 | Safe R |
| WV | 0.000 | Rachel Fetty Anderson | -29.8 | [-39.8, -19.7] | 0 | Safe R |
| WY | 0.000 | James W. Byrd | -29.8 | [-39.9, -19.9] | 0 | Safe R |

## Distritos mas competitivos (P(D) entre 0.2 y 0.8, version principal)

| distrito | P(D) | PVI | incumbente | margen mediana | encuestas | calificacion |
|---|---|---|---|---|---|---|
| AL-02 | 0.212 | -6.5 | Shomari Figures (D) | -5.2 | 0 | Lean R |
| TX-23 | 0.217 | -6.5 | abierto (R) | -4.9 | 1 | Lean R |
| MO-02 | 0.229 | -5.8 | Ann Wagner (R) | -4.5 | 3 | Lean R |
| MN-01 | 0.239 | -5.8 | Brad Finstad (R) | -4.3 | 3 | Lean R |
| FL-07 | 0.244 | -5.4 | Cory Mills (R) | -4.2 | 1 | Lean R |
| CO-05 | 0.249 | -4.8 | Jeff Crank (R) | -4.2 | 1 | Tossup |
| CO-03 | 0.258 | -4.8 | Jeff Hurd (R) | -4.1 | 2 | Likely R |
| OH-15 | 0.280 | -4.7 | Mike Carey (R) | -3.6 | 2 | Lean R |
| SC-01 | 0.286 | -6.1 | abierto (R) | -3.5 | 3 | Lean R |
| OH-10 | 0.314 | -3.7 | Mike Turner (R) | -3.0 | 1 | Lean R |
| WI-01 | 0.353 | -2.0 | Bryan Steil (R) | -2.2 | 3 | Lean R |
| TX-15 | 0.358 | -7.1 | Monica De La Cruz (R) | -2.2 | 3 | Lean D |
| MI-04 | 0.365 | -2.6 | Bill Huizenga (R) | -2.0 | 2 | Tossup |
| MT-01 | 0.380 | -5.4 | abierto (R) | -1.9 | 3 | Tossup |
| VA-01 | 0.408 | -2.8 | Rob Wittman (R) | -1.4 | 3 | Tossup |
| KY-06 | 0.417 | -7.1 | abierto (R) | -1.3 | 3 | Tossup |
| FL-22 | 0.425 | -3.6 | abierto (D) | -1.2 | 1 | Tossup |
| ME-02 | 0.428 | -4.3 | abierto (D) | -1.0 | 3 | Lean R |
| OH-07 | 0.428 | -5.4 | Max Miller (R) | -1.1 | 1 | Tossup |
| TX-35 | 0.429 | -4.2 | abierto (D) | -1.1 | 3 | Tossup |
| MO-05 | 0.452 | -8.8 | Emanuel Cleaver (D) | -0.9 | 0 | Safe D |
| MI-10 | 0.467 | -2.6 | abierto (R) | -0.5 | 1 | Lean D |
| IA-02 | 0.490 | -4.4 | abierto (R) | -0.1 | 1 | Tossup |
| NC-01 | 0.527 | -5.3 | Don Davis (D) | 0.4 | 4 | Lean D |
| FL-14 | 0.553 | -4.3 | Kathy Castor (D) | 0.8 | 2 | Lean D |
| PA-08 | 0.574 | -3.6 | Rob Bresnahan (R) | 1.1 | 3 | Lean D |
| PA-01 | 0.587 | 0.7 | Brian Fitzpatrick (R) | 1.3 | 3 | Tossup |
| WI-03 | 0.588 | -3.4 | Derrick Van Orden (R) | 1.4 | 0 | Lean D |
| OH-09 | 0.592 | -4.9 | Marcy Kaptur (D) | 1.4 | 2 | Lean D |
| PA-10 | 0.602 | -2.5 | Scott Perry (R) | 1.5 | 3 | Lean D |
| NC-11 | 0.637 | -5.0 | Chuck Edwards (R) | 2.2 | 3 | Lean D |
| NY-17 | 0.641 | 1.5 | Mike Lawler (R) | 2.2 | 3 | Tossup |
| CO-08 | 0.652 | -0.1 | Gabe Evans (R) | 2.5 | 1 | Lean D |
| IA-03 | 0.677 | -1.7 | Zach Nunn (R) | 3.0 | 0 | Lean D |
| FL-25 | 0.687 | -2.8 | Jared Moskowitz (D) | 2.9 | 4 | Lean D |
| WA-03 | 0.716 | -1.8 | Marie Gluesenkamp Perez (D) | 3.6 | 1 | Lean D |
| MI-07 | 0.726 | -0.4 | Tom Barrett (R) | 3.7 | 1 | Tossup |
| AZ-06 | 0.739 | -0.3 | Juan Ciscomani (R) | 3.9 | 1 | Likely D |
| PA-07 | 0.741 | -1.1 | Ryan Mackenzie (R) | 3.8 | 3 | Lean D |
| VA-02 | 0.741 | 0.1 | Jen Kiggans (R) | 4.0 | 1 | Lean D |
| TX-34 | 0.756 | -3.5 | Vicente Gonzalez (D) | 4.3 | 2 | Lean D |
| AZ-01 | 0.766 | -1.0 | abierto (R) | 4.4 | 3 | Lean D |
