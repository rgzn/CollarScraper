CollarScraper
================

This is a package of GPS collar data downloaders. Currently this is just for Lotek. 

## Requirements: 

  + [R](https://www.r-project.org/) >= 3.0
  + [Google Chrome](https://www.google.com/chrome/) >= 71.0 
  + [chromedriver](https://sites.google.com/a/chromium.org/chromedriver/) >= 2.45

## Install 

To install the development version from GitHub, run:

```R
# install.packages("devtools")
devtools::install_github("rgzn/CollarScraper")
```

## Use:

From within R: 

```{R}
require(CollarScraper)
username = ""
password = ""

# Create scraper:
myLotek = lotekScraper$new(username = username, password = password, headless = FALSE )

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

```
