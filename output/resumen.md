# Resumen del pronostico (cantidades preregistradas Q1-Q6)

Generado: 2026-11-02 17:37 UTC. Version principal: **con_delta**. Simulaciones: 20000.

Promedio generic ballot (dos partidos, LV, efectos de casa): **D+8.4** (sd bootstrap en dos etapas 0.48).

| Cantidad | con delta (principal) | sin delta |
|---|---|---|
| Q1 margen voto popular Camara (2 partidos) | 7.4 [IC80 2.6, 12.2] | 8.4 [3.8, 13.0] |
| Q2 escanos D Camara | 233 [IC80 212, 259] | 237 [216, 264] |
| Q2 P(D >= 218) | 0.818 | 0.879 |
| Q3 escanos D Senado (con King y Sanders) | 51 [IC80 48, 55] | 52 [48, 55] |
| Q3 P(D >= 51) | 0.598 | 0.691 |
| Q3 P(D + independientes nuevos >= 51) | 0.618 | 0.709 |
| Q5 delta (sesgo de encuestas, negativo = exageran a D) | -1.0 [IC80 -4.2, 2.2] | 0 (fijo) |
| Q6 P(D gana Camara y R retiene Senado) | 0.229 | 0.196 |
| P(D Camara y D Senado) | 0.589 | 0.684 |
| P(R Camara y R Senado) | 0.174 | 0.113 |

Q4 (470 probabilidades por carrera): `output/predicciones.csv`.

## Lineas base

| linea base | Camara D | P(D Camara) | Senado D | P(D Senado) | fuente |
|---|---|---|---|---|---|
| modelo principal (con delta) | 233 | 0.82 | 51 | 0.60 | este repositorio |
| modelo sin delta | 237 | 0.88 | 52 | 0.69 | este repositorio |
| (a) swing uniforme sin delta | 229 | 1.00 | 49 | 0.00 | este repositorio |
| (b) solo fundamentales | 235 | 0.89 | 50 | 0.40 | este repositorio |
| (c) Poliwave | - | 0.89 | 54 | 0.78 | poliwave.com/us/fed/projection (consultado 2026-11-02) |
| (c) PollCheck | 230 |  NA | 50 |  NA | PollCheck (Senado: D 50, R 45, 5 sin definir), citado en el plan |
| (c) Silver Bulletin (FLIPR) | 238 | 0.95 | - |  NA | Silver Bulletin: ~95% Camara, +25 escanos netos sobre 213 actuales, citado en el plan |

## Carreras senatoriales (version principal)

| carrera | P(no R) | lado no R | margen mediana | IC80 | encuestas |
|---|---|---|---|---|---|
| MA | 1.000 | Ed Markey | 29.6 | [21.7, 37.3] | 3 |
| RI | 1.000 | Jack Reed | 30.8 | [23.1, 38.7] | 3 |
| OR | 0.997 | Jeff Merkley | 27.5 | [14.9, 40.1] | 0 |
| DE | 0.997 | Chris Coons | 27.6 | [15.0, 39.9] | 0 |
| NM | 0.996 | Ben Ray Luján | 16.7 | [8.6, 24.9] | 1 |
| IL | 0.994 | Juliana Stratton | 15.1 | [7.4, 22.8] | 3 |
| CO | 0.994 | John Hickenlooper | 16.0 | [7.9, 24.1] | 1 |
| NJ | 0.978 | Cory Booker | 19.5 | [7.0, 32.0] | 0 |
| VA | 0.962 | Mark Warner | 17.5 | [4.8, 29.9] | 0 |
| GA | 0.958 | Jon Ossoff | 9.9 | [2.5, 17.4] | 5 |
| NH | 0.950 | Chris Pappas | 9.8 | [2.1, 17.4] | 7 |
| NC | 0.943 | Roy Cooper | 9.3 | [1.7, 16.6] | 12 |
| MN | 0.914 | Peggy Flanagan | 7.8 | [0.5, 15.1] | 14 |
| ME | 0.842 | Troy Jackson | 5.7 | [-1.6, 13.1] | 18 |
| MI | 0.834 | Abdul El-Sayed | 5.5 | [-1.8, 12.8] | 21 |
| TX | 0.580 | James Talarico | 1.1 | [-6.1, 8.3] | 34 |
| OH-S | 0.506 | Sherrod Brown | 0.1 | [-7.1, 7.4] | 22 |
| KS | 0.424 | Adam Hamilton | -1.1 | [-8.4, 6.3] | 12 |
| AK | 0.414 | Mary Peltola | -1.2 | [-8.7, 6.1] | 6 |
| IA | 0.413 | Josh Turek | -1.3 | [-8.7, 6.2] | 17 |
| NE | 0.226 | Dan Osborn | -4.5 | [-12.3, 3.1] | 11 |
| SC | 0.199 | Annie Andrews | -4.8 | [-12.1, 2.5] | 10 |
| LA | 0.143 | Jamie Davis | -6.6 | [-14.8, 1.3] | 2 |
| MT | 0.117 | Seth Bodnar | -7.3 | [-15.2, 0.6] | 4 |
| FL-S | 0.105 | Angie Nixon | -7.1 | [-14.4, 0.2] | 20 |
| MS | 0.050 | Scott Colom | -10.4 | [-18.4, -2.4] | 1 |
| SD | 0.024 | Brian Bengs | -12.2 | [-19.9, -4.4] | 6 |
| AR | 0.006 | Hallie Shoffner | -15.5 | [-23.5, -7.5] | 2 |
| KY | 0.005 | Charles Booker | -16.1 | [-24.4, -8.0] | 1 |
| OK | 0.001 | N'Kiyla Jasmine Thomas | -30.5 | [-43.0, -18.2] | 0 |
| AL | 0.001 | Everett Wess | -19.2 | [-26.8, -11.6] | 3 |
| WV | 0.000 | Rachel Fetty Anderson | -38.5 | [-51.0, -25.9] | 0 |
| ID | 0.000 | - | -100.0 | [-100.0, -100.0] | 0 |
| TN | 0.000 | Marquita Bradshaw | -25.7 | [-33.9, -17.7] | 1 |
| WY | 0.000 | James W. Byrd | -38.6 | [-51.1, -26.3] | 0 |

## Distritos mas competitivos (P(D) entre 0.2 y 0.8, version principal)

| distrito | P(D) | PVI | incumbente | margen mediana | encuestas |
|---|---|---|---|---|---|
| NV-02 | 0.203 | -6.8 | abierto (R) | -5.6 | 3 |
| FL-11 | 0.204 | -7.2 | abierto (R) | -6.8 | 0 |
| NY-02 | 0.224 | -5.6 | Andrew Garbarino (R) | -6.2 | 0 |
| WA-05 | 0.228 | -5.4 | Michael Baumgartner (R) | -6.0 | 0 |
| TX-15 | 0.231 | -7.1 | Monica De La Cruz (R) | -5.0 | 3 |
| NJ-02 | 0.231 | -5.4 | Jeff Van Drew (R) | -6.0 | 1 |
| FL-04 | 0.242 | -5.3 | Aaron Bean (R) | -5.8 | 0 |
| FL-09 | 0.254 | -7.6 | Darren Soto (D) | -4.5 | 2 |
| AZ-02 | 0.261 | -6.7 | Eli Crane (R) | -4.3 | 3 |
| TX-23 | 0.265 | -6.5 | abierto (R) | -4.3 | 1 |
| CO-05 | 0.283 | -4.8 | Jeff Crank (R) | -4.0 | 1 |
| MN-01 | 0.299 | -5.8 | Brad Finstad (R) | -3.4 | 3 |
| FL-07 | 0.309 | -5.4 | Cory Mills (R) | -3.4 | 1 |
| SC-01 | 0.321 | -6.1 | abierto (R) | -3.1 | 3 |
| NY-01 | 0.351 | -4.0 | Nick LaLota (R) | -3.2 | 0 |
| MO-02 | 0.359 | -5.8 | Ann Wagner (R) | -2.4 | 3 |
| AL-02 | 0.360 | -6.5 | Shomari Figures (D) | -3.0 | 0 |
| MT-01 | 0.366 | -5.4 | abierto (R) | -2.3 | 3 |
| OH-07 | 0.366 | -5.4 | Max Miller (R) | -2.2 | 1 |
| OH-15 | 0.369 | -4.7 | Mike Carey (R) | -2.3 | 2 |
| CO-03 | 0.371 | -4.8 | Jeff Hurd (R) | -2.2 | 2 |
| MI-04 | 0.372 | -2.6 | Bill Huizenga (R) | -2.2 | 2 |
| MI-10 | 0.387 | -2.6 | abierto (R) | -2.0 | 1 |
| WI-03 | 0.407 | -3.4 | Derrick Van Orden (R) | -2.0 | 0 |
| FL-22 | 0.425 | -3.6 | abierto (D) | -1.3 | 1 |
| TX-35 | 0.438 | -4.2 | abierto (D) | -1.1 | 3 |
| OH-10 | 0.438 | -3.7 | Mike Turner (R) | -1.1 | 1 |
| KY-06 | 0.449 | -7.1 | abierto (R) | -0.8 | 3 |
| VA-01 | 0.451 | -2.8 | Rob Wittman (R) | -0.9 | 3 |
| WI-01 | 0.484 | -2.0 | Bryan Steil (R) | -0.3 | 3 |
| NC-01 | 0.497 | -5.3 | Don Davis (D) | -0.0 | 4 |
| PA-10 | 0.501 | -2.5 | Scott Perry (R) | 0.0 | 3 |
| IA-02 | 0.505 | -4.4 | abierto (R) | 0.1 | 1 |
| ME-02 | 0.523 | -4.3 | abierto (D) | 0.4 | 3 |
| PA-08 | 0.526 | -3.6 | Rob Bresnahan (R) | 0.4 | 3 |
| FL-14 | 0.559 | -4.3 | Kathy Castor (D) | 0.9 | 2 |
| IA-03 | 0.570 | -1.7 | Zach Nunn (R) | 1.4 | 0 |
| NC-11 | 0.584 | -5.0 | Chuck Edwards (R) | 1.4 | 3 |
| OH-09 | 0.593 | -4.9 | Marcy Kaptur (D) | 1.6 | 2 |
| CO-08 | 0.609 | -0.1 | Gabe Evans (R) | 2.0 | 1 |
| WA-03 | 0.641 | -1.8 | Marie Gluesenkamp Perez (D) | 2.5 | 1 |
| PA-01 | 0.642 | 0.7 | Brian Fitzpatrick (R) | 2.4 | 3 |
| AZ-06 | 0.665 | -0.3 | Juan Ciscomani (R) | 2.9 | 1 |
| FL-25 | 0.688 | -2.8 | Jared Moskowitz (D) | 3.1 | 4 |
| NY-17 | 0.694 | 1.5 | Mike Lawler (R) | 3.4 | 3 |
| PA-07 | 0.707 | -1.1 | Ryan Mackenzie (R) | 3.5 | 3 |
| VA-02 | 0.710 | 0.1 | Jen Kiggans (R) | 3.8 | 1 |
| AZ-01 | 0.735 | -1.0 | abierto (R) | 4.2 | 3 |
| TX-34 | 0.755 | -3.5 | Vicente Gonzalez (D) | 4.6 | 2 |
| NJ-07 | 0.782 | 0.0 | Thomas Kean Jr. (R) | 5.2 | 1 |
| MI-07 | 0.783 | -0.4 | Tom Barrett (R) | 5.3 | 1 |
