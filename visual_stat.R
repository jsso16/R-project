# 1단계: 데이터 준비
library(sf)
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./06_geodataframe/06_apt_price.rdata")
load("./07_map/07_kde_high.rdata")
grid <- st_read("./01_code/sigun_grid/seoul.shp")

# 2단계: 관심 지역 그리드 찾기
# install.packages("tmap")
library(tmap)
tmap_mode("view")
tm_shape(grid) + tm_borders() + tm_text("ID", col = "red") +
  tm_shape(raster_high) +
  tm_raster(palette = c("blue", "green", "yellow", "red"), alpha = .4) +
  tm_basemap(server = c("OpenStreetMap"))
