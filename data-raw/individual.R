## code to prepare `individual` dataset goes here
## Setup ----
library(dplyr)

##Combine individual tables ----
##Create paths to inputs
#creates raw data path
raw_data_path <- here::here("data-raw",
                            "wood-survey-data-master") #go from this directory to this directory
individual_paths <- fs::dir_ls( 
  fs::path(raw_data_path, "individual")
  )
#dir_ls lists the contents of a directory, need to give it the path to directory that we want the contents of, creates list of character strings that correspond to individual files within individual folder
#iterates over each file in individual folder (that you read to using the raw_data_path) and reads it in

#read in all individual tables into one
individual <- purrr::map(.x = individual_paths,
~readr::read_csv(.x, col_types=readr::cols(.default="c"))) %>%
#can just assign the putput to an object, no need to preemptively set up a storage system (no bookkeeping)
  purrr::list_rbind()%>%
#produces df tibble all in one step
  readr::type_convert()


individual %>%
  readr::write_csv(
    file=fs::path(raw_data_path, "vst_individuals.csv" ) 
    #directory want is the raw data path, want to call it vst_
  )


# Combine NEON data tables ----
# read in additional table
maptag <- readr::read_csv(
  fs::path(
    raw_data_path,
    "vst_mappingandtagging.csv"
  ),
  show_col_types = FALSE
) %>%
  select(-eventID)

perplot <- readr::read_csv(
  fs::path(
    raw_data_path,
    "vst_perplotperyear.csv"
  ),
  show_col_types = FALSE
) %>%
  select(-eventID)

# Left join tables to individual
individual %<>%
  left_join(maptag,
            by = "individualID",
            suffix = c("", "_map")
  ) %>%
  left_join(perplot,
            by = "plotID",
            suffix = c("", "_ppl")
  ) %>%
  assertr::assert(
    assertr::not_na, stemDistance, stemAzimuth, pointID,
    decimalLongitude, decimalLatitude, plotID
  )

# ---- Geolocate individuals_functions ----
individual <- individual %>%
  mutate(
    stemLat = get_stem_location(
      decimalLongitude = decimalLongitude,
      decimalLatitude = decimalLatitude,
      stemAzimuth = stemAzimuth,
      stemDistance = stemDistance
    )$lat,
    stemLon = get_stem_location(
      decimalLongitude = decimalLongitude,
      decimalLatitude = decimalLatitude,
      stemAzimuth = stemAzimuth,
      stemDistance = stemDistance
    )$lon
  )

# create data directory
fs::dir_create(here::here("data"))

# write out analytic file
individual %>%
  janitor::clean_names() %>%
  readr::write_csv(here::here("data", "individual.csv"))


