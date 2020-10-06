#' Create grid mask for a polygon
#'
#' This function find all the grids that intersect a polygon and calculates the
#' fraction of the grids that are inside of the polygon.
#' 
#' @param grid Grid to be intersected.
#' @param shp Polygons that will be used to intersect the grids.
#' @param key Numeric. Field that will be used to define the dimensions of output
#'  files.
#' @param atrib_c String. Additional field to final table. Only for "list"
#'  format.
#' @param format Strimg. Output format.
#' @param export String. Name of the output file.
#' @param weights String. Name of the file with the weights.
#' @param progress Logic. Turn on progress bar.
#'
#' @return Array for every polygon intersected.
#'
#' @export

maskMaker = function(grid, shp, 
                     format = "array", 
                     key = NULL, atrib_c = NULL, 
                     export = NULL, 
                     weights = NULL, 
                     progress = TRUE) {

	# Trow error if "lon" or "lat" doesn't exist

	cn = colnames(grid)
	if ( !(any(cn == "lon") & any(cn == "lat")) ) {
		stop("Error: variables lon or lat not found")
	} 

	# Area for each grid

	grid = grid %>%
		dplyr::mutate(Area_T = sf::st_area(.) %>% as.numeric())
	
	# Defining output type

	if (format == "array") {

		lon.n = unique(grid$lon) %>% length()
		lat.n = unique(grid$lat) %>% length()
		mascara = array(0, c(lon.n, lat.n, nrow(shp)))

	} else if (format == "list") {

		mascara = list()

	} else {

		stop("Invalid format")

	}
	
    # Mask for polygon to be intersect

	total = nrow(shp)
	if (progress) pb = txtProgressBar(min = 0, max = total, style = 3)
	ps = c()

	for (i in 1:total) {
	
		shp_sel = shp[i, ]
		
        # Intersect and calculate the fraction of the grid

		oldw = getOption("warn")
		options(warn = -1)

		inters = 
            suppressMessages(suppressWarnings(
				sf::st_intersection(grid, shp_sel)
			))
		#inters = suppressMessages(sf::st_intersection(grid, shp_sel)) %>%
		inters = inters %>%
			dplyr::mutate(
				Area_P = sf::st_area(.) %>% as.numeric(),
				Frac = round(Area_P/Area_T, 3)
            )
		
		options(warn = oldw)

        # Atribute table (1/2)

		inters_tab = inters %>%
			dplyr::as_tibble() %>%
			dplyr::select(ID:lat, Frac)

        # Weights

		ps[i] = sum(inters_tab$Frac)

        # Atribute table (2/2)

		if (!is.null(atrib_c)) {

			inters_new = dplyr::as_tibble(inters)
			inters_new = inters_new[ ,atrib_c]
			inters_tab = cbind(inters_tab, inters_new)
			inters_tab$Peso = ps[i]

		}

        # Output object

		if (format == "array") {

			mask = numeric(lon.n * lat.n)
			mask[inters_tab$ID] = inters_tab$Frac
			mascara[ , ,i] = matrix(
				mask, 
				nrow = lon.n, 
				ncol = lat.n, 
				byrow = F
			)

		} else if (format == "list"){

			mascara[[i]] = inters_tab

		}

		if (progress) setTxtProgressBar(pb, i)
	
	}

    # Export weigth table

	if (!is.null(weights)) {

		shp_tab = as.data.frame(shp[ ,atrib_c]) %>%
			mutate(Peso = ps) %>%
			dplyr::select(-geometry) %>%
			as_tibble()

		write.csv(shp_tab, name_peso, row.names = FALSE)

	}
	
    # Output file as netCDF

	if (!is.null(export) & format == "array" & !is.null(key)) {

		# Definiendo dimensiones y variables
		key.val = as.data.frame(shp)[ ,key]
		londim = ncdim_def("lon", "degrees_east_west", unique(grid$lon))
		latdim = ncdim_def("lat", "degrees_north", unique(grid$lat))
		disdim = ncdim_def(key, key, as.integer(key.val),
			longname = 'Field used in intersection')
		
		fillmissval = -999.9
		
		mask_def = ncvar_def(
			name = "mask",
			units = "fraction",
			dim = list(londim, latdim, disdim),
			missval = fillmissval, 
			longname = "Mask"
        )

		peso_def = ncvar_def(
			name = "weight",
			units = "proportion",
			dim = list(disdim),
			missval = fillmissval,
			longname = "Weights of each polygon based on intersected grids"
        )
		
		ncout = nc_create(
			filename = export,
			vars = list(mask_def, peso_def),
			force_v4 = T
        )
		
		ncvar_put(
			nc = ncout,
			varid = mask_def,
			vals = mascara
        )

		ncvar_put(
			nc = ncout,
			varid = peso_def,
			vals = ps
        )
		
		nc_close(ncout)
		
	}

	return(mascara)

}
