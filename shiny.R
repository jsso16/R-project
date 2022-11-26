# 1단계: 샤이니 기본 구조 이해
# install.packages(shiny)
library(shiny)
ui <- fluidPage("사용자 인터페이스")
server <- function(input, output, session) { } 
shinyApp(ui, server)

# 2단계: 샤이니가 제공하는 샘플 확인하기
library(shiny)
runExample()

# 첫 번째 샘플 실행하기
runExample("01_hello")

# 3단계: 01_hello 샘플의 사용자 인터페이스 부분
library(shiny)
ui <- fluidPage(
  titlePanel("샤이니 1번 샘플"),
  sidebarLayout(
    sidebarPanel(
      sliderInput(inputId = "bins",
                  label = "막대(bin) 개수: ",
                  min = 1, max = 50,
                  value = 30)),
    mainPanel(
      plotOutput(outputId = "distPlot")
    )
  )
)

# 4단계: 01_hello 샘플의 서버 부분
server <- function(input, output, session) {
  output$distPlot<- renderPlot({
    x <- faithful$waiting
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    hist(x, breaks = bins, col = "#75AADB", border = "white",
         xlab = "다음 분출 때까지 대기 시간(분)",
         main = "대기 시간 히스토그램")
  })
}

shinyApp(ui, server)
rm(list = ls())

#---

# 1단계: 데이터 입력
library(shiny)
ui <- fluidPage(
  sliderInput("range", "연비", min = 0, max = 35, value = c(0, 10))
)
server <- function(input, output, session) {}

shinyApp(ui, server)

# 2단계: 데이터 출력
library(shiny)
ui <- fluidPage(
  sliderInput("range", "연비", min = 0, max = 35, value = c(0, 10)),
  textOutput("value")
)
server <- function(input, output, session) {
  output$value <- renderText((input$range[1] + input$range[2]))
}

shinyApp(ui, server)

# 3단계: 렌더링 함수의 중요성
library(shiny)
ui <- fluidPage(
  sliderInput("range", "연비", min = 0, max = 35, value = c(0, 10)),
  textOutput("value")
)
server <- function(input, output, session) {
  output$value <- (input$range[1] + input$range[2])
}

shinyApp(ui, server)

#---

# 1단계: 데이터 준비
# install.packages("DT")
library(DT)
library(ggplot2)
mpg <- mpg
head(mpg)

# 2단계: 반응식 작성
library(shiny)
ui <- fluidPage(
  sliderInput("range", "연비", min = 0, max = 35, value = c(0, 10)),
  DT::dataTableOutput("table")
)
server <- function(input, output, session) {
  cty_sel = reactive({
    cty_sel = subset(mpg, cty >= input$range[1] & cty <= input$range[2])
    return(cty_sel)
  })
  output$table <- DT::renderDataTable(cty_sel())
}

shinyApp(ui, server)

#---

# 1단계: 단일 페이지 화면
library(shiny)
ui <- fluidPage(
  fluidRow(
    column(9, div(style = "height: 450px; border: 4px solid red;", "폭 9")),
    column(3, div(style = "height: 450px; border: 4px solid purple;", "폭 3")),
    column(12, div(style = "height: 400px; border: 4px solid blue;", "폭 12"))
  )
)
server <- function(input, output, session) { }

shinyApp(ui, server)

# 2단계: 탭 페이지 추가
library(shiny)
ui <- fluidPage(
  fluidRow(
    column(9, div(style = "height: 450px; border: 4px solid red;", "폭 9")),
    column(3, div(style = "height: 450px; border: 4px solid red;", "폭 3")),
    
    tabsetPanel(
      tabPanel("탭1",
               column(4, div(style = "height: 300px; border: 4px solid red;", "폭 4")),
               column(4, div(style = "height: 300px; border: 4px solid red;", "폭 4")),
               column(4, div(style = "height: 300px; border: 4px solid red;", "폭 4"))
      ),
      tabPanel("탭2", div(style = "height: 300px; border: 4px solid blue;", "폭 12"))
    )
  )
)
server <- function(input, output, session) { }

shinyApp(ui, server)
