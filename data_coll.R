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

#---

# 1단계: 요청 목록 만들기
url_list <- list()
cnt <- 0

# 2단계: 요청 목록 채우기
for (i in 1:nrow(loc)) {
  for (j in 1:length(datelist)) {
    cnt <- cnt + 1
    
    url_list[cnt] <- paste0("http://openapi.molit.go.kr:8081/OpenAPI_ToolInstallPackage/service/rest/RTMSOBJSvc/getRTMSDataSvcAptTrade?",
                            "LAWD_CD=", loc[i, 1],
                            "&DEAL_YMD=", datelist[j],
                            "&numOfLows=", 100,
                            "&serviceKey=", service_key)
  }
  Sys.sleep(0.1)
  msg <- paste0("[", i, "/", nrow(loc), "] ", loc[i, 3], 
               "의 크롤링 목록이 생성됨 => 총 [", cnt, "] 건")
  cat(msg,"\n\n")
}

# 3단계: 요청 목록 동작 확인
length(url_list)
browseURL(paste0(url_list[1]))

#---

# 1단계: 임시 저장 리스트 생성
# install.packages("XML")
# install.packages("data.table")
# install.packages("stringr")
library(XML)
library(data.table)
library(stringr)

raw_data <- list()
root_Node <- list()
total <- list()
dir.create("02_raw_data")
