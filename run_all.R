# run_all.R -- corre toda la cadena. Uso: Rscript run_all.R [--sin-descarga]
#   01 descarga (idempotente: no vuelve a bajar lo que ya existe en data/raw/<hoy>/)
#   02 limpieza -> data/frozen/
#   03 calibracion historica -> data/frozen/calibration.csv
#   04 simulacion -> output/sims.rds
#   05 entregables -> output/predicciones.csv, resumen.md, SHA256SUMS.txt
args <- commandArgs(trailingOnly = TRUE)
t0 <- Sys.time()
steps <- c(if (!"--sin-descarga" %in% args) "R/01_download.R", "R/02_clean.R", "R/03_calibrate.R", "R/04_model.R", "R/05_outputs.R")
for (s in steps) {
  cat("\n==================== ", s, " ====================\n")
  source(s, echo = FALSE)
}
cat(sprintf("\nListo en %.1f minutos.\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
