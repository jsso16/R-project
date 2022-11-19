# R-project - 602277119 전소진
Open data R with Shiny 2022

## 11월 16일
> 통계 분석과 시각화

**1. 관심 지역 데이터만 추출하기**
- 지난 2단계에 이어 관심 지역 데이터만 추출하기 위해서는 남은 1단계를 시행해야 한다.
- 이때, 통계 차트를 더욱 편리하게 분석하기 위해서는 전체 지역(all)과 관심 지역(sel)을 구분해서 저장하여야 한다.
```r
3. 전체 지역/관심 지역 저장

library(dplyr)
apt_price <- st_join(apt_price, grid, join = st_intersects)  # 실거래 + 그리드 결합
apt_price <- apt_price %>% st_drop_geometry()  # 실거래에서 공간 속성 지우기
all <- apt_price  # 전체 지역(all) 추출
sel <- apt_price %>% filter(ID == 81016)  # 관심 지역(sel) 추출
dir.create('08_chart')  # 새로운 폴더 생성
save(all, file="./08_chart/all.rdata")  # 저장
save(sel, file="./08_chart/sel.rdata")
rm(list = ls())  # 정리하기
```

**3. 회귀 분석: 이 지역은 일년에 얼마나 오를까?**
- 회귀 분석이란 독립 변수(x)의 변화에 따른 종속 변수(y)의 변화를 수리적 모형으로 설명한 모델링이다.
- 회귀 분석을 이용한 그래프를 통해 가격 변화를 확인하기 위해서는 총 3가지 단계를 시행해야 한다.
```r
1. 월별 거래가 요약하기

setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./08_chart/all.rdata")  # 전체 지역
load("./08_chart/sel.rdata")  # 관심 지역
library(dplyr)  # install.packages("dplyr")
library(lubridate)  # install.packages("lubridate")
all <- all %>% group_by(month=floor_date(ymd, "month")) %>%
  summarize(all_py = mean(py))  # 전체 지역 카운팅
sel <- sel %>% group_by(month=floor_date(ymd, "month")) %>%
  summarize(sel_py = mean(py))  # 관심 지역 카운팅
```
- summarize()는 데이터프레임의 정보를 한 줄로 요약해주는 함수로, group_by() 함수와 함께 사용된다. 
```r
2. 회귀식 모델링하기

fit_all <- lm(all$all_py ~ all$month)  # 전체 지역 회귀식
fit_sel <- lm(sel$sel_py ~ sel$month)  # 관심 지역 회귀식
coef_all <- round(summary(fit_all)$coefficients[2], 1) * 365  # 전체 회귀 계수
coef_sel <- round(summary(fit_sel)$coefficients[2], 1) * 365  # 관심 회귀 계수
```
- 회귀분석은 lm() 함수를 이용하며, 종속변수 ~ 독립변수의 형태로 모형식을 쓴다.
```r
3. 그래프 그리기

# 분기별 평당 가격 변화 주석 만들기
library(grid)  # install.packages("grid")
grob_1 <- grobTree(textGrob(paste0("전체 지역: ", coef_all, "만원(평당)"), x=0.05,
                            y=0.88, hjust=0, gp=gpar(col="blue", fontsize=13, fontface="italic")))
grob_2 <- grobTree(textGrob(paste0("관심 지역: ", coef_sel, "만원(평당)"), x=0.05,
                            y=0.95, hjust=0, gp=gpar(col="red", fontsize=16, fontface="bold")))

# 관심 지역 회귀선 그리기
library(ggpmisc)  # install.packages("ggpmisc")
gg <- ggplot(sel, aes(x=month, y=sel_py)) +
  geom_line() + xlab("월") + ylab("가격") +
  theme(axis.text.x=element_text(angle=90)) +
  stat_smooth(method='lm', colour="dark grey", linetype = "dashed") +
  theme_bw()

# 전체 지역 회귀선 그리기
gg + geom_line(color="red", size=1.5) +
  geom_line(data=all, aes(x=month, y=all_py), color="blue", size=1.5) +
  # 주석 추가하기
  annotation_custom(grob_1) +
  annotation_custom(grob_2)
rm(list = ls())  # 메모리 정리하기
```
- 회귀 분석 그래프를 그려보면 아래 사진과 같이 나타난다.
<img width="565" alt="회귀 분석 그래프" src="https://user-images.githubusercontent.com/62285642/202837362-f038bd02-1c0e-476d-bacc-997469f07140.png">

**+) Mac에서 한글이 제대로 표시되지 않는다면?**
- Mac에서 실행할 때, 종종 한글이 깨지는 경우가 있다.
- 이때 아래의 스크립트를 실행해주면 글꼴을 설정해주어 한글이 깨지는 것을 막아준다.
```r
require(showtext)  # install.packages("showtext")
font_add_google(name='Nanum Gothic', regular.wt=400, bold.wt=700)
showtext_auto()
showtext_opts(dpi=112)
```

**4. 주성분 분석: 이 동네 아파트 단지의 특징은 무엇일까?**
- 주성분 분석이란 다차원 정보를 효과적으로 요약하기 위한 대표적인 차원 축소 기법이다.
- 주성분 분석을 이용한 그래프를 통해 단지별 특징을 확인하기 위해서는 총 2가지 단계를 시행해야 한다.
```r
1. 주성분 분석하기

setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./08_chart/sel.rdata")  # 관심 지역 데이터 불러오기
pca_01 <- aggregate(list(sel$con_year, sel$floor, sel$py, sel$area),
                    by=list(sel$apt_nm), mean)  # 아파트별 평균값 구하기
colnames(pca_01) <- c("apt_nm", "신축", "층수", "가격", "면적")
m <- prcomp(~ 신축 + 층수 +가격 + 면적, data=pca_01, scale=T)  # 주성분 분석
summary(m)
```
- 주성분 분석은 prcomp() 함수를 사용하며, 데이터를 주성분으로 변환해준다.
```r
2. 그래프 그리기

library(ggfortify)  # install.packages("ggfortify")
autoplot(m, loadings.label=T, loadings.label.size=6) +
  geom_label(aes(label=pca_01$apt_nm), size=4)
```
- 주성분 분석 그래프를 그려보면 아래 사진과 같이 나타난다.
<img width="570" alt="주성분 분석 그래프" src="https://user-images.githubusercontent.com/62285642/202837382-c81f73bc-6410-4714-baf6-553ede5903bc.png">

> 샤이니 입문하기

**+) 샤이니(Shiny)란?**
- 데이터 분석가의 핵심 역량은 통계적 분석과 시각화 구현 능력뿐만 아니라 분석 결과를 애플리케이션으로 구현하여 공유할 수 있는 능력도 갖추어야 한다.
- 따라서 R은 분석 결과를 웹 애플리케이션으로 구현할 수 있는 샤이니(Shiny)라는 패키지를 제공한다.
- 샤이니는 기존 R 사용자를 고려하여 만들어졌기 때문에, 웹 개발에 필요한 HTML과 CSS, Javascript 같은 언어를 공부하는데 시간을 들이지 않아도 다양한 웹 애플리케이션을 개발할 수 있다.

**1. 처음 만나는 샤이니**
- 웹 애플리케이션은 사용자의 요청에 따라 응답하는 구조로 만들어진다.
- 따라서 샤이니는 이러한 요청과 응답을 효과적으로 처리하고자 사용자 인터페이스, 서버, 실행이라는 3가지 구성 요소를 작성하여 웹 애플리케이션을 만든다.
```r
1. 샤이니 기본 구조 이해하기

library(shiny) # install.packages(shiny)
ui <- fluidPage("사용자 인터페이스")  # 사용자 인터페이스
server <- function(input, output, session) { }  # 서버
shinyApp(ui, server)  # 실행
```
- 데이터 분석은 크게 명령형과 반응형 방식으로 구분된다.
- 명령형은 데이터 분석을 단계별로 진행하는 방식이며, 반응형은 분석을 진행하다가 특정한 조건이 바뀌면 되돌아가 다시 분석하는 방식이다.
<img width="801" alt="명령형과 반응형 방식" src="https://user-images.githubusercontent.com/62285642/202837411-2e40d45e-2025-4364-96eb-d0e10e655593.png">

- 기존 R 데이터 분석과 달리 샤이니 애플리케이션은 반응형 방식으로 동작한다.
- 따라서 아래의 샘플 코드를 실행해보면 슬라이더와 그래프가 나타나면서 서로 반응형으로 작동하는 것을 확인할 수 있다.
```r
2. 샘플 실행해보기

library(shiny)  # 라이브러리 등록
runExample()  #샘플 보여주기

runExample("01_hello")  # 1번 샘플 실행
```
- 샤이니 샘플 코드를 실행시키면 화면 하단에 사용자 인터페이스 및 서버 부분의 코드를 확인할 수 있다.
- ui()는 사용자에게 보이는 화면으로 데이터 입력과 분석 결과 출력을 담당한다.
- 따라서 사용자 인터페이스 부분의 코드만 작성하여 실행시키면 사용자에게 보이는 화면인 UI만 확인할 수 있다.
```r
3. 사용자 인터페이스 부분

library(shiny)  # 라이브러리 등록
ui <- fluidPage(  # 사용자 인터페이스 시작: fluidPage 정의
  titlePanel("샤이니 1번 샘플"),  # 제목 입력
  # 레이아웃 구성: 사이드바 패널 + 메인 패널
  sidebarLayout(  
    sidebarPanel(  # 사이드바 패널 시작
      sliderInput(inputId = "bins",  # 입력 아이디 
                  label = "막대(bin) 개수: ",  # 텍스트 라벨
                  min = 1, max = 50,  # 선택 범위(1 - 50)
                  value = 30)),  # 기본값 30
    mainPanel(  # 메인 패널 시작
      # 출력값: output$distPlot 저장
      plotOutput(outputId = "distPlot")  # 차트 출력
    )
  )
)
```
- server()는 입력 결과를 처리한 다음 다시 ui()로 보내며, ShinyApp()은 애플리케이션을 실행하는 역할을 한다.
- 따라서 서버 부분 코드까지 작성하여 ShinyApp()을 통해 UI와 서버 모두 실행시키면, 샤이니 샘플 코드와 동일한 화면과 결과를 확인할 수 있다.
- 이때 input과 output 뒤에 나오는 session은 여러 사람이 샤이니를 동시에 이용할 경우, 서로의 입력값 및 출력값에 영향을 받지 않게 하기 위해 독립성을 확보하는 역할을 수행한다.
```r
4. 서버 부분

server <- function(input, output, session) {
  # 랜더링한 플롯을 output 인자의 distPlot에 저장
  output$distPlot<- renderPlot({
    x <- faithful$waiting  # 분출 대기 시간 정보 저장
    # input$bins를 플롯으로 렌더링
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    # 히스토그램 그리기
    hist(x, breaks = bins, col = "#75AADB", border = "white",
         xlab = "다음 분출 때까지 대기 시간(분)",
         main = "대기 시간 히스토그램")
  })
}

shinyApp(ui, server)  # 실행
rm(list = ls())  # 메모리 정리
```

**2. 입력과 출력하기**
- 샤이니는 입력 조건을 바꿔서 서버의 계산을 거쳐 출력 결과로 전달하는 과정이 중요하다.
- 입력 위젯은 사용자들이 입력하는 값을 받는 장치로서, 샤이니에서 제공하는 함수 이름은 대체로 ~Input으로 끝난다.
- 샤이니에는 다양한 입력 모듈이 존재하는데, 이는 샤이니 공식 홈페이지에서 확인할 수 있다.<br>
  → https://shiny.rstudio.com/
```r
1. 입력받기 input$~

library(shiny)
ui <- fluidPage(
  sliderInput("range", "연비", min = 0, max = 35, value = c(0, 10))  # 데이터 입력
)
server <- function(input, output, session) {}  # 반응 없음

shinyApp(ui, server)  # 실행
```
- 출력 위젯 또한 사용자들이 입력하는 값을 받아 출력하는 장치로서, 샤이니에서 제공하는 함수 이름은 대체로 ~Output으로 끝난다.
- 이때 입력된 데이터 값을 계산하여 출력해주기 위해서는 서버에 값을 넘겨주는 함수의 중괄호 안에 함수식을 정의해주어야 한다.
```r
2. 출력하기 output$~

library(shiny)
ui <- fluidPage(
  sliderInput("range", "연비", min = 0, max = 35, value = c(0, 10)),  # 데이터 입력
  textOutput("value")  # 결과값 출력
)
server <- function(input, output, session) {
  output$value <- renderText((input$range[1] + input$range[2]))  # 입력값 계산
}

shinyApp(ui, server)
```
- 아래의 코드를 실행하면 'Can't access reactive value 'range' outside of reactive consumer.'라는 에러 메세지를 확인할 수 있다.
- 이는 서버에서 입력값을 계산한 후 출력할 때 렌더링 함수가 없어서 발생한 오류이다.
- 따라서 계산한 결과값을 갱신해주기 위해서는 렌더링 함수가 꼭 필요하다.
```r
3. 렌더링 함수의 중요성 render()~

library(shiny)
ui <- fluidPage(
  sliderInput("range", "연비", min = 0, max = 35, value = c(0, 10)),  # 데이터 입력
  textOutput("value")  # 출력
)
server <- function(input, output, session) {
  output$value <- (input$range[1] + input$range[2])  # 입력값 계산
}

shinyApp(ui, server)
```

## 11월 09일
> 분석 주제를 지도로 시각화하기

**1. 어느 지역이 제일 비쌀까?**
- 지난 5단계에 이어 가장 가격이 높은 지역을 찾기 위해서는 남은 3가지 단계를 시행해야 한다.
```r
6. 불필요한 부분 자르기

bnd <- st_read("./01_code/sigun_bnd/seoul.shp")  # 서울시 경계선 불러오기
raster_high <- crop(raster_high, extent(bnd))  # 외곽선 자르기
crs(raster_high) <- sp::CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")  # 좌표계 정의
plot(raster_high)  # 지도 확인
plot(bnd, col = NA, border = "red", add = TRUE)
```
- st_read()는 셰이프 파일을 불러오는 함수이다.
- crop() 함수를 이용하여 외각선을 기준으로 래스터 이미지를 잘라낼 수 있다.
```r
7. 지도 그리기

library(rgdal)  # install.packages("rgdal")
library(leaflet)
leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%  # 기본 지도 불러오기
  addPolygons(data = bnd, weight = 3, color = "red", fill = NA) %>%  # 서울시 경계선 불러오기
  addRasterImage(raster_high,  # 래스터 이미지 불러오기
                 colors = colorNumeric(c("blue", "green", "yellow", "red"),
                                     values(raster_high), na.color = "transparent"), opacity = 0.4)
```
- rgdal 패키지의 RDGAL(R Geospatial Data Abstraction Library)은 지리 공간 정보를 가지는 래스터 데이터 처리 라이브러리이다. 
- addProviderTiles() 함수는 옵션으로 지도의 기본 테마를 지정할 수 있다.
- addPolygons()는 외각선을 불러오는 함수로, 외각선의 폭과 색상을 지정할 수 있다.
- addRasterImage() 함수를 이용하여 지도 위에 래스터 이미지를 올릴 수 있다.
```r
8. 평균 가격 정보 표시하기

dir.create("07_map")  # 새로운 폴더 생성
save(raster_high, file="./07_map/07_kde_high.rdata")  # 최고가 래스터 저장
rm(list = ls())  # 메모리 정리
```

**2. 요즘 뜨는 지역은 어디일까?**
- 최근 급등한 지역을 찾기 위해서는 일정 기간 동안 가장 많이 오른 지역을 특정하여야 한다.
- 이는 똑같은 그리드를 대상으로 두 시점 사이의 가격 변화를 비교하여 단순히 특정 그리드의 평균 가격을 측정하는 방식보다 복잡하다.
- 따라서 일정 기간 동안 가장 많이 오른 지역을 특정하기 위해서는 9가지 단계를 시행해야 한다.
```r
1. 데이터 준비하기

setwd(dirname(rstudioapi::getSourceEditorContext()$path))  # 작업 폴더 설정
load("./06_geodataframe/06_apt_price.rdata")  # 실거래 불러오기
grid <- st_read("./01_code/sigun_grid/seoul.shp")  # 서울시 1km 그리드 불러오기
apt_price <- st_join(apt_price, grid, join = st_intersects)  # 실거래 + 그리드 결합
head(apt_price, 2)
```
- 이전의 지역별 평균 가격을 구했던 것과 같이, 일정 기간 동안 가장 많이 오른 지역을 특정하기 위해서도 st_join() 함수를 이용해 각각의 속성 테이블을 결합해주어야 한다.
```r
2. 이전/이후 데이터 세트 만들기

kde_before <- subset(apt_price, ymd < "2021-07-01")  # 이전 데이터 필터링
kde_before <- aggregate(kde_before$py, by=list(kde_before$ID), mean)  # 평균 가격
colnames(kde_before) <- c("ID", "before")  # 칼럼명 변경

kde_after <- subset(apt_price, ymd > "2021-07-01")  # 이후 데이터 필터링
kde_after <- aggregate(kde_after$py, by=list(kde_after$ID), mean)  # 평균 가격
colnames(kde_after) <- c("ID", "after")  # 칼럼명 변경

kde_diff <- merge(kde_before, kde_after, by="ID")  # 이전 + 이후 데이터 결합
kde_diff$diff <- round((((kde_diff$after - kde_diff$before) / kde_diff$before) * 100), 0)  # 변화율 계산

head(kde_diff, 2)  # 변화율 확인
```
- subset()은 선택한 변수와 조건에 맞는 데이터를 추출해주는 함수로, 이를 이용해 원하는 데이터를 필터링할 수 있다.
- colnames() 함수를 이용하면 칼럼명(열 이름)을 변경할 수 있다.
```r
3. 가격이 오른 지역 찾기

library(sf)  # install.packages("sf")
kde_diff <- kde_diff[kde_diff$diff > 0,]  # 상승 지역만 추출
kde_hot <- merge(grid, kde_diff, by="ID")  # 그리드에 상승 지역 결합
library(ggplot2)  # install.packages("ggplot2")
library(dplyr)  # install.packages("dplyr")
kde_hot %>%  # 그래프 시각화
  ggplot(aes(fill = diff)) + 
  geom_sf() +
  scale_fill_gradient(low = "white", high = "red")
```
- ggplot을 이용해서 그래프를 시각화하면 아래 사진과 같이 가격이 높은 지역은 붉은색으로, 낮은 지역은 흰색으로 표시되어 나타난다.
<img width="566" alt="ggplot을 이용한 그래프 시각화" src="https://user-images.githubusercontent.com/62285642/201458976-229b278d-c8ef-4bbd-afab-0983f1a867ac.png">

```r
4 ~ 7. 기타 지도 작업
  - 가장 비싼 지역을 찾는 작업의 3단계부터 6단계까지의 작업을 그대로 복사하여 변수명을 kde_high에서 kde_hot으로 변경하기
```
- 지도 경계, 밀도 그래프, 래스터 이미지, 불필요한 부분 자르기 등의 작업을 진행하여야 하는데, 이는 이전에 가장 비싼 지역을 찾는 작업의 3단계부터 6단계까지의 작업과 동일하다.
- 자세한 코드는 [kde_hot.R](https://github.com/jsso16/R-project/blob/main/kde_hot.R)에서 확인할 수 있다.
```r
8. 지도 그리기

library(leaflet)  # install.packages("leaflet")
leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%  # 기본 지도 불러오기
  addPolygons(data = bnd, weight = 3, color = "red", fill = NA) %>%  # 서울시 경계선 불러오기
  addRasterImage(raster_hot,  # 래스터 이미지 불러오기
                 colors = colorNumeric(c("blue", "green", "yellow", "red"),
                                       values(raster_hot), na.color = "transparent"), opacity = 0.4)
```
- leaflet()을 이용해 지도를 그려보면 아래 사진과 같이 기본 지도 위에 경계선과 래스터 이미지가 나타난다.
<img width="568" alt=" leaflet() 함수를 이용한 지도" src="https://user-images.githubusercontent.com/62285642/201459040-14b3cb30-8568-4c94-ba5d-b538b45ed622.png">

```r
9. 평균 가격 정보율 정보 저장하기

save(raster_hot, file="./07_map/07_kde_hot.rdata")  # 급등지 래스터 저장
rm(list = ls())  # 메모리 정리
```

**3. 우리 동네가 옆 동네보다 비쌀까?**
- 특정 지역의 평균 가격을 주변 지역과 비교해보기 위해서는 평당 실거래가 평균을 직접 지도 위에 표시해야 한다.
- 그러나 제한된 영역에 많은 데이터를 배열하면 정보를 명확하게 전달할 수 없으므로, 마커 클러스터링을 이용하여 지도에 표시할 데이터를 적절하게 조절해주어야 한다.
- 마커 클러스터링이란 지도에 표시되는 마커가 너무 많을 때, 특정한 기준으로 마커들을 하나의 무리(cluster)로 묶어주는 방법이다.
- 이렇게 특정 지역의 평균 가격을 주변 지역과 비교해보기 위해서는 총 3가지 단계를 시행해야 한다.
```r
1. 데이터 준비하기

setwd(dirname(rstudioapi::getSourceEditorContext()$path))  # 작업 폴더 설정
load("./06_geodataframe/06_apt_price.rdata")  # 실거래 자료 불러오기
load("./07_map/07_kde_high.rdata")  # 최고가 래스터 이미지
load("./07_map/07_kde_hot.rdata") # 급등지 래스터 이미지

library(sf)  # install.packages("sf")
bnd <- st_read("./01_code/sigun_bnd/seoul.shp")  # 서울시 경계선
grid <- st_read("./01_code/sigun_grid/seoul.shp")  # 서울시 그리드 파일
```
- 앞서 진행했던 최근 급등 지역을 찾는 작업과 동일하게 load() 함수와 st_read() 함수를 이용하여 필요한 데이터와 셰이프 파일을 불러와야 한다.
```r
2. 마커 클러스터링 옵션 설정하기

pnct_10 <- as.numeric(quantile(apt_price$py, probs = seq(.1, .9, by = .1))[1])  # 이상치 설정(하위 10% 지점)
pnct_90 <- as.numeric(quantile(apt_price$py, probs = seq(.1, .9, by = .1))[9])  # 이상치 설정(상위 90% 지점)
load("./01_code/circle_marker/circle_marker.rdata")  # 마커 클러스터링 함수 등록
circle.colors <- sample(x=c("red", "green", "blue"), size=1000, replace=TRUE)  # 마커 클러스터링 색상 설정: 상, 중, 하
```
- 지도 위에 마커 클러스터링으로 데이터를 표현하기 위해서는 load() 함수를 이용해 circle_marker.rdata 파일을 불러와야 한다.
- 이 파일을 불러오면 avg.fomula라는 마커 클러스터링용 자바스크립트가 실행되면서 지도에 마커 클러스터링이 표시된다.
```r
3. 마커 클러스터링 시각화하기

library(purrr)  # install.packages("purrr")
leaflet() %>%
  addTiles() %>%  # 오픈 스트리트 맵 불러오기
  addPolygons(data = bnd, weight = 3, color = "red", fill = NA) %>%  # 서울시 경계선 불러오기
  addRasterImage(raster_high,  # 최고가 래스터 이미지 불러오기
                 colors = colorNumeric(c("blue", "green", "yellow", "red"), values(raster_high), 
                                       na.color = "transparent"), opacity = 0.4, group = "2021 최고가") %>%
  addRasterImage(raster_hot,  # 급등지 래스터 이미지 불러오기
                 colors = colorNumeric(c("blue", "green", "yellow", "red"), values(raster_hot), 
                                       na.color = "transparent"), opacity = 0.4, group = "2021 급등지") %>%
  addLayersControl(baseGroups = c("2021 최고가", "2021 급등지"),  # 최고가/급등지 옵션 추가하기
                   options = layersControlOptions(collapsed = FALSE)) %>%
  addCircleMarkers(data = apt_price, lng = unlist(map(apt_price$geometry, 1)),  # 마커 클러스터링 불러오기
                   lat = unlist(map(apt_price$geometry, 2)), radius = 10, stroke = FALSE,
                   fillOpacity = 0.6, fillColor = circle.colors, weight = apt_price$py,
                   clusterOptions = markerClusterOptions(iconCreateFunction=JS(avg.formula)))
rm(list = ls())  # 메모리 정리하기
```
- Mac에서는 purrr 라이브러리 설치 시 '컴파일이 요구되는 패키지를 소스로부터 바로 설치하기를 원하나요?'라는 메세지가 나올 수 있는데, 이때 'no'를 입력하면 오류없이 설치할 수 있다.
- 마커 클러스터링을 시각화하면 아래 사진과 같이 경계선과 최고가 또는 급등지 래스터 이미지가 표시된 지도 위에 마커 클러스터링이 표시된 것을 확인할 수 있다.
<img width="568" alt="마커 클러스터링 시각화" src="https://user-images.githubusercontent.com/62285642/201459089-6077a01b-1e92-42f0-9eff-70ebe1169e9d.png">

> 통계 분석과 시각화

**1. 관심 지역 데이터만 추출하기**
- 관심있는 지역 데이터를 추출하기 위해서는 관심이 있는 아파트들이 포함된 그리드를 찾아내야 한다.
- 여기서 관심 지역이란 주목해서 분석하고 싶은 동네를 의미한다.
- 이러한 관심 지역 데이터를 추출하기 위해서는 총 3가지 단계를 시행해야 한다.
```r
1. 데이터 준비하기

library(sf)  # install.packages("sf")
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./06_geodataframe/06_apt_price.rdata")  # 실거래 데이터
load("./07_map/07_kde_high.rdata")  # 최고가 래스터 이미지
grid <- st_read("./01_code/sigun_grid/seoul.shp")  # 서울시 그리드
```
- 관심 지역을 찾기 위해서는 먼저 가장 비싼 지역을 파악해야 하는데, 이를 위해서는 Thematic Map을 사용하여야 한다.
- Thematic Map이란 지리적 영역에서 인구 밀도, 강수량 등과 같은 특정 주제의 지리적 패턴을 나타내는 지도이다.
```r
2. 서울에서 가장 비싼 지역 찾기

library(tmap)  # install.packages("tmap")
tmap_mode("view")
tm_shape(grid) + tm_borders() + tm_text("ID", col = "red") +  # 그리드 그리기
  tm_shape(raster_high) +  # 래스터 이미지 그리기
  tm_raster(palette = c("blue", "green", "yellow", "red"), alpha = .4) +  # 래스터 이미지 색상 패턴 설정
  tm_basemap(server = c("openStreetMap"))  # 기본 지도 설정
```
- 지도를 시각화하면 가장 비싼 지역이 붉은색으로 나타나면서 해당 지역의 이름과 그리드 ID를 확인할 수 있다.

## 11월 02일
> 분석 주제를 지도로 시각화하기

**1. 어느 지역이 제일 비쌀까?**
- 가장 가격이 높은 지역을 찾기 위한 지역별 평균 가격을 구하려면 먼저 그리드별 평균 가격을 계산해야 한다.
- 그리드란 격자 형식의 무늬를 말하는데, 그리드별로 분할된 정보를 저장하기 위해서는 셰이프 파일을 사용하여야 한다.
- 셰이프 파일이란 지리 공간 분석에서 널리 사용하는 표준화된 형식으로서 지리 현상을 기하학적 위치와 속성 정보로 동시에 저장한 데이터 형식을 의미한다.
- 이렇게 지역별 평균 가격을 구하고, 가장 가격이 높은 지역을 찾기 위해서는 총 8가지 단계를 시행해야 한다.
```r
1. 지역별 평균 가격 구하기

setwd(dirname(rstudioapi::getSourceEditorContext()$path))  # 작업 폴더 설정
load("./06_geodataframe/06_apt_price.rdata")  # 실거래 자료 불러오기
library(sf)  # install.packages("sf")
grid <- st_read("./01_code/sigun_grid/seoul.shp")  # 서울시 1km 그리드 불러오기
apt_price <- st_join(apt_price, grid, join = st_intersects)  # 실거래 + 그리드 결합
head(apt_price, 2)

kde_high <- aggregate(apt_price$py, by=list(apt_price$ID), mean)  # 그리드별 평균 가격
colnames(kde_high) <- c("ID", "avg_price")  # 칼럼명 변경
head(kde_high, 2)  # 평균가 확인
```
- st_join() 함수는 속성 테이블을 결합해주는 함수로, 특정 정보가 어느 그리드에 속해있는지 파악할 수 있다.
- aggregate()는 데이터의 특정 컬럼을 기준으로 그룹화하고, 이에 대한 통계를 구해주는 함수이다.
```r
2. 평균 가격 정보 표시하기

kde_high <- merge(grid, kde_high, by="ID")  # ID 기준으로 결합
library(ggplot2)  # install.packages("ggplot2")
library(dplyr)  # install.packages("dplyr")
kde_high %>% ggplot(aes(fill = avg_price)) +  # 그래프 시각화
                    geom_sf() +
                    scale_fill_gradient(low = "white", high = "red")
```
- 이때 두 자료에 id 정보가 공통으로 포함되어 있으므로, 이를 기준으로 merge() 함수를 이용해 그리드 지도 데이터와 공간 결합할 수 있다.
- 다음으로 데이터가 집중된 곳을 찾고싶을 때는 커널 밀도 추정을 이용한다.
- 커널 밀도 추정(KDE: Kernel Density Estimation)이란 커널 함수로 변수의 밀도를 추정하는 방법의 하나이다.
```r
3. 지도 경계 그리기

library(sp) # install.packages("sp")
kde_high <- as(st_geometry(kde_high), "Spatial")  # sf형 => sp형 변환
x <- coordinates(kde_high_sp)[,1]  # 그리드 중심 x, y 좌표 추출
y <- coordinates(kde_high_sp)[,2]

l1 <- bbox(kde_high_sp)[1, 1] - (bbox(kde_high_sp)[1, 1] * 0.0001)
l2 <- bbox(kde_high_sp)[1, 2] + (bbox(kde_high_sp)[1, 2] * 0.0001)
l3 <- bbox(kde_high_sp)[2, 1] - (bbox(kde_high_sp)[2, 1] * 0.0001)
l4 <- bbox(kde_high_sp)[2, 2] + (bbox(kde_high_sp)[2, 2] * 0.0001)

library(spatstat)  # install.packages("spatstat")
win <- owin(xrange=c(l1, l2), yrange=c(l3, l4))
plot(win)  # 지도 경계선 확인
rm(list = c("kde_high_sp", "apt_price", "l1", "l2", "l3", "l4"))  # 변수 정리
```
- owin()은 2차원 평면에서 관찰창, 즉 경계선을 생성해주는 함수이다.
- 입력한 변수를 정리하고 싶을 때는 rm() 함수를 이용하여 저장되어있는 변수를 제거할 수 있다.
```r
4. 밀도 그래프 표시하기

p <- ppp(x, y, window = win)  # 경계선 위에 좌푯값 포인트 생성
d <- density.ppp(p, weights = kde_high$avg_price,  # 커널 밀도 함수로 변환
                 sigma = bw.diggle(p),
                 kernel = 'gaussian')
plot(d)  # 밀도 그래프 확인
rm(list = c("x", "y", "win", "p"))  # 변수 정리
```
- ppp() 함수는 x와 y에 따른 좌푯값을 포인트로 나타내준다.
- 또한 density.ppp() 함수는 ppp() 함수를 이용해 생성한 포인트를 연속된 곡선을 가지는 커널로 변환해서 그래프를 그려준다.
- 이때, 빅데이터를 잘 다루려면 노이즈를 최소화하고 의미있는 신호를 찾아내는 것이 중요하다.
```r
5. 래스터 이미지로 변환하기

d[d < quantile(d)[4] + (quantile(d)[4] * 0.1)] <- NA  # 노이즈 제거
library(raster)  # install.packages("raster")
raster_high <- raster(d)  # 래스터 변환
plot(raster_high)
```
- quntile()은 전체 데이터를 순서대로 정렬할 때, 0%, 25%, 50%, 75%, 100%가 되는 지점을 알려주는 함수이다. 
- 따라서 이를 이용해 노이즈를 제거한다면 더욱 의미있는 데이터를 얻을 수 있다.
- raster() 함수는 포인트 데이터를 래스터 이미지로 변환해준다.

**+) 커널 밀도 추정 시 기억해야 할 2가지 옵션**
- 커널 밀도를 추정하기 위해서는 커널 함수(kernel function)의 종류와 시그마(sigma) 이렇게 2가지 개념을 이해해야 한다.
- 커널 함수의 종류는 데이터가 분포하는 대략적인 형태를 지칭하는 것으로 gaussian, epanechnikov, quartic 등이 있다.
- 또한 시그마는 데이터의 분산(퍼져있는 정도)을 나타내는 것으로 대역폭 파라미터라고도 하는데, 시그마는 아래 사진과 같이 변화에 따라 커널 밀도 함수의 형태가 달라지기 때문에 최적값을 찾기가 어렵다.
<img width="218" alt="시그마 변화에 따른 커널 밀도 함수 형태" src="https://user-images.githubusercontent.com/62285642/200105798-5d5ac9c0-a87d-49fe-a284-5d47fc7b7985.png">

- 따라서 이러한 불편을 최소화하고자 r의 공간 통계 라이브러리인 spatstat 패키지는 bw.diggle(), bw.ppl(), bw.scot()이라는 3가지 옵션을 제공하게 되었다.
- 여기서 제일 널리 사용되는 커널 형태 옵션은 gaussian이며, 시그마 옵션은 bw.diggle()이다.

## 10월 26일
> 지오 데이터프레임 만들기

**2. 주소와 좌표 결합하기**
- 주소와 좌표를 결합하기 위해서는 총 2가지 단계를 시행해야 한다.
```r
1. 데이터 불러오기

setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./04_pre_process/04_pre_process.rdata")  # 주소 불러오기
load("./05_geocoding/05_juso_geocoding.rdata")  # 좌표 불러오기
```
- 2개 이상의 데이터프레임을 불러올 때, 서로 다른 데이터프레임 안에 공통된 정보가 존재하는 경우가 있다.
```r
2. 주소와 좌표 결합하기

library(dplyr)  # install.packages("dplyr")
apt_price <- left_join(apt_price, juso_geocoding, 
                       by = c("juso_jibun" = "apt_juso"))  # 결합
apt_price <- na.omit(apt_price)  # 결측치 제거
```
- 이때, 위 코드처럼 left_join() 함수를 사용하면 이를 하나의 데이터프레임으로 결합할 수 있다.

**3. 지오 데이터프레임 만들기**
- 지오 데이터프레임을 만들기 위해서는 총 3가지 단계를 시행해야 한다.
```r
1. 지오 데이터프레임 생성하기

library(sp)  # install.packages("sp")
coordinates(apt_price) <- ~coord_x + coord_y  # 좌푯값 할당
proj4string(apt_price) <- "+proj=longlat +datum=WGS84 +no_defs"  # 좌표계(CRS) 정의
library(sf)  # install.packages("sf")
apt_price <- st_as_sf(apt_price)  # sp형 => sf형 변환
```
- sp 패키지를 통해 불러온 coordinates() 함수는 좌표값을 할당하여 x축과 y축을 서로 바꾸거나 축의 값을 변환하는 등의 좌표 체계 변환 기능을 제공한다.
- 해당 좌표가 어떠한 좌표계를 참조하는지 정의하여 좌표값을 변형할 때에는 proj4string() 함수를 사용한다.
- st_as_sf() 함수는 sp형 데이터프레임을 sf형으로 변환하여 공간 데이터를 더욱 편리하게 변환할 수 있다.
```r
2. 지오 데이터프레임 시각화

plot(apt_price$geometry, axes = T, pch = 1)  # 플롯 그리기
library(leaflet)  # install.packages("leaflet")  # 지도 그리기 라이브러리
leaflet() %>% addTiles() %>% 
  addCircleMarkers(data=apt_price[1:1000,], label=~apt_nm)  # 1,000개만 그리기
```
- plot() 함수를 이용하면 데이터프레임을 간단하게 시각화할 수 있다.
- 빈 캔버스를 그린 다음, addTiles() 함수로 기본 지도인 오픈스트리트맵을 불러오기 위해서는 leaflet() 함수를 사용해야 한다.
- addCircleMarkers() 함수는 데이터가 가리키는 위치에 동그란 마커와 라벨을 표시한다.
```r
3. 지오 데이터프레임 저장하기

dir.create("./06_geodataframe")  # 새로운 폴더 생성
save(apt_price, file="./06_geodataframe/06_apt_price.rdata")  # radata 저장
write.csv(apt_price, "./06_geodataframe/06_apt_price.csv")  # csv 저장
```

## 10월 12일
> 전처리: 데이터를 알맞게 다듬기

**3. 전처리 데이터 저장하기**
- 전처리 데이터를 저장하기 위해서는 총 2가지 단계를 시행해야 한다.
```r
1. 필요한 칼럼만 추출하기

apt_price <- apt_price %>% select(ymd, ym, year, code, addr_1, apt_nm,
                                  juso_jibun, price, con_year, area, floor, py, cnt)  # 칼럼 추출
head(apt_price, 2)  # 자료 확인
```
- select() 함수는 데이터에서 필요한 변수만 추출하고 싶을 때 사용한다.
```r
2. 전처리 데이터 저장하기

setwd(dirname(rstudioapi::getSourceEditorContext()$path))
dir.create("./04_pre_process")  # 새로운 폴더 생성
save(apt_price, file = "./04_pre_process/04_pre_process.rdata")  # 저장
write.csv(apt_price, "./04_pre_process/04_pre_process.csv")
```

> 카카오맵 API로 지오 코딩하기

**1. 지오 코딩 준비하기**
- 지오 코딩이란 문자로 된 주소를 위도와 경도라는 숫자로 변환하는 작업이다.
- 지오 코딩을 하기 위해서는 공간정보산업진흥원에서 제공하는 Geocoder라는 API를 사용하거나 구글 또는 카카오 같이 민간 기업에서 제공하는 API를 사용할 수도 있다.
- 이 프로젝트에서 사용하는 카카오 API는 REST API 방식으로 카카오맵의 콘텐츠와 데이터를 이용할 수 있도록 로컬 API를 제공한다.
- 지오 코딩을 준비하기 위해서는 총 2가지 단계를 시행해야 한다.
```r
1. 카카오 로컬 API 키 발급받기
  - 카카오 개발자 사이트에서 [내 애플리케이션] 클릭하기
  → '애플리케이션 추가하기'를 클릭 후, 앱 이름 및 사업자 이름 작성하기
  → 저장한 애플리케이션을 클릭하여 REST API 키 확인하기
```
- 이때, 카카오 로컬 API 키를 발급받기 위해서는 카카오 개발자 사이트에 접속하여 회원가입 및 로그인을 해야한다.
- 카카오 개발자 사이트는 다음과 같다.<br>
  → https://developers.kakao.com
```r
2. 중복된 주소 제거하기

setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./04_pre_process/04_pre_process.rdata")  # 실거래 자료 불러오기
apt_juso <- data.frame(apt_price$juso_jibun)  # 주소가 있는 칼럼 추출
apt_juso <- data.frame(apt_juso[!duplicated(apt_juso), ])  # 고유한 주소만 추출
head(apt_juso, 2)  # 추출 결과 확인
```
- 아파트와 같이 주소가 같은 곳에 거주하는 경우, 중복되는 값들이 많이 존재한다.
- 따라서 duplicated() 함수를 사용하면 중복되는 값을 제거할 수 있다.

**2. 주소로 좌표를 변환하는 지오 코딩**
- 지오 코딩을 통해 주소로 좌표를 변환하기 위해서는 총 2가지 단계를 시행해야 한다.
```r
1. 지오 코딩하기

add_list <- list()  # 빈 리스트 생성
cnt <- 0  # 반복문 카운팅 초깃값 설정
kakao_key = "REST API 키"  # 카카오 REST API 키

library(httr)  # install.packages("httr")
library(RJSONIO)  # install.packages("RJSONIO")
library(data.table)  # install.packages("data.table")
library(dplyr)  # install.packages("dplyr")

for (i in 1:nrow(apt_juso)) {
  # 예외 처리 구문 시작
  tryCatch (
    {
      # 주소로 좌푯값 요청
      lon_lat <- GET(url = 'https://dapi.kakao.com/v2/local/search/address.json',
                     query = list(query = apt_juso[i,]),
                     add_headers(Authorization = paste0("KakaoAK ", kakao_key)))
      # 위경도만 추출하여 저장
      coordxy <- lon_lat %>% content(as = 'text') %>% RJSONIO::fromJSON()
      # 반복 횟수 카운팅
      cnt = cnt + 1
      # 주소, 경도, 위도 정보를 리스트로 저장
      add_list[[cnt]] <- data.table(apt_juso = apt_juso[i,],
                                    coord_x = coordxy$documents[[1]]$x,
                                    coord_y = coordxy$documents[[1]]$y)
      # 진행 상황 알림 메시지
      message <- paste0("[", i, "/", nrow(apt_juso), "] 번째 (",
                        round(i/nrow(apt_juso) * 100, 2), " %) [", apt_juso[i,], "] 지오 코딩 중입니다: X= ", 
                        add_list[[cnt]]$coord_x, " / Y= ", add_list[[cnt]]$coord_y)
      cat(message, "\n\n")
      # 예외 처리 구문 종료
    }, error = function(e){cat("ERROR: ", conditionMessage(e), "\n")}
  )
}
```
- 카카오 API 주소를 좌표로 변환할 때, 아래의 4가지 패키지를 사용한다.
  - httr: 웹(http)으로 자료 요청
  - rjson: 응답 결과인 JSON형 자료 처리
  - data.table: 좌표를 테이블로 저장
  - dplyr: 파이프라인 사용
- 또한 주소로 좌푯값을 요청하기 위해서는 GET() 함수 안에 서비스 URL, 질의, 헤더 이렇게 3가지 요소를 함께 작성해주어야 한다.
```r
2. 지오 코딩 결과 적용하기

juso_geocoding <- rbindlist(add_list)  # 리스트 -> 데이터프레임 변환
juso_geocoding$coord_x <- as.numeric(juso_geocoding$coord_x)  # 좌표 숫자형 변환
juso_geocoding$coord_y <- as.numeric(juso_geocoding$coord_y)
juso_geocoding <- na.omit(juso_geocoding)  # 결측치 제거
dir.create("./05_geocoding")  # 새로운 폴더 생성
save(juso_geocoding, file="./05_geocoding/05_juso_geocoding.rdata")  # 저장
write.csv(juso_geocoding, "./05_geocoding/05_juso_geocoding.csv")
```

> 지오 데이터프레임 만들기

**1. 좌표계와 지오 데이터 포맷**
- 좌표계란 불규칙한 타원체인 지구의 실체 좌푯값을 표현하기 위해서 투영 과정을 거쳐 보정해야하는데, 이러한 보정의 기준을 의미한다.
- 국내에서는 국토지리정보원 표준 좌표계인 GRS80을 많이 사용하며, 국제적으로는 GPS의 참조 좌표계이자 구글이나 오픈 스트리트맵 같은 글로벌 지도 서비스에 사용되는 WGS84가 있다.
- 이러한 좌표계를 표준화하고자 부여한 코드가 바로 EPSG(European Petroleum Survey Group)이다.
<img width="508" alt="좌표계 투영" src="https://user-images.githubusercontent.com/62285642/195973628-c5d42c0a-bb23-4fa2-8ada-2654de4734f5.png">

- R의 데이터프레임은 다양한 유형의 정보를 통합하여 저장할 수 있는 포맷을 지니고 있지만, 기하학 특성의 위치 정보를 저장하기에는 적합한 포맷이 아니어서 공간 분석에는 한계가 있다.
- 이러한 한계를 보완하기 위해 지오 데이터 포맷으로 sp 패키지가 공개되었다.
- 2005년 공개된 sp 패키지는 R에서 점, 선, 면 같은 공간 정보를 처리할 목적으로 만든 데이터 포맷으로, 테두리 상자나 좌표계 같은 다양한 정보들도 함께 저장할 수 있다는 점에서 공간 분석의 새로운 길을 열어주었다.
- 그러나 데이터 일부를 편집하거나 수정하는 것은 어렵다는 한계가 있었다.
- 따라서 이러한 sp의 한계를 극복하고자 2016년 sf 패키지가 공개되었다.
<img width="733" alt="sf 패키지 자료의 구성" src="https://user-images.githubusercontent.com/62285642/195973674-7fa86f09-4830-46c4-b092-4369db856bfb.png">

- sf는 sp 패키지가 가지고 있던 기능과 속성을 그대로 이어받지만, 기존의 데이터프레임에 공간 속성을 가진 칼럼을 추가함으로써 공간 데이터를 일반 데이터프레임과 비슷하게 편집하거나 수정할 수 있게 하였다.
- 따라서 최근에는 sf 패키지 사용자가 꾸준히 증가하고 있지만 아직까지 관련 자료나 레퍼런스는 부족한 상황이며, 아직까지는 공간 도형을 다루기에는 sp가 빠르다는 평가가 많아서 대부분 sp와 sf를 함께 사용한다.

**+) 지오 데이터 포맷 변환**
- sp 패키지는 데이터 전체의 기하학 정보를 처리할 때 유리하다.
- sf 패키지는 부분적인 바이너리 정보 처리가 빠르다.
- 이처럼 sp와 sf 패키지의 장단점이 다르기 때문에 어떠한 것이 더 좋은지 판단할 수 없으므로, 상황에 따라 아래와 같이 sp와 sf 패키지를 서로 변환하여 사용하는 것이 좋다.
<img width="458" alt="sp와 sf 변환" src="https://user-images.githubusercontent.com/62285642/195974326-5b1e4161-7f69-4ba8-a066-f9aae1a306dd.png">

## 10월 05일
> 자료 수집: API 크롤러 만들기

**4. 자료 정리: 자료 통합하기**
- 지난 1단계에 이어 통합한 데이터를 저장하기 위해서는 다음 단계를 시행해야 한다.
```r
2. 통합 데이터 저장하기

dir.create("./03_integrated")  # 새로운 폴더 생성
save(apt_price, file = "./03_integrated/03_apt_price.rdata")  # 저장
write.csv(apt_price, "./03_integrated/03_apt_price.csv")
```
- 하나의 파일로 통합한 데이터는 아래와 같다.
<img width="708" alt="통합 데이터" src="https://user-images.githubusercontent.com/62285642/194691465-84b5c4f4-ca6b-41df-bab1-5be3ba3a9c63.png">

> 전처리: 데이터를 알맞게 다듬기

**1. 불필요한 정보 지우기**
- 자료 수집 과정에서 발생하는 문제를 줄이기 위해 불필요한 정보를 정리하는 작업을 전처리라고 한다.
- 전처리를 진행하기 위해서는 총 2가지 단계를 시행해야 한다.
```r
1. 수집한 데이터 불러오기

setwd(dirname(rstudioapi::getSourceEditorContext()$path))
options(warn=-1)

load("./03_integrated/03_apt_price.rdata")  # 실거래 자료 불러오기
head(apt_price, 2)  # 자료 확인
```
- 이때, warn=-1을 이용해 중요도가 떨어지는 경고 메세지는 무시한다.
```r
2. 결측값과 공백 제거하기

table(is.na(apt_price))  # 결측값 확인

apt_price <- na.omit(apt_price)  # 결측값 제거
table(is.na(apt_price))  # 결측값 확인

head(apt_price$price, 2)  # 매매가 확인

library(stringr)  # 문자열 처리 패키지 실행
apt_price <- as.data.frame(apply(apt_price, 2, str_trim))  # 공백 제거
# apply([적용 테이블], [1: raw, 2: col], [적용 함수])
head(apt_price$price, 2)  # 매매가 확인
```
- 결측값은 보통 NA(Not Avaliable)로 표현한다.
- 이때 데이터에 NA 값이 있는지 확인하기 위해서 is.na() 함수를 사용하는데, table() 함수를 함께 사용하면 NA가 몇 개 포함되었는지 알 수 있다.
- 또한 매매가 확인 코드를 실행해보면 문자열 데이터 앞에 공백이 있는 것을 확인할 수 있다.
- 이러한 공백을 제거하기 위해서는 stringr 패키지에 들어있는 str_trim() 함수를 사용하면 된다.

**2. 항목별 데이터 다듬기**
- 아파트 실거래 자료를 살펴보면 문자와 숫자가 섞여있는 것을 확인할 수 있다.
- 이처럼 데이터의 형태가 일관되지 않으면 분석할 때 제약이 있다.
- 따라서 항목별로 데이터를 알맞게 분석하기 위해서는 데이터의 속성을 변경해주어야 한다.
- 이렇게 항목별로 데이터를 다듬기 위해서는 총 6단계를 시행해야 한다.
```r
1. 매매 연월일 만들기

library(lubridate)  # install.packages("lubridate")
library(dplyr)  # install.packages("dplyr")
apt_price <- apt_price %>% mutate(ymd=make_date(year, month, day))  # 연월일
apt_price$ym <- floor_date(apt_price$ymd, "month")  # 연월
head(apt_price, 2)  # 자료 확인
```
- 아래 코드에서 사용된 파이프라인 연산자(%>%)는 dplyr 패키지에서 제공하는 연산자로, 복잡한 계산을 간단히 처리해준다.
- 예를 들어, 중첩 함수식을 계산하려면 안쪽부터 바깥쪽까지 연이어 결과를 구하고 대입하는 과정을 반복해야 하지만, 이렇게 하면 코드가 길어질 수밖에 없다.
- 그러나 파이프라인 연산자를 이용하면 아래와 같이 이를 직관적으로 표현할 수 있다.
<img width="584" alt="파이프라인 연산자" src="https://user-images.githubusercontent.com/62285642/194691946-070a37ad-576a-42cc-b9a0-143cc3926bb7.png">

```r
2. 매매가 변환하기

head(apt_price$price, 3)  # 매매가 확인

apt_price$price <- apt_price$price %>% sub(",","",.) %>% as.numeric()  # 쉼표 제거
head(apt_price$price, 3)  # 매매가 확인
```
- sub() 함수는 특정 문자열을 찾아내 첫번째에 해당하는 것만 대체 또는 제거할 수 있도록 해주는 함수이다.
```r
3. 주소 조합하기

head(apt_price$apt_nm, 30)

apt_price$apt_nm <- gsub("\\(.*","", apt_price$apt_nm)  # 괄호 이후 삭제
head(apt_price$apt_nm, 30)  # 아파트 이름 확인

loc <- read.csv("../sigun_code/sigun_code.csv")  # 지역 코드 불러오기
apt_price <- merge(apt_price, loc, by = 'code')  # 지역명 결합하기
apt_price$juso_jibun <- paste0(apt_price$addr_2, apt_price$dong, " ",
                               apt_price$jibun, " ", apt_price$apt_nm)  # 주소 조합
head(apt_price, 2)  # 자료 확인
```
- gsub() 함수는 특정 문자열을 모두 찾아 원하는 문자열로 대체 또는 제거할 수 있도록 해주는 함수이다.
```r
4. 건축 연도, 면적 변환하기 

head(apt_price$con_year, 3)  # 건축 연도 확인

apt_price$con_year <- apt_price$con_year %>% as.numeric()  # 건축 연도 숫자 변환
head(apt_price$con_year, 3)  # 건축 연도 확인
```
- 문자형을 숫자형으로 바꿔주기 위해서는 as.numeric() 함수를 사용한다.
```r
5. 전용 면적 변환하기 

head(apt_price$area, 3)  # 전용 면적 확인

apt_price$area <- apt_price$area %>% as.numeric() %>% round(0)  # 전용 면적 변환
head(apt_price$area, 3)  # 전용 면적 확인

apt_price$py <- round(((apt_price$price/apt_price$area) * 3.3), 0)  # 평당 가격
head(apt_price$py, 3)  # 평당 매매가 확인
```
- 소수점 자리를 반올림하여 정수로만 나타내고 싶을 때 round() 함수를 사용하며, 여기서 0은 round() 함수의 기본값을 의미한다. 
```r
6. 층수 변환하기

min(apt_price$floor)  # 층수 확인

apt_price$floor %>% as.numeric() %>% abs()  # 층수 변환
min(apt_price$floor)  # 층수 확인

apt_price$cnt <- 1  # 모든 데이터에 숫자 1 할당
head(apt_price, 2)  # 자료 확인
```
- 데이터의 최솟값을 찾고 싶을 때는 min() 함수를 사용한다. 
- abs() 함수는 절댓값을 구하는 함수로, 음수값을 모두 양수로 바꿔준다.

## 09월 28일
> 자료 수집: API 크롤러 만들기

**3. 크롤러 제작: 자동으로 자료 수집하기**
- 자료 수집을 위한 크롤러를 제작하기 위해서는 지난 1단계에 이어 총 5단계를 시행해야 한다.
```r
2. 자료 요청하고 응답받기

for (i in 1:length(url_list)) {  # 요청 목록(url_list) 반복
  raw_data[[i]] <- xmlTreeParse(url_list[i], useInternalNodes = TRUE,
                                encoding = "utf-8")  # 결과 저장
  root_Node[[i]] <- xmlRoot(raw_data[[i]])  # xmlRoot로 루트 노드 이하 추출
```
- 자료를 요청하고 응답받을 때는 URL로 요청해 XML로 응답을 받는다.
```r
3. 전체 거래 건수 확인하기

items <- root_Node[[i]][[2]][['items']]  # 전체 거래 내역(items) 추출
size <- xmlSize(items)  # 전체 거래 건수 확인
```
- 이때, 전체 거래 건수의 사이즈를 확인하고 싶다면 R Studio의 Environment 창에서 Values의 size를 확인하면 된다.
```r
4. 개별 거래 내역 추출하기

item <- list()  # 전체 거래 내역(items) 저장 임시 리스트 생성
item_temp_dt <- data.table()  # 세부 거래 내역(item) 저장 임시 테이블 생성
Sys.sleep(.1)  # 0.1초 멈춤 
for(m in 1:size)  {  # 전체 거래 건수(size)만큼 반복
  # 세부 거래 내역 분리
  item_temp <- xmlSApply(items[[m]], xmlValue)
  item_temp_dt <- data.table(year = item_temp[4],  # 거래 연도
                              month = item_temp[7],  # 거래 월
                              day = item_temp[8],  # 거래 일
                              price = item_temp[1],  # 거래 금액
                              code = item_temp[12],  # 지역 코드
                              donf_nm = item_temp[5],  # 법정동
                              jibun = item_temp[11],  # 지번
                              con_year = item_temp[3],  # 건축 연도
                              apt_nm = item_temp[6],  # 아파트 이름
                              area = item_temp[9],  # 전용면적
                              floor = item_temp[13])  # 층수
  item[[m]] <- item_temp_dt  # 분리된 거래 내역 순서대로 저장
}
apt_bind <- rbindlist(item)  # 통합 저장
```
- 크롤러를 활용하여 데이터를 수집할 때 리스트형 자료를 사용하는 경우가 많다.
- 그러나 데이터를 저장하거나 분석하려면 리스트형보다 데이터프레임형으로 변환하는 것이 편리하다.
- 따라서 위 코드에서 사용된 rbindlist()나 ldply()를 사용하면 리스트 안에 포함된 작은 데이터프레임 여러 개를 하나로 결합할 수 있다.
```r
5. 응답 내역 저장하기

  region_nm <- subset(loc, code == str_sub(url_list[i], 115, 119))$addr_1  # 지역명
  month <- str_sub(url_list[i], 130, 135)  # 연월(YYYYMM)
  path <- as.character(paste0("./02_raw_data/", region_nm, "_", month, ".csv"))
  write.csv(apt_bind, path)  # CSV 저장
  msg <- paste0("[", i, "/", length(url_list), 
                "] 수집한 데이터를 [", path,"] 에 저장합니다.")  # 알림 메세지
  cat(msg, "\n\n")
}
```
- 응답 내역을 저장해주면 아래와 같이 csv 파일이 차례대로 저장된다.
<img width="761" alt="응답 내역 저장 결과" src="https://user-images.githubusercontent.com/62285642/193393960-e86dbfe3-60d9-49a7-9eaf-954335a8860b.png">

**4. 자료 정리: 자료 통합하기**
- 자료 정리를 위해서는 총 2가지 단계를 시행해야 한다.
```r
1. CSV 파일 통합하기

setwd(dirname(rstudioapi::getSourceEditorContext()$path))  # 작업 폴더 설정
files <- dir("./02_raw_data") # 폴더 내 모든 파일명 읽기
library(plyr)  # install.packages("plyr")
apt_price <- ldply(as.list(paste0("./02_raw_data/", files)), read.csv)  # 결합
tail(apt_price, 2)  # 확인
```

## 09월 21일
> 자료 수집: API 크롤러 만들기

**2. 요청 목록 생성: 자료를 어떻게 요청할까?**
- 요청 목록을 생성하기 위해서는 먼저 자료를 요청해야 한다.
- 수집을 위한 자료를 요청하기 위해서는 총 3가지 단계를 시행해야 한다.
```r
1. 요청 목록 만들기

url_list <- list()  # 빈 리스트 만들기
cnt <- 0  # 반복문의 제어 변수 초깃값 설정
```
- 요청 목록(url_list)은 '프로토콜 + 주소 + 포트 번호 + 리소스 경로 + 요청 내역' 등 5가지 정보로 구성된다.
- 이때, 대부분은 고정된 내용이지만 요청 내역은 대상 지역과 기간이라는 2가지 조건에 따라 변하기 때문에 이러한 조건을 고려한다면 아래와 같이 중첩 for문을 이용해야 한다.
```r
2. 요청 목록 채우기

for (i in 1:nrow(loc)) {  # 외부 반복: 25개 자치구
  for (j in 1:length(datelist)) {  # 내부 반복: 12개월
    cnt <- cnt + 1  # 반복 누적 세기
    # 요청 목록 채우기 (25 X 12 = 300)
    url_list[cnt] <- paste0("http://openapi.molit.go.kr:8081/OpenAPI_ToolInstallPackage/service/rest/RTMSOBJSvc/getRTMSDataSvcAptTrade?",  # URL
                            "LAWD_CD=", loc[i, 1],  # 지역코드
                            "&DEAL_YMD=", datelist[j],  # 수집 월
                            "&numOfLows=", 100,  # 가져올 최대 자료 수
                            "&serviceKey=", service_key)  # 인증키
  }
  Sys.sleep(0.1)  # 0.1초간 멈춤
  msg <- paste0("[", i, "/", nrow(loc), "] ", loc[i, 3], 
               "의 크롤링 목록이 생성됨 => 총 [", cnt, "] 건")  # 알림 메세지
  cat(msg,"\n\n")
}
```
- 위 코드와 아래 코드에서 사용된 paste0() 함수는 자주 사용하는 함수로, 자세한 설명은 아래의 **"+) paste0()란?"** 항목에서 살펴볼 수 있다.
```r
3. 요청 목록 확인하기

length(url_list)  # 요청 목록 개수 확인
browseURL(paste0(url_list[1]))  # 정상 동작 확인(웹 브라우저 실행)
```
- browseURL() 함수를 실행시켰을 때, 웹 브라우저 화면의 <resultMsg> 태그에 "NORMAL SERVICE."라고 나오면 정상으로 동작하는 것을 확인할 수 있다.

**3. 크롤러 제작: 자동으로 자료 수집하기**
- 크롤러를 제작하기 위해서는 자료를 수집해야 하는데, 이를 위해서는 리스트를 만들어주어야 한다. 
- 따라서 응답 결과인 XML 파일을 저장할 리스트와 XML에서 개별 거래 내역만 추출하여 저장할 리스트, 개별 거래 내역을 순서대로 정리할 리스트를 만들어야 한다.
```r
1. 임시 저장 리스트 만들기

library(XML)  # install.packages("XML")
library(data.table)  # install.packages("data.table")
library(stringr)  # install.packages("stringr")

raw_data <- list()  # XML 임시 저장소
root_Node <- list()  # 거래 내역 추출 임시 저장소
total <- list()  # 거래 내역 정리 임시 저장소
dir.create("02_raw_data")  # 새로운 폴더 만들기
```

**+) paste0()란?**
- paste0 함수는 paste 함수에서 sep=''를 적용해준 것과 같이 각각의 원소를 공백없이 이어주는 함수이다.
- 이러한 paste0 함수의 기반이 되는 paste 함수에는 다양한 표현 방법이 있다. 
  1. 원소가 묶여있지 않으면 공백을 넣어 묶어준다.
  ```r
  paste(1, 2, 3, 4)
  [1] "1 2 3 4"
  ```
  2. 원소가 묶여있으면 하나씩 분리해준다.
  ```r
  test <- c(1, 2, 3, 4, 5)
  paste(test)
  [1] "1" "2" "3" "4" "5"
  ```
  3. 만일 원소들이 c()나 rep()으로 묶여있으면, 각각의 원소를 매칭시켜준다.
  ```r
  paste(c('첫', '두', '세', '네', '다섯'), rep('번째', 5))
  [1] "첫 번째"   "두 번째"   "세 번째"   "네 번째"   "다섯 번째"
  ```
  4. 한쪽만 묶인 원소는 묶인 원소의 개수만큼 출력한다.
  ```r
  paste('첫', '두', '세', '네', '다섯', rep('번째', 5))
  [1] "첫 두 세 네 다섯 번째" "첫 두 세 네 다섯 번째" "첫 두 세 네 다섯 번째"
  [4] "첫 두 세 네 다섯 번째" "첫 두 세 네 다섯 번째"
  ```
  5. 묶인 원소의 개수가 서로 다른 경우에는 긴 쪽의 원소가 모두 출력될 때까지 반복한다.
  ```r
  paste(c('첫', '두', '세', '네', '다섯'), rep('번째', 7))
  [1] "첫 번째"   "두 번째"   "세 번째"   "네 번째"   "다섯 번째" "첫 번째"   "두 번째"
  ```
- 이 외에도 paste 함수는 다양한 옵션들을 지니고 있다.
  1. sep
      - sep는 '구분하다'를 뜻하는 seperate의 약자이다.
      - sep를 이용해 paste에 나열된 각각의 원소 사이에 옵션을 적용하여 구분할 수 있다.
    ```r
    paste(1, 2, 3, 4, sep='-')  # - 로 구분하기
    [1] "1-2-3-4"
    paste('function', 'in', 'r', sep='   ')  # 공백(스페이스바)로 구분하기
    [1] "function   in   r"
    paste('문자열을', '합쳐', '주세요', sep='')  # 공백으로 구분하기(공백없음)
    [1] "문자열을합쳐주세요"
    ```
  2. collapse
      - collapse는 결과값이 두개 이상일 때, 각각의 결과값에 옵션을 주어 이어붙일 때 사용한다.
    ```r
    paste(c('첫', '두', '세', '네', '다섯'), rep('번째', 5), sep='', collapse=', ')
    [1] "첫번째, 두번째, 세번째, 네번째, 다섯번째"
  
    paste(1:10, c('st', 'nd', 'rd', rep('th', 7)), sep='', collapse = '_')     
    [1] "1st_2nd_3rd_4th_5th_6th_7th_8th_9th_10th"
    ```

## 09월 14일
> 자료 수집: API 크롤러 만들기

**1. 크롤링 준비: 무엇을 준비할까?**
- 크롤링을 시작하기 위해서는 여러가지 설정을 해주어야 한다.
- 이러한 설정을 진행하기 위한 단계로는 총 4가지가 있다.
```r
1. 작업 폴더 설정하기

install.packages("rstudioapi")  # rstudioapi 설치
setwd(dirname(rstudioapi::getSourceEditorContext()$path))  # 작업 폴더 설정
getwd()  # 작업 폴더 확인
```
- rstudioapi라는 라이브러리를 이용하면 스크립트가 저장된 위치를 작업 폴더로 쉽게 설정할 수 있다.
```r
2. 수집 대상 지역 설정하기

loc <- read.csv("../sigun_code/sigun_code.csv")  # 지역 코드
loc$code <- as.character(loc$code)  # 행정구역명 문자 변환
head(loc, 2)  # 확인
```
- 이때, head() 함수는 데이터를 가져올 때 처음 값부터 차례대로 가져오는데, 마지막 값부터 확인하고 싶다면 tail() 함수를 대신 사용하면 된다.
- 지역코드란 기초 자치 단체인 시·군·구에 할당한 코드로서 광역시·도(2자리) + 기초 시·군·구(3자리)로 이루어진 코드를 의미한다.
- 지역코드 예시는 아래와 같다.
<img width="634" alt="지역 코드 예시" src="https://user-images.githubusercontent.com/62285642/190842573-c5019527-478e-4a59-b669-8bfe143f783a.png">

```r
3. 수집 기간 설정하기

datelist <- seq(from = as.Date('2021-01-01'),  # 시작
                to = as.Date('2021-12-31'),  # 종료
                by = '1 month')  # 단위
datelist <- format(datelist, format = '%Y%m')  # 형식 변환(YYYY-MM-DD => YYYYMM)
datelist[1:3]  # 확인
```
- seq() 함수는 등차수열을 만들 때 활용하는 함수이다.
- 따라서 원하는 기간동안 일정한 간격의 데이터를 출력하기 위해서는 from - to를 이용해 수집 기간을 설정하고, by를 통해 수집 기간의 간격을 설정한다.
```r
4. 인증키 입력하기

service_key <- "인증키"  # 인증키 입력
```
- 인증키는 이전처럼 개발 계정의 상세보기 화면에서 일반 인증키(Encoding) 항목을 확인하면 된다.

## 09월 07일
> 자료 수집 전에 알아야 할 내용

**1. 자료는 어디서 구할까?**
- 자료 수집은 데이터 분석 과정의 첫 관문이다.
- 어떤 자료를 어떻게 수집할 지에 따라 분석에 소용되는 시간과 비용 그리고 결과물의 수준이 결정된다.
- 자료를 수집하기 위해서는 크롤러가 필요하며, 이를 직접 만드는 일은 까다롭다.
- 그러나 공공데이터포털 같은 곳에서는 이러한 데이터를 다양하게 이용할 수 있도록 API를 제공한다.

**+) 공공데이터란?**
- 공공기관이 법령에 따라 생성, 수집하는 전자적 형태의 정보로써 개방 가능한 모든 데이터를 의미한다.
- 이러한 공공데이터를 한 곳에 모아 제공하는 통합 플랫폼이 바로 [공공데이터포털](https://www.data.go.kr/)이다.

**2. API 인증키 얻기**
- 공공데이터포털에서 인증키를 발급받기 위해서는 공공데이터포털에 접속하여 회원가입 및 로그인을 해야한다.
- API 인증키를 얻기 위해서는 총 2가지 단계를 시행해야 한다.
```
1. API 활용 신청하기
  - 공공데이터포털 첫 화면의 검색란에 필요한 자료 입력하기
  → 검색 결과 화면의 [오픈 API] 탭 클릭하기
  → 목록에서 필요한 자료를 찾은 후, 오른쪽의 <활용신청> 클릭하기
  → 'OpenAPI 개발계정 신청' 화면에서 심의 여부 확인 후, 활용목적 작성하기
  → 모든 정보 작성 및 확인 후 확인 버튼 누르기
```
- 이때, 'OpenAPI 개발계정 신청' 화면에서 심의 여부를 확인해보면 '자동승인'이라고 적혀있는 경우가 있다.
- 이 경우, 따로 심사하지 않고 신청하면 곧바로 사용할 수 있다.
- 그러나 신청한 API는 바로 호출이 불가능하며, 1~2시간 후 호출 가능하다.
```
2. 승인 및 인증키 확인하기
  - 포털 사이트 위쪽 메뉴에서 [마이 페이지] 클릭하기
  → 신청한 자료명 앞에 [승인]이 붙어있는지 확인하기
  → 승인 완료된 자료를 클릭 후, 상세보기 화면에서 일반 인증키(Encoding) 확인하기
```
- 마이 페이지의 개발 계정 화면에서는 신청과 활용, 중지 건수를 확인할 수 있는데, 이때 신청한 자료가 승인되면 활용 건수로 바뀌고 목록에서 해당 자료명 앞에 [승인]이 붙는다.
- 상세보기 화면의 다양한 정보 중 일반 인증키(Encoding) 항목의 데이터가 API를 이용할 때 필요한 인증키로, 각자 발급받은 이 고유한 인증키로 서버에 자료를 요청한다.

**3. API에 자료 요청하기**
- API에 자료를 요청하기 위해서는 총 3가지 단계를 시행해야 한다.
- 이 단계를 시행하기 위해서는 아래의 문서가 필요하다.<br>
  → 참고문서 : [아파트 매매 신고정보 조회 기술문서.hwp](https://www.data.go.kr/data/15058747/openapi.do)
```
1. 서비스 URL 확인하기
 - 기술 문서 4페이지의 상세 기능 정보에서 'Call Back URL' 항목의 주소 확인하기
```
```
2. 요청 변수 확인하기
  - 기술 문서 4페이지의 요청 메시지 명세에서 LAWD_CD, DEAL_YMD, serviceKey 3가지 정보 확인하기
```
- 위 정보를 조합해 하나의 요청 URL로 만들어서 API에 요청하면 서버가 해당 자료를 찾아서 보내준다.
```
3. 요청 URL 만들기
  - 2단계에서 확인한 지역 코드와 거래 연월 그리고 발급받은 인증키 채워넣기
```
- 데이터 요청을 위한 URL 작성 예시는 아래와 같다.
```
서비스URL?LAWD_CD=지역코드&DEAL_YMD=거래연월&serviceKey=인증키
```
- 이렇게 만든 URL을 웹 브라우저 주소 창에 입력한 후 Enter를 누르면 서버로부터 XML 형태로 응답받은 데이터를 확인할 수 있다.

**4. API 응답 확인하기**
- API 응답을 확인하기 위해서는 총 2가지 단계를 시행해야 한다.
```
1. 응답 내역 알아보기
  - API로 자료를 요청해서 XML 형태로 응답받은 데이터의 응답 상태와 응답 내역 구성 확인하기
```
- XML은 컴퓨터끼리 데이터를 원활하게 전달하는 것을 목적으로 만든 언어이며, 모든 XML 데이터는 루트 노드에서 출발하며 부모-자식 관계로 연결되어 있다.
- API에서 자료를 요청할 때 얻을 수 있는 데이터가 바로 이러한 XML 형태이다.
```
2. XML 형태의 응답 내역 확인하기
  - 요청 URL과 응답 결과 확인하기
```
- 요청 URL과 응답 결과 예시는 다음과 같다.
<img width="749" alt="XML 응답 내역 예시" src="https://user-images.githubusercontent.com/62285642/189472658-ffdb3d5e-2631-4cb9-b106-a1992ec8159a.png">

> 텍스트 마이닝과 워드 클라우드 활용

**1. 텍스트 마이닝과 워드 클라우드**
- 텍스트 마이닝이란 비정형 텍스트에서 의미 있는 정보를 찾아내는 mining 기술을 의미한다.
- 단어 분류 또는 문법적 구조 분석 등의 자연언어 처리 기술에 기반한다.
- 문서 분류, 관련있는 문서들의 군집화, 정보의 추출, 문서 요약 등에 활용된다.

**2. 지역별 인구 변화 수에 대한 워드 클라우드 출력**
- 워드클라우드를 이용하여 통계청에 있는 다양한 자료들 중, '시·군·구별 이동자 수' 자료를 이용하여 지역별 전입과 전출에 의한 순이동 인구수를 비교할 수 있다.
- 워드클라우드를 생성하는 코드는 아래와 같다.
```r
install.packages("wordcloud") 
library(wordcloud)

word <- c("인천광역시", "강화군", "웅진군")  # 단어 할당
frequency <- c(651, 85, 61)  # 단어별 빈도 할당

wordcloud(word, frequency, colors="blue",family="AppleGothic")  # 워드클라우드 출력
```