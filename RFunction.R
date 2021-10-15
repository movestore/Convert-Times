library('move')
library('lubridate')
library('lutz')
library('sf')

rFunction <- function(data,local=FALSE,local_details=FALSE,mean_solar=FALSE,true_solar=FALSE)
{

  Sys.setenv(tz="UTC")
  
  if (local==FALSE & local_details==FALSE & mean_solar==FALSE & true_solar==FALSE) logger.info("You have not selected any timestamp conversion. The original dataset will be returned and provided as csv output.")
  
  data.csv <- as.data.frame(data)
  names(data.csv) <- make.names(names(data.csv),allow_=FALSE)
  data.csv <- data.csv[c("trackId","timestamp","location.long","location.lat","sensor","taxon.canonical.name")]
  
  # ask the cache and/or Google for the timezone at these coordinates
  tz_info <- tz_lookup_coords(coordinates(data)[,2], coordinates(data)[,1], method = "accurate")
  
  #return in daylight local
  if(local==TRUE) 
  {
    logger.info("You have selected to add local timestamps.")
    timestamp_local <- apply(data.frame(timestamps(data),tz_info), 1, function(x) as.character(lubridate::with_tz(x[1], x[2])))
    data@data <- cbind(data@data,timestamp_local,"local_lz"=tz_info)
    data.csv <- cbind(data.csv,timestamp_local,"local_timezone"=tz_info)
  }
  if (local_details==TRUE)
  {
    logger.info("You have selected to add detailed time information of the local timestamps.")
    timestamp_local <- apply(data.frame(timestamps(data),tz_info), 1, function(x) as.character(lubridate::with_tz(x[1], x[2])))
    date <- as.Date(timestamp_local)
    
    time <- strftime(timestamp_local, format="%H:%M:%S")
    year <- year(timestamp_local)
    month <- months(as.POSIXct(timestamp_local))
    yday <- as.numeric(strftime(date, format = "%j"))
    calender_week <- as.numeric(strftime(date, format = "%V"))
    weekday <- weekdays(as.POSIXct(timestamp_local))
    data@data <- cbind(data@data,date,time,year,month,weekday,yday,calender_week)
    data.csv <- cbind(data.csv,date,time,year,month,weekday,yday,calender_week)
  }
  if (mean_solar==TRUE)
  {
    logger.info("You have selected to add mean solar time timestamps.")
    # reference to convert_UTC_to_solartime function by Alison Appling (USGS)
    time.adjustment <- 239.34 * coordinates(data)[,1] #in secs --> 3.989 minutes = 239.34 seconds per degree
    timestamp_mean_solar <- as.character(timestamps(data) + as.difftime(time.adjustment,units="secs")) #add seconds to the UTC time
    data@data <- cbind(data@data,timestamp_mean_solar)
    data.csv <- cbind(data.csv,timestamp_mean_solar)
  }
  if (true_solar==TRUE)
  {
    logger.info("You ahve selected to add true solar time timestamps.")
    time.adjustment <- 239.34 * coordinates(data)[,1] #in secs --> 3.989 minutes = 239.34 seconds per degree
    timestamp_mean_solar <- timestamps(data) + as.difftime(time.adjustment,units="secs") #add seconds to the UTC time
    # Use the equation of time to compute the discrepancy between apparent and
    # mean solar time. E is in minutes.
    jday <- as.numeric(strftime(timestamp_mean_solar, format = "%j")) -1
    E <- 9.87*sin(((2*360*(jday-81))/365)/180*pi) - 7.53*cos(((360*(jday-81))/365)/180*pi) - 1.5*sin(((360*(jday-81))/365)/180*pi)
    timestamp_true_solar <- timestamp_mean_solar + as.difftime(E,units="mins")
    data@data <- cbind(data@data,timestamp_true_solar)
    data.csv <- cbind(data.csv,timestamp_true_solar)
  }    

  write.csv(data.csv, file = paste0(Sys.getenv(x = "APP_ARTIFACTS_DIR", "/tmp/"),"data_wtime.csv"),row.names=FALSE)
  #write.csv(data.csv, file = "data_wtime.csv",row.names=FALSE)
  
  result <- data
  return(result)
}

  
  
  
  
  
  
  
  
  
  