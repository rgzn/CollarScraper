require(CollarScraper)

# Set these variable in your script:
username = ""
password = ""

# Otherwise, load from a file:
# load("./demo/login_info.Rda")

download_dir = paste0(getwd(),"/","tmp")

# Create scraper:
<<<<<<< HEAD
myLotek = lotekScraper$new(username = username,
                           password = password,
                           headless = FALSE,
                           download_path = download_dir,
                           driver_version = "74.0.3729.6")
=======
myLotek = lotekScraper$new(username = username, password = password, headless = FALSE, driver_version = "74.0.3729.6")
>>>>>>> fa65da8a963c44e48ae3e33396febaf6265b9a45

# Start browser:
myLotek$start()

# Submit login data:
myLotek$login()

# Get a data frame with available collars:
collarsDF = myLotek$get_collar_df()

# Set a start and end date for requested data:
end = Sys.Date()
begin = end - 365

# download a single collar:
collar1 = collarsDF[1,]
myFilename = myLotek$dl_collar(collar_id = collar1$ID,
                               start_date = begin,
                               end_date = end,
                               format = "Text Listing")


# download each collar and return a list of downloaded files
#    use default arguments for dl_collar method
downloadedFiles = lapply(collarsDF$ID, function(x) myLotek$dl_collar(x))

# stop browser:
myLotek$close()
