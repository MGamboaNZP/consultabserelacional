
<!-- README.md is generated from README.Rmd. Please edit that file -->

# consultabserelacional

Paquete de R para la consulta remota y agregación estadística de ensayos
clínicos desde la base de datos oficial **AACT (ClinicalTrials.gov)**
mediante SQL (`DBI` y `RPostgres`).

## Tablas de AACT consultadas

Las funciones realizan cruces relacionales (`INNER JOIN`) directamente
en el servidor remoto sobre el esquema `ctgov`:

- `ctgov.studies`: fases clínicas, estado de reclutamiento y tamaño
  muestral.
- `ctgov.conditions`: patologías y condiciones médicas estandarizadas.
- `ctgov.sponsors`: promotores principales y colaboradores de cada
  ensayo.
- `ctgov.interventions`: tipo de intervención clínica (fármaco,
  biológico, dispositivo, etc.).

## Instalación

``` r
# install.packages("remotes")
remotes::install_github("MGamboaNZP/consultabserelacional")
```

## Configuración de credenciales (obligatorio)

Por seguridad, el paquete no almacena contraseñas en el código. Antes de
usarlo, regístrate gratuitamente en AACT y guarda tus credenciales en tu
archivo local `.Renviron`:

``` r
usethis::edit_r_environ()
```

Añade estas dos líneas, guarda el archivo y reinicia R
(`Session -> Restart R`):

``` text
AACT_USER=tu_usuario_aact
AACT_PASSWORD=tu_contraseña_aact
```

## Ejemplo de uso en vivo contra AACT

``` r
library(consultabserelacional)

# Resumen general por fase clínica en melanoma
resumen_ensayos_aact("Melanoma")
#>      fase_clinica num_ensayos reclutamiento_medio
#> 1          PHASE2         961                69.6
#> 2          PHASE1         747                59.3
#> 3 No especificada         548             12970.9
#> 4   PHASE1/PHASE2         422                71.0
#> 5              NA         389               467.6
#> 6          PHASE3         182               659.5
#> 7    EARLY_PHASE1          60                33.4
#> 8          PHASE4          30                89.7
#> 9   PHASE2/PHASE3          23               183.5

# Top 10 promotores con más ensayos completados en Fase 3
top_promotores_fase3_aact(limite = 10)
#>                    promotor estado_reclutamiento n_ensayos
#> 1           GlaxoSmithKline            COMPLETED       777
#> 2               AstraZeneca            COMPLETED       569
#> 3   Merck Sharp & Dohme LLC            COMPLETED       531
#> 4  Novartis Pharmaceuticals            COMPLETED       523
#> 5                    Pfizer            COMPLETED       439
#> 6                    Sanofi            COMPLETED       438
#> 7     Eli Lilly and Company            COMPLETED       413
#> 8         Hoffmann-La Roche            COMPLETED       413
#> 9      Boehringer Ingelheim            COMPLETED       340
#> 10         Novo Nordisk A/S            COMPLETED       296
#>    tamano_muestral_medio
#> 1                   1255
#> 2                   1118
#> 3                   1050
#> 4                    636
#> 5                    898
#> 6                    851
#> 7                    749
#> 8                    565
#> 9                    875
#> 10                   661

# Distribución por tipo de intervención en melanoma (10 primeras filas)
head(intervencion_por_patologia_aact("melanoma"), 10)
#>    tipo_intervencion  fase_clinica n_ensayos
#> 1               DRUG        PHASE2       793
#> 2               DRUG        PHASE1       531
#> 3         BIOLOGICAL        PHASE1       321
#> 4               DRUG PHASE1/PHASE2       312
#> 5         BIOLOGICAL        PHASE2       286
#> 6         BIOLOGICAL PHASE1/PHASE2       177
#> 7              OTHER          <NA>       137
#> 8               DRUG        PHASE3       134
#> 9              OTHER            NA       128
#> 10             OTHER        PHASE2       111
```
