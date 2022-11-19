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
