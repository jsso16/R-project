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

# 3단계: 전체 지역/관심 지역 저장
library(dplyr)
apt_price <- st_join(apt_price, grid, join = st_intersects)
apt_price <- apt_price %>% st_drop_geometry()
all <- apt_price
sel <- apt_price %>% filter(ID == 81016)
dir.create('08_chart')
save(all, file="./08_chart/all.rdata")
save(sel, file="./08_chart/sel.rdata")
rm(list = ls())

#---

# 1단계: 월별 평당 거래가 요약
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./08_chart/all.rdata")
load("./08_chart/sel.rdata")
library(dplyr)
library(lubridate)
all <- all %>% group_by(month=floor_date(ymd, "month")) %>%
  summarize(all_py = mean(py))
sel <- sel %>% group_by(month=floor_date(ymd, "month")) %>%
  summarize(sel_py = mean(py))

# 2단계: 회귀식 모델링
fit_all <- lm(all$all_py ~ all$month)
fit_sel <- lm(sel$sel_py ~ sel$month)
coef_all <- round(summary(fit_all)$coefficients[2], 1) * 365
coef_sel <- round(summary(fit_sel)$coefficients[2], 1) * 365

# 3단계: 회귀 분석 그리기
library(grid)
grob_1 <- grobTree(textGrob(paste0("전체 지역: ", coef_all, "만원(평당)"), x=0.05,
                            y=0.88, hjust=0, gp=gpar(col="blue", fontsize=13, fontface="italic")))
grob_2 <- grobTree(textGrob(paste0("관심 지역: ", coef_sel, "만원(평당)"), x=0.05,
                            y=0.95, hjust=0, gp=gpar(col="red", fontsize=16, fontface="bold")))

# install.packages("ggpmisc")
library(ggpmisc)
gg <- ggplot(sel, aes(x=month, y=sel_py)) +
  geom_line() + xlab("월") + ylab("가격") +
  theme(axis.text.x=element_text(angle=90)) +
  stat_smooth(method='lm', colour="dark grey", linetype="dashed") +
  theme_bw()

gg + geom_line(color="red", size=1.5) +
  geom_line(data=all, aes(x=month, y=all_py), color="blue", size=1.5) +
  annotation_custom(grob_1) +
  annotation_custom(grob_2)
rm(list = ls())

#---

require(showtext)
font_add_google(name='Nanum Gothic', regular.wt=400, bold.wt=700)
showtext_auto()
showtext_opts(dpi=112)

#---

# 1단계: 주성분 분석
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./08_chart/sel.rdata")
pca_01 <- aggregate(list(sel$con_year, sel$floor, sel$py, sel$area),
                    by=list(sel$apt_nm), mean)
colnames(pca_01) <- c("apt_nm", "신축", "층수", "가격", "면적")
m <- prcomp(~ 신축 + 층수 + 가격 + 면적, data=pca_01, scale=T)
summary(m)

# 2단계: 그래프 그리기
# install.packages("ggfortify")
library(ggfortify)
autoplot(m, loadings.label=T, loadings.label.size=6) +
  geom_label(aes(label=pca_01$apt_nm), size=4)
