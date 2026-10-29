#' @title Deprecated R6 HydroShare Client
#' @description 
#' `r lifecycle::badge("deprecated")`
#' 
#' `HSClient` is deprecated and retained only for backward compatibility.
#' It is no longer supported by this package and may return errors.
#' Prefer direct package functions such as [hs_resource()], [hs_files()],
#' and [hs_sysmeta()].
#' @importFrom R6 R6Class
#' @importFrom urltools param_get
#' @importFrom lifecycle badge
#' @export
HSClient <- R6::R6Class("HSClient",
    public = list(
        #' @description
        #' Initialize a HydroShare Client
        #' @return A new `HSClient` object.
        #'
        #' *Note: A message will be issued
        #' since this R6 object is deprecated.*
        initialize = function() {
            rlang::warn(
                paste(
                    "HSClient is deprecated and no longer supported by this package.",
                    "It may return errors.",
                    "Use direct package functions such as hs_resource(), hs_files(),",
                    "and hs_sysmeta() instead."
                )
            )

            rlang::inform(
                crayon::cyan(crayon::bold(paste0(
                    "R6-based client is deprecated.\n",
                    "Use package functions instead."
                )))
            )

            preamble <- crayon::bold(paste0(
                "\n",
                crayon::blue("HS"),
                crayon::green("Client"),
                crayon::blue("R"),
                " - ",
                crayon::red("R6 Client"),
                "\n"
            ))

            msg <- paste0(
                crayon::silver("=======================================\n"),
                "Thanks for using HSClientR! ",
                crayon::red("\u2665"),
                "\nThis R6 client is deprecated.",
                "\nPrefer package functions like ",
                crayon::red("hs_resource()"),
                " and ",
                crayon::red("hs_files()"),
                "\n"
            )

            cat(preamble,
                msg,
                crayon::silver("=======================================\n"),
                sep = "")

            invisible(self)
        },

        #' @description
        #' Print HSClient object
        #' @return `HSClient` output
        print = function() {
            if (!is.null(private$.token)) {
                private$.user_details <- hs_user()

                user_msg <- paste0(
                    "Authenticated as:\n",
                    crayon::bold(crayon::cyan(
                        private$.user_details$first_name,
                        private$.user_details$last_name
                    )),
                    "\n",
                    crayon::bold("User: "), private$.user_details$username, "\n",
                    crayon::bold("ID:   "), private$.user_details$id, "\n",
                    crayon::bold("Org:  "), private$.user_details$organization, "\n"
                )

                res_msg <- paste0(
                    crayon::bold("Last Query ($query): "),
                    private$.query, "\n",
                    crayon::bold("Query Results:\n"),
                    "\tCount: ", nrow(private$.query_results),
                    "\n"
                )

                msg <- paste0(
                    user_msg,
                    crayon::silver("=======================================\n"),
                    res_msg
                )
            } else {
                msg <- paste0(
                    "It looks like you haven't authenticated yet...\n",
                    "Please call ",
                    crayon::red('$authenticate()'),
                    " on this object to get\nOAuth2 authentication set up with ",
                    crayon::bold(crayon::blue("Hydro"), crayon::green("Share"), sep = ""),
                    "! :)",
                    "\n"
                )
            }

            cat(msg)
        },

        #' @description
        #' Perform OAuth2 Authentication
        #' with HydroShare.
        #' @return self, invisibly.
        #' @details
        #' Note, the access token will be set
        #' as a header automatically if `.token`
        #' is `NULL`.
        authenticate = function() {
            if (!is.null(private$.token)) {
                rlang::inform("You are authenticated :)")
            } else {
                private$.token <- hs_auth()

                # Get access token
                creds <- private$.token$credentials %>%
                         names() %>%
                         jsonlite::fromJSON()

                # Apply to all subsequent requests
                httr::set_config(
                    config = httr::add_headers(
                        Authorization = paste("Bearer", creds$access_token)
                    )
                )

                if (!is.null(private$.token)) {
                    private$.authenticated <- TRUE
                    rlang::inform("Authenticated! :)")
                } else {
                    private$.authenticated <- FALSE
                    rlang::warn("Authentication Failed :(")
                }
            }

            invisible(self)
        },

        #' @description
        #' Query/Search HydroShare
        #' @param ... Query parameters. See \link{hs_resource} parameters.
        #' @return R6 object
        query = function(...) {
            parameters <- list(...)
            
            if (identical(parameters, "")) parameters <- "NONE"

            private$.query <- paste0(
                ifelse(nchar(names(parameters)) > 0, paste0(names(parameters), " = "), ""),
                unlist(parameters),
                collapse=", "
            )

            temp_results <- hs_resource(...)

            private$.next_page     <- temp_results$".next"
            private$.prev_page     <- temp_results$".prev"
            private$.query_results <- temp_results$results
            private$.current_resource <- 1

            private$.query_results
        },

        #' @description
        #' Get current resource
        #' @return A [tibble][tibble::tibble-package] of the current resource
        get_res = function() {
            if (is.null(private$.current_resource)) {
                rlang::abort("There is no current resource. Use $query()")
            } else {
                private$.query_results[private$.current_resource, ]
            }
        },

        #' @description
        #' Get next resource
        #' @return Resource tibble. See `$get_res`.
        next_res = function() {
            if (private$.current_resource == nrow(private$.query_results)) {
                rlang::abort("There is no next resource.")
            } else {
                private$.current_resource <- private$.current_resource + 1
                self$get_res()
            }
        },

        #' @description
        #' Get previous resource
        #' @return Resource tibble. See `$get_res`.
        prev_res = function() {
            if (private$.current_resource == 1) {
                rlang::abort("There is no previous resource.")
            } else {
                private$.current_resource <- private$.current_resource - 1
                self$get_res()
            }
        },

        #' @description
        #' Get next search page
        #' @return Query tibble. See `$query`.
        next_page = function() {
            if (is.null(private$.next_page) | is.na(private$.next_page)) {
                rlang::abort("There is no next page.")
            } else {
                do.call(self$query, urltools::param_get(private$.next_page))
            }
        },

        #' @description
        #' Get previous search page
        #' @return Query tibble. See `$query`.
        prev_page = function() {
            if (is.null(private$.prev_page) | is.na(private$.prev_page)) {
                rlang::abort("There is no previous page.")
            } else {
                do.call(self$query, urltools::param_get(private$.prev_page))
            }
        }
    ),
    private = list(
        .user_details = NULL,
        .current_resource = NULL,
        .next_res  = NULL,
        .prev_res  = NULL,
        .next_page = NULL,
        .prev_page = NULL,
        .query = NULL,
        .query_results = NULL,
        .token = NULL,
        .authenticated = NULL
    )
)