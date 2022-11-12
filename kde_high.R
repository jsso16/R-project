# 1단계: 실거래 + 그리드 데이터 결합
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./06_geodataframe/06_apt_price.rdata")
library(sf)
grid <- st_read("./01_code/sigun_grid/seoul.shp")
apt_price <- st_join(apt_price, grid, join = st_intersects)
head(apt_price, 2)

# 그리드별 평균 가격(평당) 계산
kde_high <- aggregate(apt_price$py, by=list(apt_price$ID), mean)
colnames(kde_high) <- c("ID", "avg_price")
head(kde_high, 2)

# 2단계: 그리드 + 평균 가격 결합
kde_high <- merge(grid, kde_high, by="ID")
# install.packages("ggplot2")
library(ggplot2)
library(dplyr)
kde_high %>% ggplot(aes(fill = avg_price)) +
                    geom_sf() +
                    scale_fill_gradient(low = "white", high = "red")

# 3단계: sp형으로 변환과 그리드별 중심 좌표 추출
library(sp)
kde_high_sp <- as(st_geometry(kde_high), "Spatial")
x <- coordinates(kde_high_sp)[,1]
y <- coordinates(kde_high_sp)[,2]

# 기준 경계 설정
l1 <- bbox(kde_high_sp)[1, 1] - (bbox(kde_high_sp)[1, 1] * 0.0001)
l2 <- bbox(kde_high_sp)[1, 2] + (bbox(kde_high_sp)[1, 2] * 0.0001)
l3 <- bbox(kde_high_sp)[2, 1] - (bbox(kde_high_sp)[2, 1] * 0.0001)
l4 <- bbox(kde_high_sp)[2, 2] + (bbox(kde_high_sp)[2, 2] * 0.0001)

# 지도 경계선 그리기
# install.packages("spatstat")
library(spatstat)
win <- owin(xrange=c(l1, l2), yrange=c(l3, l4))
plot(win)
rm(list = c("kde_high_sp", "apt_price", "l1", "l2", "l3", "l4"))

# 4단계: 밀도 그래프 표시하기
p <- ppp(x, y, window = win)
d <- density.ppp(p, weights = kde_high$avg_price,
                 sigma = bw.diggle(p),
                 kernel = "gaussian")
plot(d)
rm(list = c("x", "y", "win", "p"))

# 5단계: 노이즈 제거와 래스터 이미지로 변환
d[d < quantile(d)[4] + (quantile(d)[4] * 0.1)] <- NA
# install.packages("raster")
library(raster)
raster_high <- raster(d)
plot(raster_high)

# 6단계: 서울시 외곽선 자르기
bnd <- st_read("./01_code/sigun_bnd/seoul.shp")
raster_high <- crop(raster_high, extent(bnd))
crs(raster_high) <- sp::CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
plot(raster_high)
plot(bnd, col = NA, border = "red", add = TRUE)

# 7단계: 지도 위에 래스터 이미지 올리기
# install.packages("rgdal")
library(rgdal)
library(leaflet)
leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = bnd, weight = 3, color = "red", fill = NA) %>%
  addRasterImage(raster_high,
                 colors = colorNumeric(c("blue", "green", "yellow", "red"),
                                       values(raster_high), na.color = "transparent"), opacity = 0.4)

# 8단계: 저장하기
dir.create("07_map")
save(raster_high, file="./07_map/07_kde_high.rdata")
rm(list = ls())
