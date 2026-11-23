# consultabserelacional

Paquete de R para la consulta remota y agregación estadística de ensayos clínicos desde la base de datos oficial **AACT (ClinicalTrials.gov)** mediante SQL (`DBI` y `RPostgres`).

## Tablas de AACT consultadas

Las funciones del paquete realizan cruces relacionales (`INNER JOIN`) en el servidor remoto sobre el esquema `ctgov`:
* `ctgov.studies`: fases clínicas, estado de reclutamiento y tamaño muestral.
* `ctgov.conditions`: patologías y condiciones médicas estandarizadas.
* `ctgov.sponsors`: promotores principales y colaboradores de cada ensayo.
* `ctgov.interventions`: tipo de intervención clínica (fármaco, biológico, dispositivo, etc.).

## Instalación

```r
# install.packages("remotes")
remotes::install_github("tu-usuario/consultabserelacional")
```

## Configuración de credenciales (obligatorio)

Por seguridad, el paquete no almacena contraseñas en el código. Antes de usarlo, regístrate gratuitamente en AACT y guarda tus credenciales en tu archivo local `.Renviron`:

```r
usethis::edit_r_environ()
```

Añade estas dos líneas, guarda el archivo y reinicia R (`Session -> Restart R`):

```text
AACT_USER=tu_usuario_aact
AACT_PASSWORD=tu_contraseña_aact
```

## Ejemplo de uso

```r
library(consultabserelacional)

# Resumen de ensayos clínicos de melanoma por fase
resumen_ensayos_aact("Melanoma")

# Top 10 promotores con más ensayos completados en Fase 3
top_promotores_fase3_aact(limite = 10)
```
