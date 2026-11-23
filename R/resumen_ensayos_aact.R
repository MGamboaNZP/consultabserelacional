#' Resumen de ensayos clinicos por fase en AACT (ClinicalTrials.gov)
#'
#' Conecta de forma remota al servidor PostgreSQL de AACT usando las
#' credenciales almacenadas en .Renviron, filtra los ensayos por patologia
#' y devuelve el numero de estudios y el reclutamiento medio por fase.
#'
#' @param patologia Texto de busqueda de la enfermedad (ej. "Melanoma").
#'
#' @return Un data.frame con el numero de ensayos y tamano muestral medio.
#' @export
#'
#' @examples
#' \dontrun{
#' resumen_ensayos_aact("Melanoma")
#' }
resumen_ensayos_aact <- function(patologia = "Melanoma") {
  usuario <- Sys.getenv("AACT_USER")
  clave   <- Sys.getenv("AACT_PASSWORD")

  if (usuario == "" || clave == "") {
    stop("Configura AACT_USER y AACT_PASSWORD en tu archivo .Renviron.")
  }

  con <- DBI::dbConnect(
    RPostgres::Postgres(),
    dbname   = "aact",
    host     = "aact-db.ctti-clinicaltrials.org",
    port     = 5432,
    user     = usuario,
    password = clave
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  consulta_sql <- "
    SELECT
      COALESCE(s.phase, 'No especificada') AS fase_clinica,
      COUNT(DISTINCT s.nct_id) AS num_ensayos,
      ROUND(AVG(s.enrollment), 1) AS reclutamiento_medio
    FROM ctgov.studies s
    INNER JOIN ctgov.conditions c ON s.nct_id = c.nct_id
    WHERE LOWER(c.name) LIKE LOWER($1)
      AND s.enrollment IS NOT NULL
    GROUP BY s.phase
    ORDER BY num_ensayos DESC;
  "

  DBI::dbGetQuery(
    con,
    consulta_sql,
    params = list(paste0("%", patologia, "%"))
  )
}

#' Promotores con más ensayos clínicos de Fase 3 en AACT
#'
#' Conecta en remoto a la base de datos AACT (ClinicalTrials.gov) y cruza
#' las tablas \code{ctgov.studies} y \code{ctgov.sponsors} mediante SQL para
#' identificar los promotores con mayor número de ensayos en Fase 3 según su
#' estado de reclutamiento.
#'
#' @param limite Número máximo de filas a devolver (por defecto, 15).
#' @param solo_promotor_principal Lógico. Si es \code{TRUE} (por defecto),
#'   filtra por \code{lead_or_collaborator = 'lead'} para evitar duplicar
#'   ensayos entre colaboradores.
#'
#' @return Un \code{data.frame} con el promotor, estado del ensayo, número de
#'   estudios y tamaño muestral medio.
#' @export
#'
#' @examples
#' \dontrun{
#' top_promotores_fase3_aact(limite = 10)
#' }
top_promotores_fase3_aact <- function(limite = 15, solo_promotor_principal = TRUE) {
  usuario <- Sys.getenv("AACT_USER")
  clave <- Sys.getenv("AACT_PASSWORD")

  if (usuario == "" || clave == "") {
    stop("Credenciales no encontradas. Configura AACT_USER y AACT_PASSWORD en .Renviron y reinicia R.")
  }

  con <- DBI::dbConnect(
    RPostgres::Postgres(),
    host = "aact-db.ctti-clinicaltrials.org",
    port = 5432,
    dbname = "aact",
    user = usuario,
    password = clave
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  filtro_lead <- if (isTRUE(solo_promotor_principal)) {
    "AND sp.lead_or_collaborator = 'lead'"
  } else {
    ""
  }

  consulta_sql <- sprintf("
    SELECT
      sp.name AS promotor,
      s.overall_status AS estado_reclutamiento,
      COUNT(DISTINCT s.nct_id) AS n_ensayos,
      ROUND(AVG(s.enrollment), 0) AS tamano_muestral_medio
    FROM ctgov.studies s
    INNER JOIN ctgov.sponsors sp
      ON s.nct_id = sp.nct_id
    WHERE s.phase = 'PHASE3'
      %s
    GROUP BY sp.name, s.overall_status
    ORDER BY n_ensayos DESC
    LIMIT %d;
  ", filtro_lead, as.integer(limite))

  DBI::dbGetQuery(con, consulta_sql)
}


#' Distribución de tipos de intervención por patología en AACT
#'
#' Cruza las tablas \code{ctgov.studies}, \code{ctgov.conditions} y
#' \code{ctgov.interventions} en AACT para comparar el número de ensayos
#' clínicos según el tipo de intervención (\code{DRUG}, \code{BIOLOGICAL},
#' \code{DEVICE}, etc.) y fase clínica en una patología concreta.
#'
#' @param patologia Cadena de texto con el término de búsqueda en inglés
#'   (por ejemplo, \code{"melanoma"}, \code{"diabetes"} o \code{"asthma"}).
#'
#' @return Un \code{data.frame} ordenado por número de ensayos clínicos.
#' @export
#'
#' @examples
#' \dontrun{
#' intervencion_por_patologia_aact("melanoma")
#' }
intervencion_por_patologia_aact <- function(patologia = "melanoma") {
  usuario <- Sys.getenv("AACT_USER")
  clave <- Sys.getenv("AACT_PASSWORD")

  if (usuario == "" || clave == "") {
    stop("Credenciales no encontradas. Configura AACT_USER y AACT_PASSWORD en .Renviron y reinicia R.")
  }

  con <- DBI::dbConnect(
    RPostgres::Postgres(),
    host = "aact-db.ctti-clinicaltrials.org",
    port = 5432,
    dbname = "aact",
    user = usuario,
    password = clave
  )
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  patron_busqueda <- paste0("%", tolower(trimws(patologia)), "%")

  consulta_sql <- DBI::sqlInterpolate(
    con,
    "
    SELECT
      i.intervention_type AS tipo_intervencion,
      s.phase AS fase_clinica,
      COUNT(DISTINCT s.nct_id) AS n_ensayos
    FROM ctgov.studies s
    INNER JOIN ctgov.conditions c
      ON s.nct_id = c.nct_id
    INNER JOIN ctgov.interventions i
      ON s.nct_id = i.nct_id
    WHERE c.downcase_name LIKE ?patron
    GROUP BY i.intervention_type, s.phase
    ORDER BY n_ensayos DESC;
    ",
    patron = patron_busqueda
  )

  DBI::dbGetQuery(con, consulta_sql)
}


# # -> Prueba aqui tambien tu segunda funcion SQL propia sobre AACT
#top_promotores_fase3_aact(limite = 10)
# intervencion_por_patologia_aact("melanoma")
