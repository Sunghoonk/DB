#' @description
#' Gets the sensor data for a specific device id from a database table, file or whatever source you want to query
#' 
#' @param stream_parameters The PHONE_STREAM_PARAMETERS key in config.yaml. If you need specific parameters add them there.
#' @param device A device ID string
#' @param sensor_container database table or file containing the sensor data for all participants. This is the PHONE_SENSOR[CONTAINER] key in config.yaml
#' @param columns the columns needed from this sensor (we recommend to only return these columns instead of every column in sensor_container)
#' @return A dataframe with the sensor data for device

pull_data <- function(stream_parameters, device, sensor, sensor_container, columns){
  if(!dir.exists(stream_parameters$FOLDER))
    stop("[PHONE_DATA_STREAMS][aware_csv][FOLDER] does not exist: ", stream_parameters$FOLDER)
  data_file <- file.path(stream_parameters$FOLDER, sensor_container)

  if(!file.exists(data_file))
    stop("The CSV file with ",sensor," data does not exist: '", data_file, "'. In config.yaml, configure [",sensor,"][CONTAINER] with the name of your CSV file including its '.csv' extension (you set the folder name in [PHONE_DATA_STREAMS][aware_csv]")

  if(!endsWith(data_file, ".csv"))
    stop("The data container should be a CSV file: ", data_file)

  # Letting the user know what we are doing
  message(paste0("Reading this CSV file: ", data_file))
  message(paste0("stream_parameters: ", stream_parameters))
  message(paste0("device: ", device))
  message(paste0("sensor: ", sensor))
  message(paste0("sensor_container: ", sensor_container))
  message(paste0("columns: ", columns))

  sensor_data <- read_delim_chunked(data_file, escape_backslash = TRUE, delim = ",", escape_double = FALSE, quote = "\"",
    callback = DataFrameCallback$new(function(x, pos) x[x[[columns$DEVICE_ID]] == device, unlist(columns, use.names = FALSE)] ), progress = T, chunk_size = 50000)
    # callback = DataFrameCallback$new(function(x, pos) subset(x,x[[columns$DEVICE_ID]] == device, select = unlist(columns))), progress = T, chunk_size = 50000)
  if(is.null(sensor_data)) # emtpy file
    sensor_data <- read.csv(data_file) %>% select(unlist(columns, use.names = FALSE))

  if(nrow(sensor_data) == 0)
    warning("The device '", device,"' did not have data in ", sensor_container)
  return(sensor_data)
}
