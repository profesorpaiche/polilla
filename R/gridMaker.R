#' Create grid with polygons
#'
#' This function takes each grid from longitude and latitude vectors or a raster
#' image and creates polygons wich later can be used with sf package functions.
#'
#' @param grid Raster image or points (in a grid configuration, from lower-left
#'  to uper-right).
#' @param crs Integer or String. EPSG code or PROJ4 string for polygons.
#' @param export Logic. Save the polygons in file.
#' @param name String. Name of the file to be exported.
#'
#' @return Grid as polygons
#'
#' @export

gridMaker = function(grid, crs = 4326, export = FALSE, name = "malla.shp") {
    # Getting corners of the boundary arean and number of grids cells
    type = class(grid)
    if (any(type == "sfc_POINT")) {
        ndims = dimensionSize(grid)
        nc = ndims[1] * ndims[2]
        grid_df = grid |> sf::st_coordinates() |> as.data.frame()
        lon_res = grid_df$X[2] - grid_df$X[1]
        lat_res = grid_df$Y[ndims[1] + 1] - grid_df$Y[1]
        lon_l = grid_df$X[1] - lon_res / 2
        lon_r = grid_df$X[nc] + lon_res / 2
        lat_d = grid_df$Y[1] - lat_res / 2
        lat_u = grid_df$Y[nc] + lat_res / 2
    } else if (type == "raster") {
        # FIXME: There should be a better way to obtain the dimension size
        lon_res = raster::xres(grid)
        lat_res = raster::yres(grid)
        lon_l = raster::xmin(grid)
        lon_r = raster::xmax(grid)
        lat_d = raster::ymin(grid)
        lat_u = raster::ymax(grid)
        lon_l[lon_l > 180] = lon_l[lon_l > 180] - 360
        lon_r[lon_r > 180] = lon_r[lon_r > 180] - 360
        lon = seq(lon_l + lon_res / 2, lon_r - lon_res / 2, lon_res)
        lat = seq(lat_d + lat_res / 2, lat_u - lat_res / 2, lat_res)
        ndims = c(length(lon), length(lat))
    } else {
        stop("input class must be either 'sfc_POINT' or 'raster'")
    }
    corners = c(
        lon_l, lat_u,
        lon_r, lat_u,
        lon_r, lat_d,
        lon_l, lat_d,
        lon_l, lat_u
    )

    # Create grid polygon
    boundaries = matrix(corners, byrow = TRUE, ncol = 2) |>
        list() |>
        sf::st_polygon() |>
        sf::st_sfc(crs = crs) |>
        sf::st_make_grid(
            n = ndims,
            crs = crs,
            what = "polygons"
        )

    if (any(names(grid) == "id")) {
        ids = dplyr::pull(grid, id)
    } else {
        ids = seq_along(boundaries)
    }
    poly_grid = sf::st_sf(
        "geometry" = boundaries,
        data.frame("id" = ids)
    )
    return(poly_grid)
}

# Finding number of dimensions
dimensionSize = function(points) {
    points = points |>
        sf::st_coordinates() |>
        as.data.frame()
    nlat = diff(points$X)
    nlat = length(nlat[nlat < mean(nlat)]) + 1
    nlon = as.integer(nrow(points) / nlat)
    return(c(nlon, nlat))
}
