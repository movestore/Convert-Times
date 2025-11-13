library('move2')
library('lubridate')
library('lutz')
library('sf')
library('suncalc')
library('dplyr')
library('stringr')
library('readr')

rFunction <- function(data,
                      local=FALSE,
                      local_details=FALSE,
                      sunriset=FALSE,
                      mean_solar=FALSE,
                      true_solar=FALSE)
{
  
  if (sum(local, local_details, sunriset, mean_solar, true_solar) == 0){
    
    logger.info("You have not selected any timestamp conversion. The original dataset will be returned")
                # and provided as csv output.")
    
    # readr::write_csv(data, file = appArtifactPath("data_wtime.csv"))
    
  } else {
  
    #' get longlat coords, transforming accordingly if CRS is not WGS84
    if(!st_is_longlat(data)){
      lonlat <- data |> 
        sf::st_transform(4326) |> 
        sf::st_coordinates()
    }else{
      lonlat <- sf::st_coordinates(data)
    }
    
    # get the time column of input dataset
    tm_col_id <- mt_time_column(data)  
    
    
    # Add sunrise and sunset timestamps
    if(sunriset == TRUE){
      logger.info("You have selected to add the time of sunrise and sunset.")
      
      # Calculate UTC sunrise and sunset for each event/location
      sun_rise_set <- data.frame(
        date = as.Date(data[[tm_col_id]]),
        lon = lonlat[, "X"],
        lat = lonlat[, "Y"]
      ) |> 
        suncalc::getSunlightTimes(data = _, keep = c("sunrise", "sunset"), tz = "UTC")
      
      # bind new cols
      data <- data |> 
        dplyr::mutate(
          sunrise_timestamp = sun_rise_set$sunrise,
          sunset_timestamp = sun_rise_set$sunset
        )
    }
    
    
    # Bind local time variables
    if(local == TRUE | local_details == TRUE) {
      
      if(local == TRUE) logger.info("You have selected to add local timestamps.") 
      
      # add timezone - ask the cache and/or Google for the timezone at these coords
      data$local_tz <- lutz::tz_lookup_coords(lonlat[, "Y"], lonlat[, "X"], method = "accurate")
      
      # handling events with multiple TZs due to geo-political disputes
      multz_idx <- stringr::str_which(data$local_tz, ".+;.+") # {lutz} separates TZs with ';'
      
      if(length(multz_idx) > 0){
        logger.warn(
          paste0(
            "Some events initially annotated with multiple TZs for being located ",
            "in areas under geo-political disputes.\n",
            "      Selecting the first TZ provided for timestamp parsing purposes.")
        )
        
        data$local_tz[multz_idx] <- stringr::str_extract(data$local_tz[multz_idx], ".+(?=;)")
      }
      
      # add local timestamps
       data <- data |>
         dplyr::mutate(
           timestamp_local = lubridate::with_tz(.data[[tm_col_id]], unique(local_tz)),
           .before = local_tz, 
           .by = local_tz
         ) 
      
      
      # add local time details
      if (local_details == TRUE){
        logger.info("You have selected to add detailed time information of the local timestamps.")
        
        data <- data |> 
          dplyr::mutate(
            date = as.Date(timestamp_local),
            time = format(timestamp_local, format="%H:%M:%S"),
            year = lubridate::year(timestamp_local),
            month = months(timestamp_local),
            weekday = weekdays(timestamp_local),
            yday = as.numeric(format(timestamp_local, format = "%j")),
            calender_week = as.numeric(format(timestamp_local, format = "%V"))
          )
      }
    }
    
    
    if(mean_solar == TRUE | true_solar == TRUE){
      
      # reference to convert_UTC_to_solartime function by Alison Appling (USGS)
      time.adjustment <- 239.34 * lonlat[, "X"] #in secs --> 3.989 minutes = 239.34 seconds per degree
      
      # add mean solar timestamp (ensuring computations based on UTC)
      timestamp_mean_solar <- lubridate::with_tz(data[[tm_col_id]], "UTC") + as.difftime(time.adjustment, units="secs")
      
      if(mean_solar == TRUE){
        logger.info("You have selected to add mean solar time timestamps.")  
        data$timestamp_mean_solar <- timestamp_mean_solar
      }
      
      if(true_solar == TRUE){
        logger.info("You have selected to add true solar time timestamps.")
        
        # Use the equation of time to compute the discrepancy between apparent and
        # mean solar time. E is in minutes.
        jday <- as.numeric(format(timestamp_mean_solar, format = "%j")) - 1
        E <- 9.87*sin(((2*360*(jday-81))/365)/180*pi) - 7.53*cos(((360*(jday-81))/365)/180*pi) - 1.5*sin(((360*(jday-81))/365)/180*pi)
        timestamp_true_solar <- timestamp_mean_solar + as.difftime(E, units="mins")
        
        data$timestamp_true_solar <- timestamp_true_solar
      }
    }
    
    
    # # Prepare data for csv artifact (grossly based on previous app move1 version)
    # data |> 
    #   dplyr::relocate(
    #     mt_track_id_column(data),
    #     dplyr::all_of(tm_col_id),
    #     .before = 1
    #   ) |> 
    #   dplyr::mutate(
    #     location_long = lonlat[, "X"], 
    #     location_lat = lonlat[, "Y"],
    #     .after = dplyr::all_of(tm_col_id)
    #   ) |> 
    #   # using {readr} as `write.csv` was not exporting the data correctly
    #   readr::write_csv(file = appArtifactPath("data_wtime.csv"))
  }
  
  return(data)
  
}
