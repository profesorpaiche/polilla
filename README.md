# polilla

This little package (just 2 main functions) takes gridded coordinates and finds
all the grids cells that intersects a polygon (like a district). In addition,
it calculates the weights of each grid cell based on how much they intersect
the polygon. This last capability is useful to calculate weighted statistics.

You can install the package with:

```r
devtools::install_github("profesorpaiche/polilla")
```

## Preparing the data

For this example, we will be using some polygons from the Amazon jungle (as
a shape file) and precipitation data from the same place (as a netCDF file). You
can download this sample date from:

https://drive.google.com/file/d/1GoN8CXBNEP4zbLVurGjkDqGnmCjYvB_3/view?usp=sharing

Now, loading the needed packages and data:

```r
library(dplyr)
library(ggplot2)
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
data. The function only works with one polygon. You can use a loop if your
object has more polygons.

```r
# Creating the polygon grid
grid_pol = coord2sf(lon = lon, lat = lat, crs = 4236) |>
    st_crop(mdd)
grid_pol = gridMaker(grid_pol, crs = 4326)
```

## Creating weights

Now we have to intersect the grids (`grid`) with the target polygon (`shp`), this
is easily done with just one function.

```r
weights = getWeights(grid = grid_pol, shp = mdd[1, ])
grid_pol = left_join(grid_pol, weights, by = "ID")
```

## What comes next?

With this, you should have a new netCDF file which has a mask for every polygon
you need to intersect. 

```r
g = ggplot() +
    geom_sf(data = grid_pol, mapping = aes(fill = weights)) +
    geom_sf(data = mdd[1, ], fill = NA)
```

![](mask.png)

This mask can be used with the original netCDF file and get a time series of only
the grids inside on intersecting a polygon if you have a lot of values.
