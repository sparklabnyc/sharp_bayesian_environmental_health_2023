# File: STR_1_plotOneParameterSpatial.R
# Author: Sebastian T. Rowland <sr3463@cumc.columbia.edu>
# Date: 12/21/2021

# note: this code is designed to handle just one time point, but can handle BNE
# outputs from any version

#' \code{plotOneParameterSpatial} makes a plot of a single parameterName, typically from
#' a BNE run. The parameterName could be, for example the weight of a particular model,
#' or the predictive uncertainty. The code can also accept base model predictions,
#' AQS observations, disagreement among base models, etc. A key feature is that
#' the user can set the legend scale and break to ensure consistent plotting across plots.
#'
#' @param dta The dataset containing the parameterName we will plot. Must have columns
#' for lat and lon. Typical dta is the dataset of BNE PPD parameterName summaries.
#' An upcoming version could include option to average spatiotemporal dataset.
#' @param parameterName A string of the parameterName of interest, such as 'w_mean_av'
#' for the mean of the weight of the av base model. Valid names follow this pattern:
#' {[parameter] _ [metric] _ [base model]} Some possible parameterName names are:
#' w (weight)
#' ens (core ensemble; the model combination from BNE)
#' res (residual process)
#' pred (predicted variable; the dependent variable in the model)
#' for w, ens, res, and pred, metrics can be 'mean' or 'sd.' For now, pred can also
#' have metrics '05CI', '95CI', 'min', 'max', and 'median'.
#' @param valueScale A vector containing the values to be used as break points for
#' the legend and color scheme. If a valueScale is not provided, then the function
#' will calculate breakpoints from just the values in the dataset.
#' @param legYN A string determining whether to include a legend.
#' Default is to include a legend. Possible values are 'legY' and 'legN'.
#' @param legTitle The title of the legend. 'default legendTitle' means the function
#' will use the pre-set legend title based on the parameterName name
#' @param mainTitle The title of the plot. 'default mainTitle' means the function
#' will use the pre-set title based on the parameterName name. " " will yield a blank title
#' @param extraPointObj An optional dataframe with additional points to plot, e.g, AQS monitors.
#' Must have lat and lon columns. Color chosen based on parameterName
#' @param borderObj An optional simple features object of a border for the plot.
#' Color chosen based on parameterName name
#' @param pointSize The size of the points. Can adjust this to increase resolution
#' @param pointShape Shape of the points. Pretty much always circles;
#' the rectangles look even worse
#'
#' @return A ggplot object that can be printed as a png, pdf, etc.
#'
#' #' @seealso \code{\link{readBNEoutput}}
#'
#' @export
#' @importFrom magrittr %>%

plotOneParameterSpatial <- function(
    dta,
    parameterName,
    valueScale = "unique scale",
    legYN = "legY",
    legTitle = "default legendTitle",
    mainTitle = "default mainTitle",
    extraPointObj = "noExtraPoints",
    borderObj = "noBorder",
    pointSize = 0.9,
    pointShape = 21,
    titleSize = 10) {
  #--------------------------#
  #### 0. example values: ####
  #--------------------------#

  # dta <- bne.out
  # parameterName <- 'res_mean';  legYN <- 'LegY'
  #   titleYN = 'titleY'; valueScale = valueVec.SD
  # parameterName <- 'pred_sd'; legYN <- 'LegY'

  #-------------------------------#
  #### 1. wrangle BNE outputs: ####
  #-------------------------------#

  # 1a. Rename the parameterName of interest
  dta <- dta %>%
    dplyr::rename(p := !!parameterName)

  # 1b. Convert to  simple feature
  dta <- dta %>%
    sf::st_as_sf(coords = c("lon", "lat"), crs = sf::st_crs("epsg:4326"))

  # 1c. Transform geographical coordinates to Albers Projection
  dta <- dta %>%
    sf::st_transform(crs = sf::st_crs(projCRS))

  # 1d. extract the name of the base model, if relevant
  if (stringr::str_detect(parameterName, "w_mean") |
    stringr::str_detect(parameterName, "w_sd") |
    stringr::str_detect(parameterName, "w_dist") |
    stringr::str_detect(parameterName, "contrib")) {
    baseModel <- stringr::str_split_fixed(parameterName, "_", 3)[3]
  }

  #--------------------------------#
  #### 2. create plot elements: ####
  #--------------------------------#

  #--------------------------#
  #### 2A. create titles: ####
  #--------------------------#

  # 2A.a create default titles
  # we only use these if the user does not define a title
  if (stringr::str_detect(parameterName, "w_mean")) {
    legTitle.default <- "Weight"
    mainTitle.default <- paste0("Weight of ", baseModel)
  } else if (stringr::str_detect(parameterName, "w_sd")) {
    legTitle.default <- "Weight SD"
    mainTitle.default <- paste0("SD of ", baseModel, " Weight")
  } else if (stringr::str_detect(parameterName, "contrib_sd")) {
    legTitle.default <- "Contribution SD"
    mainTitle.default <- paste0("SD of ", baseModel, " Contribution")
  } else if (stringr::str_detect(parameterName, "w_dist")) {
    legTitle.default <- "Dist from Prior"
    mainTitle.default <- paste0("Distance of ", baseModel, " Weight from Prior")
  } else if (parameterName == "ens_mean") {
    legTitle.default <- expression(atop(atop(" ", "Model"), atop(
      "Combination",
      "(" * mu * g / m^3 * ")"
    )))
    mainTitle.default <- "Model Combination"
  } else if (parameterName == "ens_sd") {
    legTitle.default <- expression(atop(atop(" ", "SD of Model"), atop(
      "Combination",
      "(" * mu * g / m^3 * ")"
    )))
    mainTitle.default <- "Sd of Model Combination"
  } else if (parameterName == "res_mean" | parameterName == "rp_mean") {
    legTitle.default <- expression(atop(atop(" ", "Residual"), atop(
      "Process",
      "(" * mu * g / m^3 * ")"
    )))
    mainTitle.default <- "Residual Process"
  } else if (parameterName == "res_sd" | parameterName == "rp_sd") {
    legTitle.default <- expression(atop(atop(" ", "SD of Residual"), atop(
      "Process",
      "(" * mu * g / m^3 * ")"
    )))
    mainTitle.default <- "SD of Residual Process"
  } else if (parameterName == "pred_mean" | parameterName == "y_mean" |
    stringr::str_detect(parameterName, "pred_")) {
    legTitle.default <- expression(atop(
      atop(" ", "Predicted"),
      atop("PM"[2.5], "(" * mu * g / m^3 * ")")
    ))
    mainTitle.default <- expression("Predicted" ~ "Concentration" ~ "of" ~ "PM"[2.5])
  } else if (parameterName == "pred_sd" | parameterName == "y_sd") {
    legTitle.default <- expression(atop(
      atop(" ", "PM"[2.5]),
      atop("SD", "(" * mu * g / m^3 * ")")
    ))
    mainTitle.default <- expression("Uncertainty" ~ "of" ~ "PM"[2.5] ~ "Predictions")
  } else if (parameterName == "base_model_sd") {
    legTitle.default <- expression(atop(
      atop(" ", "PM"[2.5]),
      atop("SD", "(" * mu * g / m^3 * ")")
    ))
    mainTitle.default <- expression("Disagreement" ~ "of" ~ "PM"[2.5] ~ "Models")
  } else if (parameterName == "base_maxW") {
    legTitle.default <- expression(atop("Highest", "Weighted Model"))
    mainTitle.default <- "Highest-Weighted Base Model"
  } else if (parameterName == "pred_sd_scaled" | parameterName == "y_sd_scaled") {
    legTitle.default <- "Uncertainty"
    mainTitle.default <- "Scaled Uncertainty"
  } else if (parameterName == "obs") {
    legTitle.default <- expression(atop(
      atop(" ", "Measured"),
      atop("PM"[2.5], "(" * mu * g / m^3 * ")")
    ))
    mainTitle.default <- expression("Measured" ~ "Concentration" ~ "of" ~ "PM"[2.5])
  } else if (stringr::str_detect(parameterName, "err_")) {
    legTitle.default <- expression(atop("Error", "(" * mu * g / m^3 * ")"))
    mainTitle.default <- "Error"
  } else if (stringr::str_detect(parameterName, "rmse_")) {
    legTitle.default <- expression(atop("RMSE", "(" * mu * g / m^3 * ")"))
    mainTitle.default <- "RMSE"
  } else if (stringr::str_detect(parameterName, "me_")) {
    legTitle.default <- expression(atop("Mean Error", "(" * mu * g / m^3 * ")"))
    mainTitle.default <- "Mean Error"
  } else {
    legTitle.default <- parameterName
    mainTitle.default <- parameterName
  }

  # 2A.b. set the titles we will use for the plot
  if (legTitle == "default legendTitle") {
    legTitle <- legTitle.default
  } else if (legTitle == "pred_pm25") {
    legTitle <- expression(atop(
      atop(" ", "Predicted"),
      atop("PM"[2.5], "(" * mu * g / m^3 * ")")
    ))
  }
  if (mainTitle == "default mainTitle") {
    mainTitle <- mainTitle.default
  }

  # 2A.c. set legend position
  if (legYN == "legY") {
    legPos <- "right"
  }
  if (legYN == "legN") {
    legPos <- "none"
  }

  #----------------------------------#
  #### 2B. get values for legend: ####
  #----------------------------------#

  # 2B.a. extract the values from the dataset, if appropriate
  # unique scale means we get a scale specific for this parameterName, for this bne run
  # for w_mean we usually want the potential min (0) and potential max (1)
  if (valueScale[1] == "unique scale") {
    p.min <- cap_tenth(min(dta$p, na.rm = TRUE), "floor")
    p.max <- cap_tenth(max(dta$p), "ceiling")
    if (stringr::str_detect(parameterName, "w_mean")) {
      p.min <- 0
      p.max <- 1
    }
    p.breaks <- c(
      p.min,
      round(p.min + 0.25 * (p.max - p.min), 2),
      round(p.min + 0.50 * (p.max - p.min), 2),
      round(p.min + 0.75 * (p.max - p.min), 2),
      p.max
    )
  }

  # 2B.b. otherwise, grab the values the user provided
  if (valueScale[1] != "unique scale") {
    # valueScale is a set of inputs you provide. ValueScale should have a length of 5.
    p.min <- min(valueScale)
    p.max <- max(valueScale)
    p.breaks <- valueScale
  }

  # 2B.c add zero if appropriate
  # if (p.min < 0) {
  # p.breaks <- sort(c(0, p.breaks), decreasing = FALSE)
  # }

  #---------------------------------#
  #### 2C. set aesthetic schemes: ####
  #----------------------------------#

  # 2C.a Set the aesthetic schemes
  # at the bottom we have the defaul coloring schemes,
  # which is viridis for positive-only parameters and
  # and red (negative), white (zero), and blue (positive) for parameters that go negative
  # we also set the colors for the extra points and border
  if (stringr::str_detect(parameterName, "w_mean") |
    stringr::str_detect(parameterName, "w_sd")) {
    fillScheme <- viridis::scale_fill_viridis(
      direction = -1,
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    colorScheme <- viridis::scale_color_viridis(
      direction = -1,
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    extraPointCol <- "black"
    borderCol <- "black"
  } else if (parameterName == "rp_mean") {
    fillScheme <- ggplot2::scale_fill_gradient2(
      low = "red", mid = "white", high = "blue", midpoint = 0,
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    colorScheme <- ggplot2::scale_color_gradient2(
      low = "red", mid = "white", high = "blue", midpoint = 0,
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    extraPointCol <- "black"
    borderCol <- "black"
  } else if (parameterName == "y_mean" |
    stringr::str_detect(parameterName, "pred_") |
    parameterName == "obs") {
    fillScheme <- scico::scale_fill_scico(
      direction = -1, palette = "hawaii", trans = "sqrt",
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    colorScheme <- scico::scale_color_scico(
      direction = -1, palette = "hawaii", trans = "sqrt",
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    extraPointCol <- "black" #' orchid'
    borderCol <- "black" #' orchid'
  } else if (parameterName == "ens_sd" |
    parameterName == "rp_sd" |
    parameterName == "y_sd" |
    parameterName == "y_sd_scaled") {
    fillScheme <- viridis::scale_fill_viridis(
      direction = -1, option = "magma", trans = "log",
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    colorScheme <- viridis::scale_color_viridis(
      direction = -1, option = "magma", trans = "log",
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    extraPointCol <- "steelblue4"
    borderCol <- "steelblue4"
  } else if (parameterName == "residu") {
    fillScheme <- scico::scale_fill_scico(
      direction = -1, palette = "vik", midpoint = 0,
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    colorScheme <- scico::scale_color_scico(
      direction = -1, palette = "vik", midpoint = 0,
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    extraPointCol <- "orchid"
    borderCol <- "black"
  } else if (parameterName == "base_maxW") {
    cbp1 <- c(
      "#E69F00", "#56B4E9", "#009E73",
      "#F0E442", "#0072B2", "#D55E00", "#CC79A7"
    )
    fillScheme <- ggplot2::scale_fill_manual(values = cbp1)
    colorScheme <- ggplot2::scale_color_manual(values = cbp1)
  } else if (p.min >= 0) {
    fillScheme <- viridis::scale_fill_viridis(
      direction = -1, option = "magma",
      breaks = c(p.breaks),
      limits = c(0, p.max)
    )
    colorScheme <- viridis::scale_color_viridis(
      direction = -1, option = "magma",
      breaks = c(p.breaks),
      limits = c(0, p.max)
    )
    extraPointCol <- "steelblue4"
    borderCol <- "steelblue4"
  } else if (p.min < 0) {
    fillScheme <- ggplot2::scale_fill_gradient2(
      low = "red", mid = "white", high = "blue", midpoint = 0,
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    colorScheme <- ggplot2::scale_color_gradient2(
      low = "red", mid = "white", high = "blue", midpoint = 0,
      breaks = c(p.breaks),
      limits = c(p.min, p.max)
    )
    extraPointCol <- "black"
    borderCol <- "black"
  }

  #-----------------------#
  #### 3. create plot: ####
  #-----------------------#

  # 3a. make gg object for any extra points
  if (is.data.frame(extraPointObj)) {
    extraPointObj <- extraPointObj %>%
      sf::st_as_sf(coords = c("lon", "lat"), crs = sf::st_crs("epsg:4326")) %>%
      sf::st_transform(crs = sf::st_crs(projCRS))
    extraPoint.gg <- ggplot2::geom_sf(
      data = extraPointObj, fill = extraPointCol,
      color = extraPointCol, size = pointSize
    )
  } else {
    extraPoint.gg <- ggplot2::labs(x = "", y = "")
  }

  # 3b. make gg object for any border
  if (!is.character(borderObj)) {
    border.gg <- ggplot2::geom_sf(data = borderObj, fill = NA, color = borderCol)
  } else {
    border.gg <- ggplot2::labs(x = "", y = "")
  }

  # I don't think we need this
  # if(parameterName != 'base_maxW') {
  guideScheme <- ggplot2::guides(
    fill = guide_colorbar(title = legTitle),
    color = guide_colorbar(title = legTitle)
  )
  # } else {
  #  guideScheme <- ggplot2::labs(x='', y='')
  # }

  # 3c. create plot object
  p.gg <- ggplot2::ggplot() +
    ggplot2::geom_sf(fill = NA) +
    ggplot2::geom_sf(
      data = dta, aes(fill = p, color = p),
      size = pointSize, shape = pointShape
    ) +
    extraPoint.gg +
    border.gg +
    fillScheme +
    colorScheme +
    guideScheme +
    ggplot2::ggtitle(mainTitle) +
    ggplot2::labs(x = "", y = "") +
    ggplot2::theme(plot.margin = unit(c(0, 0, 0, 0), "cm")) +
    ggplot2::theme_void() +
    ggplot2::theme(
      legend.position = legPos,
      legend.title = element_text(size = 19),
      legend.text = element_text(size = 14),
      title = element_text(size = titleSize)
    )

  # 3d. return plot
  print(p.gg)
}
