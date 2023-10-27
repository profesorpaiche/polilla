#' Get extra bbox area for sf::st_crop
#'
#' This function expands the st_crop boundary box by an specific amount. It is
#'  useful if you want to construct a grid from just points. If you happen to
#'  use only st_crop, you cannot get the full area that the grid would cover
#'  because the crop would only reach the center of the grid. By adding thi
#'  "specific amount" (half of the spatial resolution), all the grid area will
#'  be covered.
#'
#' @param target The target grid centroids.
#' @param reference Reference polygon used for the cropping.
#'
#' @return bbox
#'
#' @export

st_crop_extra = function(target, reference) {
    reference_bbox = sf::st_bbox(reference)
    target_crop_ini = sf::st_crop(target, reference_bbox)
    id = target_crop_ini[1, ] |> dplyr::pull(ID)
    target_df = target |>
        sf::st_coordinates() |>
        as.data.frame()
    ndims = dimensionSize(target)
    xres = target_df$X[id + 1] - target_df$X[id]
    yres = target_df$Y[id + ndims[1]] - target_df$Y[id]
    reference_bbox_new = reference_bbox + c(-xres / 2, -yres / 2, xres / 2, yres / 2)
    target_crop = sf::st_crop(target, reference_bbox_new)
    return(target_crop)
}
