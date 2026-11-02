# tests/test_utils.R -- pruebas de las funciones puras (base R, sin testthat).  Uso: Rscript tests/test_utils.R
source("R/00_setup.R")
if (!exists("rating_to_margin")) source("R/utils.R")

n_ok <- 0L
check <- function(desc, cond) {
  if (!isTRUE(all(cond))) stop("FALLO: ", desc)
  n_ok <<- n_ok + 1L
}
same <- function(a, b) isTRUE(all.equal(a, b))

# PVI
check("pvi_to_num", same(pvi_to_num(c("R+17", "D+5", "EVEN", "D+0.5", "basura")), c(-17, 5, 0, 0.5, NA)))

# calificaciones
check("rating_to_margin niveles",
      same(rating_to_margin(c("Lean D (flip)", "Tossup", "Toss-up", "Safe R", "Likely R", "Tilt I", "Solid D", "Likely D (flip)", "foo")),
           c(5, 0, 0, -18, -9, 2.5, 18, 9, NA)))

# fechas de Wikipedia
d <- parse_wiki_dates(c("October 22–30, 2026", "October 29 – November 1, 2026", "October 26, 2026", "September 30 – October 2, 2026"))
check("parse_wiki_dates start", same(d$start, as.Date(c("2026-10-22", "2026-10-29", "2026-10-26", "2026-09-30"))))
check("parse_wiki_dates end",   same(d$end,   as.Date(c("2026-10-30", "2026-11-01", "2026-10-26", "2026-10-02"))))
d2 <- parse_wiki_dates("December 28, 2025 – January 4, 2026")
check("parse_wiki_dates cruza el ano", same(d2$start, as.Date("2025-12-28")) && same(d2$end, as.Date("2026-01-04")))

# partidos
check("norm_party", same(norm_party(c("DFL", "Democratic–Farmer–Labor", "Democratic-NPL", "Republican", "Independent", "Libertarian")),
                         c("Democratic", "Democratic", "Democratic", "Republican", "Independent", "Libertarian")))
cands <- "▌Brad Finstad (Republican)[12]\n▌Jake Johnson (DFL)"
check("parties_in", same(parties_in(cands), c("Republican", "Democratic")))
check("cand_by_party D", same(cand_by_party(cands, "Democratic"), "Jake Johnson"))
check("cand_by_party R", same(cand_by_party(cands, "Republican"), "Brad Finstad"))
check("cand_by_party ausente", is.na(cand_by_party(cands, "Independent")))

# Poliwave
check("color_to_party", same(color_to_party(c("--party-color: #DC2626;", "--party-color: #3B82F6;", "--party-color: #9d2dc8;",
                                              "--party-color: #94A3B8;", "--party-color: #2dc872;", NA)),
                             c("R", "D", "I", "UND", "OTH", NA)))
check("option_key", same(option_key(c("James Talarico", "Thomas Kean Jr.", "María Elvira Salazar")),
                         c("JAMES_TALARICO", "THOMAS_KEAN_JR_", "MARIA_ELVIRA_SALAZAR")))
check("key_tokens", same(key_tokens("TOM_KEAN_JR"), c("TOM", "KEAN")))
hdr <- tibble(key = option_key(c("Matthew Dunlap", "Thomas Kean Jr.", "Maria Elvira Salazar", "Dan Sullivan", "Dan Smith")),
              party = c("D", "R", "R", "R", "D"))
check("match_key_to_header", same(match_key_to_header(c("MATT_DUNLAP", "TOM_KEAN_JR", "MAR_A_ELVIRA_SALAZAR", "DAN_SULLIVAN", "NADIE_X"), hdr),
                                  c("D", "R", "R", "R", NA)))

# modelo
check("two_party_margin", same(two_party_margin(50, 40), 100 * 10 / 90))
c1 <- combine3(m_f = 4, v_f = 9, m_p = NA, v_p = NA, m_r = NA, v_r = NA)
check("combine3 solo fundamentales", same(c1$m_hat, 4) && same(c1$sd, 3) && same(c1$w_poll, 0) && same(c1$w_rating, 0))
c2 <- combine3(m_f = 0, v_f = 16, m_p = 8, v_p = 16, m_r = NA, v_r = 36)
check("combine3 dos fuentes iguales", same(c2$m_hat, 4) && same(c2$sd, sqrt(8)) && same(c2$w_poll, 0.5))
c3 <- combine3(m_f = 0, v_f = 4, m_p = 10, v_p = 4, m_r = 20, v_r = 4)
check("combine3 tres fuentes", same(c3$m_hat, 10) && same(c3$w_poll + c3$w_rating, 2 / 3))
check("combine3 vectorizado", nrow(combine3(c(0, 1), c(4, 4), c(NA, 2), c(4, 4), c(NA, NA), c(9, 9))) == 2)

cat(sprintf("OK: %d pruebas superadas\n", n_ok))
