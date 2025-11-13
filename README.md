# Add Local and Solar Time

MoveApps

GitHub repository: *github.com/movestore/Convert-Times*

## Description
This App calculates local information about the time, including (i) the local timestamp and timezone, (ii) local time components, (iii) time of local sunrise and sunset, (iv) mean solar time and/or (v) true solar time. The values are added to the output.

## Documentation
The timestamp and location of each record in your data are used to calculate local timezones. Timezones are identified from longitute and latitude with the `tz_lookup_coords()` function of the [lutz](https://cran.r-project.org/web/packages/lutz/index.html) package and include Daylight Savings Time where applicable. In addition, the timestamps of sunrise and sunset of the day are provided (calculated with the `getSunlightTimes()` function in the [suncalc](https://cran.r-project.org/web/packages/suncalc/index.html) package). For each local timestamp it is also possible to have the following time components extracted: date, time, year, month, Julian day, calender week, weekday. All calculations assume that the input data provide timestamp in UTC and locations in the WGS85 coordinate reference system.

It is also possible to calculate [solar times](https://en.wikipedia.org/wiki/Solar_time). It is possible to select mean and/or true (apparent) solar times. Mean solar time is approximated by adjustment of 3.989 min per degree from longitute zero. It approximates solar noon at clock noon to ~20 min accuracy. True solar time is then calculated from mean solar time by use of the equation of time (see [Yard et al., 2005](https://doi.org/10.1016/j.ecolmodel.2004.07.027)). The two solar time conversions are adapted from the function convert_UTC_to_solartime() in the R package [USGS-R/streamMetabolizer](https://github.com/USGS-R/streamMetabolizer) described in [Appling et al. (2018)](https://doi.org/10.1002/2017JG004140).

### Application scope
#### Generality of App usability
This App was developed for any taxonomic group. 

#### Required data properties
The App should work for any kind of (location) data.


### Input data
move2::move2_loc

### Output data
move2::move2_loc

### Artefacts
none

### Settings
**Local time (`local`):** Checkbox to select if local times should be added to the dataset. Column added: "timestamp_local". Defaults to FALSE.

**Local time details (`local_details`):** Checkbox to select if time components of local time shall be added to the dataset. Columns "local_tz", "date", "time", "year", "month", "weekday", "yday", "calender_week" will be added. Defaults to FALSE.

**Sunrise and sunset (`sunriset`):** Checkbox to select if the time of local sunrise and sunset shall be added to the dataset. Columns added: "sunrise_timestamp", "sunset_timestamp". Defaults to FALSE.

**Mean solar time (`mean_solar`):** Checkbox to select if mean solar time should be added to the dataset. Column added: "timestamp_mean_solar". Defaults to FALSE.

**True solar time (`true_solar`):** Checkbox to select if true solar time should be added to the dataset. Column added: "timestamp_true_solar". Defaults to FALSE.

### Changes in output data
The App adds to the input the selected settings of local time information, based on the selected settings. All timestamps are provided in the format `yyyy-MM-dd HH:mm:ss`. The sunrise, sunset, mean solar and true solar times are reported in UTC. The sunrise and sunset are provided for the sunrise and sunset between which the local timestamp falls. The local time components are based on the local time. 

### Null or error handling:
**Local time (`local`):** The default value FALSE will lead to no local times being added to the dataset. NULL is not possible.

**Local time details (`local_details`):** The default value FALSE will lead to no local time components being added to the dataset. NULL is not possible.

**Mean solar time (`mean_solar`):** The default value FALSE will lead to no mean solar time being added to the dataset. NULL is not possible.

**True solar time (`true_solar`):** The default value FALSE will lead to no true solar time being added to the dataset. NULL is not possible.
