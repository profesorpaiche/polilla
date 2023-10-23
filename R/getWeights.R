#' Create grid mask for a polygon
#'
#' This function calculates the weight for each cell with respect to the area
#'  that intersects with a polygon.
#'
#' @param grid Grid (as polygons) to be intersected.
#' @param shp Polygons that will be used to intersect the grids.
#'
#' @return Weight for each cell index. NA means no intersection.
#'
#' @export

getWeights = function(grid, shp) {
    grid$area_total = sf::st_area(grid) |> as.numeric()
    intersection = sf::st_intersection(grid, shp)
    intersection$area_intersection = sf::st_area(intersection) |> as.numeric()
    intersection = intersection |>
        dplyr::mutate(
            area_fraction = area_intersection / area_total,
            weights = area_fraction / sum(area_fraction)
        ) |>
        as.data.frame() |>
        dplyr::select(ID, weights)
    return(intersection)
}
