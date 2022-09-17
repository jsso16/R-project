# 1단계: 작업 폴더 설정
install.packages("rstudioapi")
setwd(dirname(rstudioqpi::getSourceEditorContext()$path))
getwd()

# 2단계: 수집 대상 지역 설정
loc <- read.csv("/Users/jeonsojin/R/R-project/sigun_code.csv")
loc$code <- as.character(loc$code)
head(loc, 2)

# 3단계: 수집 기간 설정
datelist <- seq(from = as.Date('2021-01-01'),
                to = as.Date('2021-12-31'),
                by = '1 month')
datelist <- format(datelist, format = '%Y%m')
datelist[1:3]

# 4단계: 인증키 입력
service_key <- "인증키"