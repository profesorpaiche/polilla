#' Create grid with polygons
#'
#' This function takes each grid from longitude and latitude vectors or a raster
#' image and creates polygons wich later can be used with sf package functions.
#' 
#' @param rtr Raster image from raster package.
#' @param lon Numeric vector with longitude values.
#' @param lat Numeric vector with latitude values.
#' @param type String. If "grid" selected, it will take the values from lon and 
#'  lat to create the polygons. If "raster", it will use the raster dimensions.
#' @param scr Integer. EPSG code for polygons.
#' @param export Logic. Save the polygons in file.
#' @param name String. Name of the file to be exported.
#'
#' @return polygons.
#'
#' @export

gridMaker = function(rtr = NULL, lon = NULL, lat = NULL, 
                     type = "grid", scr = 4326, 
                     export = FALSE, name = "malla.shp") {
	
	# Checking data type 
    # Getting latitude and longitude data

	if (type == "grid") {

		if(is.null(lon) | is.null(lat)) stop("Missing lat and lon data")

		lon[lon > 180] = lon[lon > 180] - 360
		lon = sort(lon)

		lon.res = diff(lon)[1]
		lat.res = diff(lat)[1]
		lon.l = min(lon) - lon.res / 2
		lon.r = max(lon) + lon.res / 2
		lat.d = min(lat) - lat.res / 2
		lat.u = max(lat) + lat.res / 2

	} else if (tipo == "raster") {

		if (class(rtr) != "RasterLayer") stop("Data is not RasterLayer class")

		lon.res = raster::xres(rtr)
		lat.res = raster::yres(rtr)
		lon.l = raster::xmin(rtr)
		lon.r = raster::xmax(rtr)
		lat.d = raster::ymin(rtr)
		lat.u = raster::ymax(rtr)

		lon.l[lon.l > 180] = lon.l[lon.l > 180] - 360
		lon.r[lon.r > 180] = lon.r[lon.r > 180] - 360

		lon = seq(lon.l + lon.res/2, lon.r - lon.res/2, lon.res)
		lat = seq(lat.d + lat.res/2, lat.u - lat.res/2, lat.res)

	}

	# Making grid

	esquinas = c(
        lon.l, lat.u, 
        lon.r, lat.u, 
        lon.r, lat.d, 
        lon.l, lat.d, 
        lon.l, lat.u
        ) 

	malla_gri = 
        matrix(
			esquinas,
			byrow = TRUE, 
			ncol = 2
            ) %>%
		list() %>%
		sf::st_polygon() %>%
		sf::st_sfc(crs = scr)
	
	malla = 
        sf::st_make_grid(
			malla_gri, 
			n = c( lengths(list(lon,lat)) ),
			crs = scr,
			what = 'polygons'
            ) %>%
		sf::st_sf(
			"geometry" = .,
			data.frame(
				"ID" = 1:length(.),
				"lon" = rep(lon, times = length(lat)),
				"lat" = rep(lat, each = length(lon))
			    )
		    ) 

    # Export grid

	if (export) sf::st_write(malla, name)

	return(malla)

}
