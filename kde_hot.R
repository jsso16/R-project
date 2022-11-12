# 1단계: 데이터 준비
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./06_geodataframe/06_apt_price.rdata")
grid <- st_read("./01_code/sigun_grid/seoul.shp")
apt_price <- st_join(apt_price, grid, join = st_intersects)
head(apt_price, 2)

# 2단계: 이전/이후 데이터 세트 만들기
kde_before <- subset(apt_price, ymd < "2021-07-01")
kde_before <- aggregate(kde_before$py, by=list(kde_before$ID), mean)
colnames(kde_before) <- c("ID", "before")

kde_after <- subset(apt_price, ymd > "2021-07-01")
kde_after <- aggregate(kde_after$py, by=list(kde_after$ID), mean)
colnames(kde_after) <- c("ID", "after")

kde_diff <- merge(kde_before, kde_after, by="ID")
kde_diff$diff <- round((((kde_diff$after - kde_diff$before) / kde_diff$before) * 100), 0)

head(kde_diff, 2)

# 3단계: 가격이 오른 지역 찾기
library(sf)
kde_diff <- kde_diff[kde_diff$diff > 0,]
kde_hot <- merge(grid, kde_diff, by="ID")
library(ggplot2)
library(dplyr)
kde_hot %>%
  ggplot(aes(fill = diff)) + 
  geom_sf() +
  scale_fill_gradient(low = "white", high = "red")

# 4단계 ~ 7단계: 기타 지도 작업
# 4단계: sp형으로 변환과 그리드별 중심 좌표 추출
library(sp)
kde_hot_sp <- as(st_geometry(kde_hot), "Spatial")
x <- coordinates(kde_hot_sp)[,1]
y <- coordinates(kde_hot_sp)[,2]

# 기준 경계 설정
l1 <- bbox(kde_hot_sp)[1, 1] - (bbox(kde_hot_sp)[1, 1] * 0.0001)
l2 <- bbox(kde_hot_sp)[1, 2] + (bbox(kde_hot_sp)[1, 2] * 0.0001)
l3 <- bbox(kde_hot_sp)[2, 1] - (bbox(kde_hot_sp)[2, 1] * 0.0001)
l4 <- bbox(kde_hot_sp)[2, 2] + (bbox(kde_hot_sp)[2, 2] * 0.0001)

# 지도 경계선 그리기
library(spatstat)
win <- owin(xrange=c(l1, l2), yrange=c(l3, l4))
plot(win)
rm(list = c("kde_hot_sp", "apt_price", "l1", "l2", "l3", "l4"))

# 5단계: 밀도 그래프 표시하기
p <- ppp(x, y, window = win, marks = kde_hot$diff)
d <- density.ppp(p, weights = kde_hot$diff,
                 sigma = bw.diggle(p),
                 kernel = 'gaussian')
plot(d)
rm(list = c("x", "y", "win", "p"))

# 6단계: 노이즈 제거와 래스터 이미지로 변환
d[d < quantile(d)[4] + (quantile(d)[4] * 0.1)] <- NA
library(raster)
raster_hot <- raster(d)
plot(raster_hot)

# 7단계: 서울시 외곽선 자르기
bnd <- st_read("./01_code/sigun_bnd/seoul.shp")
raster_hot <- crop(raster_hot, extent(bnd))
crs(raster_hot) <- sp::CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
plot(raster_hot)
plot(bnd, col = NA, border="red", add = TRUE)

# 8단계: 지도 그리기
library(leaflet)
leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = bnd, weight = 3, color = "red", fill = NA) %>%
  addRasterImage(raster_hot,
                 colors = colorNumeric(c("blue", "green", "yellow", "red"),
                                       values(raster_hot), na.color = "transparent"), opacity = 0.4)

# 9단계: 분석 결과 저장
save(raster_hot, file="./07_map/07_kde_hot.rdata")
rm(list = ls())
