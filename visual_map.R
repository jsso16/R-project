# 1단계: 데이터 준비
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./06_geodataframe/06_apt_price.rdata")
load("./07_map/07_kde_high.rdata")
load("./07_map/07_kde_hot.rdata")

library(sf)
bnd <- st_read("./01_code/sigun_bnd/seoul.shp")
grid <- st_read("./01_code/sigun_grid/seoul.shp")

# 2단계: 마커 클러스터링 옵션 설정
pnct_10 <- as.numeric(quantile(apt_price$py, probs = seq(.1, .9, by = .1))[1])
pnct_90 <- as.numeric(quantile(apt_price$py, probs = seq(.1, .9, by = .1))[9])
load("./01_code/circle_marker/circle_marker.rdata")
circle.colors <- sample(x=c("red", "green", "blue"), size=1000, replace=TRUE)

# 3단계: 마커 클러스터링 시각화
# install.packages("purrr")
library(purrr)
leaflet() %>%
  addTiles() %>%
  addPolygons(data = bnd, weight = 3, color = "red", fill = NA) %>%
  addRasterImage(raster_high,
                 colors = colorNumeric(c("blue", "green", "yellow", "red"), values(raster_high), 
                                       na.color = "transparent"), opacity = 0.4, group = "2021 최고가") %>%
  addRasterImage(raster_hot,
                 colors = colorNumeric(c("blue", "green", "yellow", "red"), values(raster_hot), 
                                       na.color = "transparent"), opacity = 0.4, group = "2021 급등지") %>%
  addLayersControl(baseGroups = c("2021 최고가", "2021 급등지"),
                   options = layersControlOptions(collapsed = FALSE)) %>%
  addCircleMarkers(data = apt_price, lng = unlist(map(apt_price$geometry, 1)),
                   lat = unlist(map(apt_price$geometry, 2)), radius = 10, stroke = FALSE,
                   fillOpacity = 0.6, fillColor = circle.colors, weight = apt_price$py,
                   clusterOptions = markerClusterOptions(iconCreateFunction=JS(avg.formula)))
rm(list = ls())
