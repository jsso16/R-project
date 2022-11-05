# 1단계: 작업 폴더 설정
# install.packages("rstudioapi")
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
getwd()

# 2단계: 수집 대상 지역 설정
loc <- read.csv("./sigun_code.csv")
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

# 2단계: URL 요청 - XML 응답
for (i in 1:length(url_list)) {
  raw_data[[i]] <- xmlTreeParse(url_list[i], useInternalNodes = TRUE,
                                encoding = "utf-8")
  root_Node[[i]] <- xmlRoot(raw_data[[i]])
  
  # 3단계: 전체 거래 건수 확인
  items <- root_Node[[i]][[2]][['items']]
  size <- xmlSize(items)
  
  # 4단계: 거래 내역 추출
  item <- list()
  item_temp_dt <- data.table()
  Sys.sleep(.1)
  for(m in 1:size)  {
    item_temp <- xmlSApply(items[[m]], xmlValue)
    item_temp_dt <- data.table(year = item_temp[4],
                               month = item_temp[7],
                               day = item_temp[8],
                               price = item_temp[1],
                               code = item_temp[12],
                               donf_nm = item_temp[5],
                               jibun = item_temp[11],
                               con_year = item_temp[3],
                               apt_nm = item_temp[6],
                               area = item_temp[9],
                               floor = item_temp[13])
    item[[m]] <- item_temp_dt
  }
  apt_bind <- rbindlist(item)
  
  # 5단계: 응답 내역 저장
  region_nm <- subset(loc, code == str_sub(url_list[i], 115, 119))$addr_1
  month <- str_sub(url_list[i], 130, 135)
  path <- as.character(paste0("./02_raw_data/", region_nm, "_", month, ".csv"))
  write.csv(apt_bind, path)
  msg <- paste0("[", i, "/", length(url_list), 
                "] 수집한 데이터를 [", path,"] 에 저장합니다.")
  cat(msg, "\n\n")
}

#---

# 1단계: CSV 파일 통합
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
files <- dir("./02_raw_data")
# install.packages("plyr")
library(plyr)
apt_price <- ldply(as.list(paste0("./02_raw_data/", files)), read.csv)
tail(apt_price, 2)

# 2단계: RDATA와 CSV 형식으로 저장
dir.create("./03_integrated")
save(apt_price, file = "./03_integrated/03_apt_price.rdata")
write.csv(apt_price, "./03_integrated/03_apt_price.csv")
