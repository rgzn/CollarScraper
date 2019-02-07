#' CLASS lotekScraper
#'
#' lotekScraper Class
#'
#'
#' @importFrom magrittr "%>%"
#' @importFrom dplyr "first"
#' @importFrom dplyr "last"
#'
#'
#'
#' @include seleniumScraper.R
#' @export lotekScraper
#' @exportClass lotekScraper
#' @aliases lotekScraper
#' @examples
#'

lotekScraper <- R6::R6Class(
  "lotekScraper",
  inherit = seleniumScraper,
  public = list(
    home_url = "https://webservice.lotek.com",
    data_url = "https://webservice.lotek.com/DeviceDataForm.aspx",

    # parsing constants:
    date_format = "%B %d, %Y",

    # web elements:
    username_element_id = "ctl00_LeftBarContent_lvLeftPanel_LoginGWS_UserName",
    password_element_id = "ctl00_LeftBarContent_lvLeftPanel_LoginGWS_Password",
    loginbutton_element_id = "ctl00_LeftBarContent_lvLeftPanel_LoginGWS_LoginButton",
    username_welcome_element_id = "ctl00_MenuBarContent_lvMenu_lnUN",
    downloadbutton_element_id = "ctl00_LeftBarContent_lvLeftPanel_btnDownload",
    downscrollbutton_element_css = ".e-vdown.e-chevron-down_01.e-icon.e-box.e-button",
    upscrollbutton_element_css = ".e-vup.e-chevron-up_01.e-icon.e-box.e-button",
    errormsg_element_id = "ctl00_LeftBarContent_lvLeftPanel_lblErrorMsg",
    devicelist_element_id = "ctl00_LeftBarContent_lvLeftPanel_lstDevices",
    dloptions_element_id = "ctl00_LeftBarContent_lvLeftPanel_ddlDLOptions",
    startdate_element_id = "ctl00_LeftBarContent_lvLeftPanel_txtStartDate",
    enddate_element_id = "ctl00_LeftBarContent_lvLeftPanel_txtEndDate",
    collar_table_element_class = "e-gridcontent",
    collar_table_row_xpath = "//tr[@data-role='row']",

    # javascript functions:
    logout_js = "__doPostBack('ctl00$MenuBarContent$lvMenu$lsLoginStatus$ctl00','')",

    #collar_table_element = NULL,
    collar_element_list = NULL,

    # go_home()
    # Take browser to the Lotek home page
    go_home = function() {
      self$driver$navigate(self$home_url)
    },

    # is_logged_in()
    # Check if browser is logged in
    is_logged_in = function() {
      welcome_elements =
        self$driver$findElements(using="id", username_welcome_element_id)
      if(length(welcome_elements) == 0) {
        return(FALSE)
      } else if (welcome_elements[[1]] != self$username) {
        return(FALSE)
      } else {
        return(TRUE)
      }
    },

    # logout()
    # log user out of website
    logout = function() {
      self$driver$executeScript(logout_js)
    },

    # login()
    # Take browser to the homepage, enter login info and submit
    login = function(username = self$username,
                     password = self$password) {
      self$go_home()
      if (self$is_logged_in()) {
        return(TRUE)
      }
      username_element = self$driver$findElement(using = "id", value =
                                                   self$username_element_id)
      password_element = self$driver$findElement(using = "id", value =
                                                   self$password_element_id)
      loginbutton_element = self$driver$findElement(using = "id", value =
                                                      self$loginbutton_element_id)
      username_element$sendKeysToElement(list(username))
      password_element$sendKeysToElement(list(password))
      loginbutton_element$clickElement()
      if( self$is_logged_in() != TRUE) {
        stop("Unable to log in")
      }
    },

    # go_download_page()
    # Go to the device download page
    go_download_page = function() {
      if( self$is_logged_in() != TRUE) {
        self$login()
      }

      # Following Links:
      # download_link_element = self$driver$findElement(using = "partial link text", "List View")
      # download_link_element$clickElement()

      # Go to URL:
      self$driver$navigate(self$data_url)
    },


    # parse_collar_table()
    # Find the collar table elements and read them.
    parse_collar_table = function() {
      if(self$driver$getCurrentUrl() != self$data_url) {
        self$go_download_page()
      }
      collar_table_element = self$driver$findElement(
        using="class name",
        self$collar_table_element_class)
      self$collar_element_list = collar_table_element$findChildElements(
        using="xpath",
        self$collar_table_row_xpath)
      return(collar_table_element)
    },

    get_collar_df = function() {
      collar_table_element = self$parse_collar_table()
      collar_table_html = collar_table_element$getElementAttribute('outerHTML')[[1]]
      collar_df = collar_table_html %>%
        xml2::read_html() %>%
        rvest::html_table() %>%
        first()

      # Colnames hardcoded, should update this to parse the header on page:
      colnames(collar_df) = c('Name', 'ID', 'LatestFix', 'GPS', 'Sen', 'Alrt', 'Prx')
      return(collar_df)
    },

    get_collar_element_by_id = function(collar_id) {
      collar_xpath = paste0("//td[. ='", collar_id, "']")
      collar_element = self$driver$findElement(using="xpath", collar_xpath)
      return(collar_element)
    },

    scroll_up = function() {
      upbutton_element = self$driver$findElement(
        using="css selector",
        self$upscrollbutton_element_css)
      upbutton_element$clickElement()
    },

    scroll_down = function() {
      downbutton_element = self$driver$findElement(
        using="css selector",
        self$downscrollbutton_element_css)
      downbutton_element$clickElement()
    },

    scroll_to_top = function() {
      top_element = self$collar_element_list[[1]]
      while(top_element$isElementDisplayed() == FALSE) {
        self$scroll_up()
      }
    },

    select_collar_element = function(collar_element) {
      assertthat::assert_that(class(collar_element) == "webElement")
      if(collar_element$isElementSelected() == FALSE) {
        self$scroll_to_top()
        # If collar entry is not visible, scroll down:
        while(collar_element$isElementDisplayed() == FALSE) {
          self$scroll_down()
        }
        collar_element$clickElement()
      }
    },

    # dl_collar_element = function(collar_element) {
    #   assertthat::assert_that(class(collar_element) == "webElement")
    #   self$select_collar_element(collar_element)
    #
    # },

    dl_button_press = function() {
      if(self$driver$getCurrentUrl() != self$data_url) {
        return(FALSE)
      }
      dl_button_element = self$driver$findElement(
        using="id",
        self$downloadbutton_element_id)
      dl_button_element$clickElement()
    },

    # Set start date
    # start date format: [Month] [d], [yyyy]
    set_start_date = function(start_date) {
      startdate_str = format(start_date , self$date_format)
      startdate_element = self$driver$findElement(
        using="id",
        self$startdate_element_id)
      startdate_alter_js = paste0("arguments[0].value = \'", startdate_str, "\';")
      self$driver$executeScript(
        startdate_alter_js,
        args = list(startdate_element))
    },
    get_start_date = function() {
      startdate_element = self$driver$findElement(
        using="id",
        self$startdate_element_id)
      startdate_str = startdate_element$getElementAttribute("value")[[1]]
      return(as.Date(startdate_str, self$date_format))
    },
    set_end_date = function(end_date) {
      enddate_str = format(end_date , self$date_format)
      enddate_element = self$driver$findElement(
        using="id",
        self$enddate_element_id)
      enddate_alter_js = paste0("arguments[0].value = \'", enddate_str, "\';")
      self$driver$executeScript(
        enddate_alter_js,
        args = list(enddate_element))
    },
    get_end_date = function() {
      enddate_element = self$driver$findElement(
        using="id",
        self$enddate_element_id)
      enddate_str = enddate_element$getElementAttribute("value")[[1]]
      return(as.Date(enddate_str, self$date_format))
    },

    set_dl_format = function(dl_format) {
      dloptions_element = self$driver$findElement(
        using="id",
        self$dloptions_element_id)
      dloptions_alter_js = paste0("arguments[0].value = \'", dl_format, "\';")
      self$driver$executeScript(
        dloptions_alter_js,
        args = list(dloptions_element))
    },
    get_dl_format = function() {
      dloptions_element = self$driver$findElement(
        using="id",
        self$dloptions_element_id)
      return(dloptions_element$getElementAttribute("value")[[1]])
    },

    select_collar_by_id = function(collar_id) {
      id = as.numeric(collar_id)
      collar_df = self$get_collar_df()
      if ( !id %in% collar_df$ID) {
        # no such collar id
        return(FALSE)
      }
      collar_idx = match(id, collar_df$ID)
      collar_element = self$collar_element_list[[collar_idx]]
      self$select_collar_element(collar_element)
    },

    clear_log = function(type = "performance") {
      self$driver$log(type)
    },

    get_dl_response = function() {
      logs = self$driver$log(type = "performance")
      logs_json = lapply(logs, function(entry) jsonlite::fromJSON(entry$message) )
      response = logs_json[sapply(logs_json, function(x){
        is.character(x$message$params$response$headers$`Content-Disposition`)
      })] %>% last()
      return(response)
    },

    get_dl_filename = function(path = TRUE) {
      response = self$get_dl_response()
      content_disposition = response$message$params$response$headers$`Content-Disposition`
      filename = sub(".*filename=(.*)","\\1",content_disposition)
      if(path) {
        filename = paste0(self$download_path, "/", filename)
        if ( Sys.info()['sysname'] == "Windows" ) {
          filename = gsub("/", "\\\\", filename)
        }
      }
      return(filename)
    },

    dl_collar = function(collar_id,
                         start_date = self$get_start_date(),
                         end_date = self$get_end_date(),
                         format = self$get_dl_format()) {
      self$select_collar_by_id(collar_id)
      self$set_start_date(start_date)
      self$set_end_date(end_date)
      self$set_dl_format(format)

      # clear log:
      self$clear_log()

      # begin download:
      self$dl_button_press()
      return(self$get_dl_filename())
    }
  )
)

