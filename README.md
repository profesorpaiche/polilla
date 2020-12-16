# polilla

This little package (just 2 functions) takes gridded data and finds all 
the grids that intersects a polygon. Also, it calculates the fraction of the grid
that is inside of the polygon.

You can install the package with:

```r
devtools::install_github("profesorpaiche/polilla")
```

## Preparing the data

For this example, we will be using some polygons from the Amazon jungle (as
a shape file) and precipitation data from the same place (as a netCDF file). You
can download this sample date from:

link

Now, loading the needed packages and data:

```r
library(dplyr)
library(sf)
library(ncdf4)
library(polilla)

# Polygons
mdd = st_read("mdd.shp", quiet = TRUE)

# Gridded data
gpm_nc = nc_open("3B-DAY-L.MS.MRG.3IMERG.20200101.nc4")
lon = ncvar_get(gpm_nc, "lon")
lat = ncvar_get(gpm_nc, "lat")
nc_close(gpm_nc)

```

## Create the grid

The first step is to create a grid of polygons from the original gridded data.
This is done in order for our principal polygons can interact with the gridded
data. 

```r
# Creating the polygon grid
grid_pol = gridMaker(lon = lon, lat = lat)
```

## Create the mask

Now we have to intersect the grids (`grid`) with the target polygon (`shp`), this
is easily done with just one function. Here we are only using one polygon, but it
is possible to use all the available polygons, just keep in mind that it would
take some time until it finishes and that it takes more time with a bigger
polygon.

We are also exporting the output as a netCDF and a table with a summary of the
weights of each target polygon. In the netCDF file there is a dimension that uses
the `key` parameter to create different mask for every polygon intersected. The
`atrib_c` parameter has a series of columns from the original polygon that will
be exported in the weights file.

```r
mask = maskMaker(
    grid = grid_pol, 
    shp = mdd[1, ],
    key = "IDDIST", 
    atrib_c = c("IDDIST", "DEPARTAMEN", "PROVINCIA", "DISTRITO"),
    export = "gebco_mdd_masked.nc",
    weights = "gebco_mdd_weights.csv")
```

## What comes next?

With this, you should have a new netCDF file which has a mask for every polygon
you need to intersect. 

```r

# Limiting the data in the area we are working
mdd_lim = st_bbox(mdd)
lon_sel = lon >= mdd_lim$xmin & lon <= mdd_lim$xmax
lat_sel = lat >= mdd_lim$ymin & lat <= mdd_lim$ymax
lon_new = lon[lon_sel]
lat_new = lat[lat_sel]
mask_new = mask[lon_sel, lat_sel, 1]
mask_new[mask_new == 0] = NA

# Ploting the mask
image(x = lon_new, y = lat_new, z = mask_new)
plot(mdd$geometry, add = TRUE)

```

![](mask.png)

_Uggg thats an ugly image, I will improve it!_

This mask can be used with the original netCDF file and get a time series of only
the grids inside on intersecting a polygon if you have a lot of values.

## Why this package?

BECAUSE I NEEDED IT AND DIDN'T FIND ANY SOLUTION :(

Managing spatial data in R its not too hard, but when you are dealing with many
different formats (matrices and polygons in my case) you just want to kill
yourself. The main reason for me to use this package is to extract a time series
for a specific region (like a district, or 1873 districts) that is in a matrix
like format (raster or netCDF).

