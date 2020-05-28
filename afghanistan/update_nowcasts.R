
# Packages -----------------------------------------------------------------
require(EpiNow, quietly = TRUE)
require(NCoVUtils, quietly = TRUE)
require(furrr, quietly = TRUE)
require(future, quietly = TRUE)
require(dplyr, quietly = TRUE)
require(tidyr, quietly = TRUE)
require(magrittr, quietly = TRUE)
require(future.apply, quietly = TRUE)
require(fable, quietly = TRUE)
require(fabletools, quietly = TRUE)
require(feasts, quietly = TRUE)
require(urca, quietly = TRUE)
require(data.table)


# Get cases ---------------------------------------------------------------

NCoVUtils::reset_cache()

cases <- get_afghan_regional_cases() %>%
  dplyr::select(date, region, region_code = iso_3166_2, cases) %>%
  dplyr::filter(!is.na(cases))


region_codes <- cases %>%
  dplyr::select(region, region_code) %>%
  unique()

saveRDS(region_codes, "afghanistan/data/region_codes.rds")

cases <- cases %>%
  dplyr::rename(local = cases) %>%
  dplyr::mutate(imported = 0) %>%
  tidyr::gather(key = "import_status", value = "confirm", local, imported) %>% 
  tidyr::drop_na(region)

# Shared delay ------------------------------------------------------------

delay_defs <- readRDS("delays.rds")

# Set up cores -----------------------------------------------------
if (!interactive()){
  options(future.fork.enable = TRUE)
}

future::plan("multiprocess", workers = round(future::availableCores() / 2))



# Run pipeline ----------------------------------------------------

EpiNow::regional_rt_pipeline(
  cases = cases,
  delay_defs = delay_defs,
  target_folder = "afghanistan/regional",
  horizon = 14,
  approx_delay = TRUE,
  report_forecast = TRUE,
  forecast_model = function(...){EpiSoon::forecastHybrid_model(
    model_params = list(models = "aeftz", weights = "equal"),
    forecast_params = list(PI.combination = "mean"), ...)}
)


# Summarise results -------------------------------------------------------

EpiNow::regional_summary(results_dir = "afghanistan/regional",
                         summary_dir = "afghanistan/regional-summary",
                         target_date = "latest",
                         region_scale = "Region")
