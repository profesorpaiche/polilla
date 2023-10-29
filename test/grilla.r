library(dplyr)
library(sf)
library(ncdf4)
library(ggplot2)
library(maps)

source("../R/gridMaker.R")
source("../R/sfCoords.R")
source("../R/getWeights.R")
source("../R/st_crop_extra.R")

# Reprojection information
grid_north_pole_latitude = 39.25
grid_north_pole_longitude = -162
lat_center = 90 - grid_north_pole_latitude # displacement from the north
lon_center = grid_north_pole_longitude + 180 # displacement from the east
crs_ortho = paste0("+proj=ortho +lat_0=", lat_center, " +lon_0=", lon_center)

# Shapefiles
shp = "~/data/shapes/germany/vg250_ebenen_1231/VG250_VWG.shp" |>
    st_read(
        quiet = TRUE,
        query = "SELECT GEN, GF FROM \"VG250_VWG\""
    ) |>
    filter(GEN == "Hamburg", GF == 4) |>
    st_transform(crs = crs_ortho)

# Ncdf file
nc = nc_open("cordex.nc")
lon = ncvar_get(nc, "lon")
lat = ncvar_get(nc, "lat")

# Testing sfCoords
lonlat_sf = sfCoords(lon = lon, lat = lat, crs = 4326) |>
    st_transform(crs = crs_ortho)

# Testing extended crop
lonlat_sf = extraCrop(lonlat_sf, st_bbox(shp))

# Testing gridMaker
malla_gri = gridMaker(lonlat_sf, crs = crs_ortho)

# Testing getWeights
intersection = getWeights(malla_gri, shp)
grid = left_join(malla_gri, intersection, by = "id")

# test plot
g = ggplot() +
    geom_sf(data = grid, mapping = aes(fill = weights)) +
    geom_sf(data = shp, fill = NA) +
    geom_sf(data = malla_gri |> st_centroid()) +
    geom_sf(data = lonlat_sf, color = "brown")
