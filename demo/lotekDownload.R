require(CollarScraper)

# Create scraper:
myLotek = lotekScraper$new(username = "changeme", password = "*****", headless = TRUE )

# Start browser:
myLotek$start()

# Submit login data:
myLotek$login()

# Get a data frame with available collars:
collarsDF = myLotek$get_collar_df()

# Set a start and end date for requested data:
end = Sys.Date()
begin = end - 365

# download each collar and return a list of downloaded files
downloadedFiles = lapply(collarsDF$ID, function(x) myLotek$dl_collar(
  collar_id = x,
  start_date = begin,
  end_date = end))

# stop browser:
myLotek$close()
