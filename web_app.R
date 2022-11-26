# 1단계: 데이터 불러오기
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./06_geodataframe/06_apt_price.rdata")
library(sf)
bnd <- st_read("./01_code/sigun_bnd/seoul.shp")
load("./07_map/07_kde_high.rdata")
load("./07_map/07_kde_hot.rdata")
grid <- st_read("./01_code/sigun_grid/seoul.shp")

# 2단계: 마커 클러스터링 설정
pnct_10 <- as.numeric(quantile(apt_price$py, probs=seq(.1, .9, by = .1))[1])
pnct_90 <- as.numeric(quantile(apt_price$py, probs=seq(.1, .9, by = .1))[9])
load("./01_code/circle_marker/circle_marker.rdata")
circle.colors <- sample(x=c("red", "green", "blue"), size=1000, replace=TRUE)

# 3단계: 반응형 지도 만들기
library(leaflet)
library(purrr)
library(raster)
leaflet() %>%
  addTiles(options = providerTileOptions(minZoom = 9, maxZoom = 18)) %>%
  addRasterImage(raster_high,
                 colors = colorNumeric(c("blue", "green", "yellow", "red"), 
                                       values(raster_high), na.color = "transparent"), opacity = 0.4, 
                 group = "2021 최고가") %>%
  addRasterImage(raster_hot,
                 colors = colorNumeric(c("blue", "green", "yellow", "red"), 
                                       values(raster_hot), na.color = "transparent"), opacity = 0.4, 
                 group = "2021 급등지") %>%
  addLayersControl(baseGroups = c("2021 최고가", "2021 급등지"),
                   options = layersControlOptions(collapsed = FALSE)) %>%
  addPolygons(data = bnd, weight = 3, stroke = T, color = "red", 
              fillOpacity = 0) %>%
  addCircleMarkers(data = apt_price, lng = unlist(map(apt_price$geometry, 1)),
                   lat = unlist(map(apt_price$geometry, 2)), radius = 10, stroke = FALSE,
                   fillOpacity = 0.6, fillColor = circle.colors, weight = apt_price$py,
                   clusterOptions = markerClusterOptions(iconCreateFunction=JS(avg.formula)))

#---

# 1단계: 그리드 필터링
grid <- st_read("./01_code/sigun_grid/seoul.shp")
grid <- as(grid, "Spatial"); grid <- as(grid, "sfc")
grid <- grid[which(sapply(st_contains(st_sf(grid), apt_price), length) > 0)]
plot(grid)

# 2단계: 반응형 지도 모듈화
m <- leaflet() %>%
  addTiles(options = providerTileOptions(minZoom = 9, maxZoom = 18)) %>%
  addRasterImage(raster_high,
                 colors = colorNumeric(c("blue", "green", "yellow", "red"), 
                                       values(raster_high), na.color = "transparent"), opacity = 0.4, 
                 group = "2021 최고가") %>%
  addRasterImage(raster_hot,
                 colors = colorNumeric(c("blue", "green", "yellow", "red"), 
                                       values(raster_hot), na.color = "transparent"), opacity = 0.4, 
                 group = "2021 급등지") %>%
  addLayersControl(baseGroups = c("2021 최고가", "2021 급등지"),
                   options = layersControlOptions(collapsed = FALSE)) %>%
  addPolygons(data = bnd, weight = 3, stroke = T, color = "red", 
              fillOpacity = 0) %>%
  addCircleMarkers(data = apt_price, lng = unlist(map(apt_price$geometry, 1)),
                   lat = unlist(map(apt_price$geometry, 2)), radius = 10, stroke = FALSE,
                   fillOpacity = 0.6, fillColor = circle.colors, weight = apt_price$py,
                   clusterOptions = markerClusterOptions(iconCreateFunction=JS(avg.formula))) %>%
  leafem::addFeatures(st_sf(grid), layerId = ~seq_len(length(grid)), color = "grey")
m

# 3단계: 샤이니와 mapedit으로 애플리케이션 구현
library(shiny)
# install.packages("mapedit")
library(mapedit)
library(dplyr)
ui <- fluidPage(
  selectModUI("selectmap"),
  "선택은 할 수 있지만 아무런 반응이 없습니다."
)
server <- function(input, output) {
  callModule(selectMod, "selectmap", m)
}

shinyApp(ui, server)

# 4단계: 반응식 추가
ui <- fluidPage(
  selectModUI("selectmap"),
  textOutput("sel")
)
server <- function(input, output, session) {
  df <- callModule(selectMod, "selectmap", m)
  output$sel <- renderPrint({df()[1]})
}

shinyApp(ui, server)

#---

# 1단계: 사용자 인터페이스 설정
# install.packages("DT")
library(DT)
ui <- fluidPage(
  fluidRow(
    column(9, selectModUI("selectmap"), div(style = "height: 45px")),
    column(3, 
           sliderInput("range_area", "전용 면적", sep = "", min = 0, max = 350, 
                       value = c(0, 200)),
           sliderInput("range_time", "건축 연도", sep = "", min = 1960, max = 2020, 
                       value = c(1980, 2020)),
    ),
    column(12, dataTableOutput(outputId = "table"), div(style = "height: 200px"))
  )
)

# 2단계: 슬라이더 입력 필터링
server <- function(input, output, session) {
  apt_sel = reactive({
    apt_sel = subset(apt_price, con_year >= input$range_time[1] & 
                       con_year <= input$range_time[2] & area >= input$range_area[1] & 
                       area <= input$range_area[2])
    return(apt_sel)})
  
  # 3단계: 그리드 선택 저장
  g_sel <- callModule(selectMod, "selectmap",
                      leaflet() %>% 
                        addTiles(options = providerTileOptions(minZoom = 9, maxZoom = 18)) %>% 
                        addRasterImage(raster_high, 
                                       colors = colorNumeric(c("blue", "green","yellow","red"), 
                                                             values(raster_high), na.color = "transparent"), opacity = 0.4, 
                                       group = "2021 최고가") %>%
                        addRasterImage(raster_hot, 
                                       colors = colorNumeric(c("blue", "green","yellow","red"), 
                                                             values(raster_hot), na.color = "transparent"), opacity = 0.4, 
                                       group = "2021 급등지") %>%
                        addLayersControl(baseGroups = c("2021 최고가", "2021 급등지"), 
                                         options = layersControlOptions(collapsed = FALSE)) %>%   
                        addPolygons(data=bnd, weight = 3, stroke = T, color = "red", 
                                    fillOpacity = 0) %>%
                        addCircleMarkers(data = apt_price, lng =unlist(map(apt_price$geometry,1)), 
                                         lat = unlist(map(apt_price$geometry,2)), radius = 10, stroke = FALSE, 
                                         fillOpacity = 0.6, fillColor = circle.colors, weight=apt_price$py, 
                                         clusterOptions=markerClusterOptions(iconCreateFunction=JS(avg.formula))) %>%
                        leafem::addFeatures(st_sf(grid),layerId= ~seq_len(length(grid)),
                                            color='grey'))
  
  # 4단계: 선택에 따른 반응 결과 저장
  rv <- reactiveValues(intersect=NULL, selectgrid=NULL) 
  observe({
    gs <- g_sel() 
    rv$selectgrid <- st_sf(grid[as.numeric(gs[which(gs$selected==TRUE),"id"])])
    if (length(rv$selectgrid) > 0) {
      rv$intersect <- st_intersects(rv$selectgrid, apt_sel())
      rv$sel <- st_drop_geometry(apt_price[apt_price[unlist(rv$intersect[1:10]),],])
    } else {
      rv$intersect <- NULL
    }
  })
  
  # 5단계: 반응 결과 렌더링   
  output$table <- DT::renderDataTable({
    dplyr::select(rv$sel, ymd, addr_1, apt_nm, price, area, floor, py) %>%
      arrange(desc(py))}, extensions = 'Buttons', options = list(dom = 'Bfrtip',
                                                                 scrollY = 300, scrollCollapse = T, paging = TRUE, 
                                                                 buttons = c('excel')))
}

# 6단계: 애플리케이션 실행
shinyApp(ui, server)
