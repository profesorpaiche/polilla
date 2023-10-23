#' Convert coordinates to sfc_POINTS
#'
#' This function converts normal coordinates in a grid configuration to
#'  to sfc_POINTS type. Keep in mind that the first grid should be the
#'  lower-left and the last one the upper-right (increasing longitude and
#'  latitude).
#'
#' @param lon Numeric matrix with the longitude of each point
#' @param lat Numeric matrix with the latitude of each point
#' @param crs Integer or String. EPSG code or PROJ4 string of the points
#'
#' @return points as sfc_POINTS
#'
#' @export

coords2sf = function(lon, lat, crs) {
    ndims = length(dim(lon))
    if (ndims == 1) {
        lonlat = expand.grid(lon = c(lon), lat = c(lat), KEEP.OUT.ATTRS = FALSE) |>
            as.data.frame()
    } else if (ndims == 2) {
        lonlat = data.frame(lon = c(lon), lat = c(lat))
    } else {
        stop("coordinates have more than 2 dimensions")
    }

    lonlat_sf = lonlat |>
        sf::st_as_sf(coords = c("lon", "lat")) |>
        sf::st_geometry() |>
        sf::st_sfc(crs = crs)
    return(lonlat_sf)
}
