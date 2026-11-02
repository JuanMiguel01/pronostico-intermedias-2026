# Resumen del pronostico (cantidades preregistradas Q1-Q6)

Generado: 2026-11-02 18:16 UTC. Version principal: **con_delta**. Simulaciones: 20000.

Promedio generic ballot (dos partidos, LV, efectos de casa): **D+8.4** (sd bootstrap en dos etapas 0.46).

| Cantidad | con delta (principal) | sin delta |
|---|---|---|
| Q1 margen voto popular Camara (2 partidos) | 7.4 [IC80 2.7, 12.2] | 8.4 [3.8, 13.0] |
| Q2 escanos D Camara | 230 [IC80 211, 253] | 234 [215, 257] |
| Q2 P(D >= 218) | 0.797 | 0.865 |
| Q3 escanos D Senado (con King y Sanders) | 51 [IC80 47, 55] | 52 [48, 55] |
| Q3 P(D >= 51) | 0.600 | 0.691 |
| Q3 P(D + independientes nuevos >= 51) | 0.607 | 0.697 |
| Q5 delta (sesgo de encuestas, negativo = exageran a D) | -1.0 [IC80 -4.2, 2.2] | 0 (fijo) |
| Q6 P(D gana Camara y R retiene Senado) | 0.205 | 0.181 |
| P(D Camara y D Senado) | 0.592 | 0.683 |
| P(R Camara y R Senado) | 0.195 | 0.127 |

Q4 (470 probabilidades por carrera): `output/predicciones.csv`.

## Lineas base

| linea base | Camara D | P(D Camara) | Senado D | P(D Senado) | fuente |
|---|---|---|---|---|---|
| modelo principal (con delta) | 230 | 0.80 | 51 | 0.60 | este repositorio |
| modelo sin delta | 234 | 0.86 | 52 | 0.69 | este repositorio |
| (a) swing uniforme sin delta | 228 | 1.00 | 49 | 0.00 | este repositorio |
| (b) solo fundamentales | 237 | 0.90 | 50 | 0.40 | este repositorio |
| (c) Poliwave | - | 0.89 | 54 | 0.78 | poliwave.com/us/fed/projection (consultado 2026-11-02) |
| (c) PollCheck | 230 | - | 50 | - | PollCheck (Senado: D 50, R 45, 5 sin definir), citado en el plan |
| (c) Silver Bulletin (FLIPR) | 238 | 0.95 | - | - | Silver Bulletin: ~95% Camara, +25 escanos netos sobre 213 actuales, citado en el plan |
| (d) Polymarket (mercado de prediccion) | - | 0.94 | - | 0.73 | gamma-api.polymarket.com (which-party-will-win-the-house/senate-in-2026) |

## Sensibilidad a la hipotesis de sesgo (media de delta; 5 000 replicas cada una)

| media de delta | Camara D mediana | P(D Camara) | Senado D mediana | P(D Senado) | P(D Camara y R Senado) |
|---|---|---|---|---|---|
| 0.0 | 234 | 0.851 | 52 | 0.689 | 0.171 |
| -1.0 | 230 | 0.785 | 51 | 0.597 | 0.198 |
| -2.0 | 226 | 0.710 | 51 | 0.505 | 0.217 |
| -2.7 | 223 | 0.646 | 50 | 0.432 | 0.226 |
| -4.0 | 218 | 0.514 | 49 | 0.312 | 0.215 |

## Carreras senatoriales (version principal)

| carrera | P(no R) | lado no R | margen mediana | IC80 | encuestas | calificacion |
|---|---|---|---|---|---|---|
| MA | 1.000 | Ed Markey | 27.3 | [19.7, 34.9] | 3 | Safe D |
| RI | 1.000 | Jack Reed | 28.2 | [20.5, 35.9] | 3 | Safe D |
| OR | 0.998 | Jeff Merkley | 22.8 | [12.6, 32.9] | 0 | Safe D |
| DE | 0.998 | Chris Coons | 22.9 | [12.8, 32.8] | 0 | Safe D |
| IL | 0.996 | Juliana Stratton | 16.1 | [8.4, 23.7] | 3 | Safe D |
| CO | 0.995 | John Hickenlooper | 16.6 | [8.6, 24.6] | 1 | Safe D |
| NM | 0.995 | Ben Ray Luján | 17.0 | [8.6, 25.4] | 1 | Safe D |
| NJ | 0.991 | Cory Booker | 18.4 | [8.4, 28.4] | 0 | Safe D |
| VA | 0.985 | Mark Warner | 17.3 | [7.3, 27.2] | 0 | Safe D |
| GA | 0.970 | Jon Ossoff | 10.1 | [3.2, 17.0] | 5 | Likely D |
| NC | 0.952 | Roy Cooper | 9.2 | [2.1, 16.0] | 12 | Likely D |
| NH | 0.947 | Chris Pappas | 8.9 | [1.8, 15.9] | 7 | Lean D |
| MN | 0.914 | Peggy Flanagan | 7.4 | [0.4, 14.2] | 14 | Lean D |
| MI | 0.819 | Abdul El-Sayed | 4.8 | [-2.0, 11.8] | 21 | Likely D |
| ME | 0.809 | Troy Jackson | 4.7 | [-2.3, 11.6] | 18 | Lean D |
| TX | 0.612 | James Talarico | 1.5 | [-5.3, 8.3] | 34 | Tossup |
| OH-S | 0.541 | Sherrod Brown | 0.6 | [-6.2, 7.5] | 22 | Tossup |
| AK | 0.457 | Mary Peltola | -0.6 | [-7.6, 6.3] | 6 | Tossup |
| KS | 0.431 | Adam Hamilton | -1.0 | [-7.9, 6.0] | 12 | Tossup |
| IA | 0.382 | Josh Turek | -1.6 | [-8.7, 5.3] | 17 | Tossup |
| SC | 0.177 | Annie Andrews | -4.9 | [-11.8, 1.9] | 10 | Lean R |
| NE | 0.157 | Dan Osborn | -5.5 | [-12.6, 1.5] | 11 | Lean R |
| FL-S | 0.060 | Angie Nixon | -8.2 | [-15.0, -1.4] | 20 | Likely R |
| LA | 0.044 | Jamie Davis | -9.6 | [-16.9, -2.4] | 2 | Likely R |
| MS | 0.029 | Scott Colom | -10.7 | [-17.9, -3.5] | 1 | Likely R |
| MT | 0.024 | Seth Bodnar | -10.8 | [-17.9, -3.7] | 5 | Likely R |
| SD | 0.010 | Brian Bengs | -13.8 | [-21.4, -6.2] | 6 | Solid R |
| AR | 0.004 | Hallie Shoffner | -16.5 | [-24.4, -8.7] | 2 | Safe R |
| KY | 0.003 | Charles Booker | -17.5 | [-26.0, -9.2] | 1 | Solid R |
| AL | 0.000 | Everett Wess | -19.4 | [-26.8, -11.9] | 3 | Safe R |
| OK | 0.000 | N'Kiyla Jasmine Thomas | -25.4 | [-35.3, -15.4] | 0 | Safe R |
| TN | 0.000 | Marquita Bradshaw | -23.8 | [-32.2, -15.5] | 1 | Safe R |
| ID | 0.000 | - | -100.0 | [-100.0, -100.0] | 0 | Safe R |
| WV | 0.000 | Rachel Fetty Anderson | -29.8 | [-39.8, -19.7] | 0 | Safe R |
| WY | 0.000 | James W. Byrd | -29.8 | [-39.9, -19.9] | 0 | Safe R |

## Distritos mas competitivos (P(D) entre 0.2 y 0.8, version principal)

| distrito | P(D) | PVI | incumbente | margen mediana | encuestas | calificacion |
|---|---|---|---|---|---|---|
| AL-02 | 0.212 | -6.5 | Shomari Figures (D) | -5.2 | 1 | Lean R |
| TX-23 | 0.214 | -6.5 | abierto (R) | -5.0 | 1 | Lean R |
| MN-01 | 0.230 | -5.8 | Brad Finstad (R) | -4.5 | 3 | Lean R |
| FL-07 | 0.237 | -5.4 | Cory Mills (R) | -4.4 | 1 | Lean R |
| CO-05 | 0.248 | -4.8 | Jeff Crank (R) | -4.3 | 1 | Tossup |
| CO-03 | 0.249 | -4.8 | Jeff Hurd (R) | -4.2 | 2 | Likely R |
| MO-02 | 0.251 | -4.0 | Ann Wagner (R) | -4.0 | 3 | Lean R |
| OH-15 | 0.271 | -4.7 | Mike Carey (R) | -3.8 | 2 | Lean R |
| SC-01 | 0.283 | -6.1 | abierto (R) | -3.6 | 3 | Lean R |
| OH-10 | 0.304 | -3.7 | Mike Turner (R) | -3.2 | 1 | Lean R |
| WI-01 | 0.350 | -2.0 | Bryan Steil (R) | -2.3 | 3 | Lean R |
| TX-15 | 0.356 | -7.1 | Monica De La Cruz (R) | -2.2 | 3 | Lean D |
| MI-04 | 0.373 | -2.6 | Bill Huizenga (R) | -1.9 | 2 | Tossup |
| KY-06 | 0.398 | -7.1 | abierto (R) | -1.6 | 3 | Tossup |
| VA-01 | 0.407 | -2.8 | Rob Wittman (R) | -1.5 | 3 | Tossup |
| ME-02 | 0.418 | -4.3 | abierto (D) | -1.2 | 3 | Lean R |
| OH-07 | 0.419 | -5.4 | Max Miller (R) | -1.2 | 1 | Tossup |
| TX-35 | 0.430 | -4.2 | abierto (D) | -1.1 | 3 | Tossup |
| FL-22 | 0.432 | -3.6 | abierto (D) | -1.1 | 2 | Tossup |
| MI-10 | 0.486 | -2.6 | abierto (R) | -0.2 | 1 | Lean D |
| IA-02 | 0.487 | -4.4 | abierto (R) | -0.2 | 1 | Tossup |
| NC-01 | 0.526 | -5.3 | Don Davis (D) | 0.4 | 4 | Lean D |
| FL-14 | 0.553 | -4.3 | Kathy Castor (D) | 0.8 | 2 | Lean D |
| MT-01 | 0.565 | -5.4 | abierto (R) | 1.0 | 4 | Tossup |
| PA-08 | 0.570 | -3.6 | Rob Bresnahan (R) | 1.1 | 3 | Lean D |
| OH-09 | 0.587 | -4.9 | Marcy Kaptur (D) | 1.4 | 2 | Lean D |
| WI-03 | 0.588 | -3.4 | Derrick Van Orden (R) | 1.4 | 0 | Lean D |
| PA-01 | 0.593 | 0.7 | Brian Fitzpatrick (R) | 1.4 | 3 | Tossup |
| PA-10 | 0.606 | -2.5 | Scott Perry (R) | 1.6 | 3 | Lean D |
| NC-11 | 0.624 | -5.0 | Chuck Edwards (R) | 2.0 | 3 | Lean D |
| NY-17 | 0.650 | 1.5 | Mike Lawler (R) | 2.3 | 3 | Tossup |
| CO-08 | 0.668 | -0.1 | Gabe Evans (R) | 2.8 | 1 | Lean D |
| IA-03 | 0.677 | -1.7 | Zach Nunn (R) | 3.0 | 0 | Lean D |
| FL-25 | 0.688 | -2.8 | Jared Moskowitz (D) | 2.9 | 4 | Lean D |
| MI-07 | 0.718 | -0.4 | Tom Barrett (R) | 3.6 | 1 | Tossup |
| WA-03 | 0.727 | -1.8 | Marie Gluesenkamp Perez (D) | 3.8 | 1 | Lean D |
| PA-07 | 0.738 | -1.1 | Ryan Mackenzie (R) | 3.8 | 3 | Lean D |
| AZ-06 | 0.744 | -0.3 | Juan Ciscomani (R) | 4.0 | 1 | Likely D |
| VA-02 | 0.745 | 0.1 | Jen Kiggans (R) | 4.1 | 1 | Lean D |
| TX-34 | 0.748 | -3.5 | Vicente Gonzalez (D) | 4.1 | 2 | Lean D |
| AZ-01 | 0.767 | -1.0 | abierto (R) | 4.5 | 3 | Lean D |
| NJ-07 | 0.796 | 0.0 | Thomas Kean Jr. (R) | 5.2 | 1 | Lean D |
