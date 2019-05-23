#' CLASS seleniumScraper
#'
#' seleniumScraper Class is a Superclass of webdriver-based scrapers
#'    This wraps an RSelenium::remoteDriver object
#'    Specific instances for individual websites should inherit from this
#'
#' @export seleniumScraper
#' @exportClass seleniumScraper
#' @aliases seleniumScraper
#'

CHROME_VERSION = "74.0.3729.6"

seleniumScraper <- R6::R6Class(
  "seleniumScraper",
  public = list(
    username = NULL,
    password = NULL,
    headless = TRUE,
    download_path = NULL,
    browser_port = NA,
    browser = NULL,
    driver = NULL,
    timeout_ms = NA,
    extraCapabilities = list(
      loggingPrefs = list(
        performance = 'INFO'
      ),
      chromeOptions = list(
        args = c('--window-size=1280,800',
                 '--no-sandbox')),
      perfLoggingPrefs = list(
        enablePage = FALSE
      )
    ),

    initialize = function(
      username,
      password,
      headless = TRUE,
      download_path = getwd(),
      browser_port = 4567L,
      timeout_ms = 10000,
      driver_version = "latest",
    ){

      self$username = username
      self$password = password
      self$headless = headless
      self$download_path = download_path
      self$browser_port = browser_port
      self$timeout_ms = timeout_ms
      self$driver_version = driver_version

      if (self$headless) {
        self$extraCapabilities$chromeOptions$args = c(self$extraCapabilities$chromeOptions$args,
                                                      '--headless',
                                                      '--disable-gpu')
      }

      if ( Sys.info()['sysname'] == "Windows" ) {
        self$download_path <<- gsub("/", "\\\\", self$download_path)
      }


      self$driver <- RSelenium::remoteDriver(
        browserName = "chrome",
        port = self$browser_port,
        extraCapabilities = self$extraCapabilities)
    },

    start = function(){
      self$browser = wdman::chrome(
        port = self$browser_port,
        version = self$driver_version)
      self$driver$open()
      server_URL = self$driver$serverURL
      session_info_id = self$driver$sessionInfo[["id"]]
      self$driver$queryRD(
        ipAddr = paste0(server_URL, "/session/", session_info_id, "/chromium/send_command"),
        method = "POST",
        qdata = list(
          cmd = "Page.setDownloadBehavior",
          params = list(
            behavior = "allow",
            downloadPath = self$download_path)))
      self$driver$setImplicitWaitTimeout(milliseconds = self$timeout_ms)
    },

    stop = function(){
      self$driver$close()
    },

    close = function(){
      self$driver$close()
      self$browser$stop()
    }
  )
)