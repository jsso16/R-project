# 1단계: 아파트 실거래 자료 불러오기
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
options(warn=-1)

load("./03_integrated/03_apt_price.rdata")
head(apt_price, 2)

# 2단계: 결측값 확인
table(is.na(apt_price))

# 결측값 제거 후 확인
apt_price <- na.omit(apt_price)
table(is.na(apt_price))

# 공백 확인
head(apt_price$price, 2)

# 공백 제거와 확인
library(stringr)
apt_price <- as.data.frame(apply(apt_price, 2, str_trim))
head(apt_price$price, 2)

#---

# 1단계: 매매 연월일, 연월 데이터 만들기
# install.packages("lubridate")
library(lubridate)
# install.packages("dplyr")
library(dplyr)
apt_price <- apt_price %>% mutate(ymd=make_date(year, month, day))
apt_price$ym <- floor_date(apt_price$ymd, "month")
head(apt_price, 2)

# 2단계: 매매가 확인
head(apt_price$price, 3)

# 매매가 변환(문자 → 숫자)
apt_price$price <- apt_price$price %>% sub(",","",.) %>% as.numeric()
head(apt_price$price, 3)

# 3단계: 아파트 이름 현황
head(apt_price$apt_nm, 30)

# 괄호 이후 삭제
apt_price$apt_nm <- gsub("\\(.*","", apt_price$apt_nm)
head(apt_price$apt_nm, 30)

# 주소 조합
loc <- read.csv("/Users/jeonsojin/R/R-project/sigun_code.csv")
apt_price <- merge(apt_price, loc, by = 'code') 
apt_price$juso_jibun <- paste0(apt_price$addr_2, apt_price$dong, " ",
                               apt_price$jibun, " ", apt_price$apt_nm)
head(apt_price, 2)

# 4단계: 건축 연도 현황
head(apt_price$con_year, 3)

# 건축 연도 변환(문자 → 숫자)
apt_price$con_year <- apt_price$con_year %>% as.numeric()
head(apt_price$con_year, 3)

# 5단계: 전용 면적 현황
head(apt_price$area, 3)

# 전용 면적 변환(문자 → 숫자)
apt_price$area <- apt_price$area %>% as.numeric() %>% round(0)
head(apt_price$area, 3)

# 평당 매매가 만들기
apt_price$py <- round(((apt_price$price/apt_price$area) * 3.3), 0)
head(apt_price$py, 3)

# 6단계: 층수 현황
min(apt_price$floor)

# 층수 변환(문자 → 숫자)
apt_price$floor %>% as.numeric() %>% abs()
min(apt_price$floor)

# 카운트 변수 추가
apt_price$cnt <- 1
head(apt_price, 2)

#---

# 1단계: 칼럼 추출
apt_price <- apt_price %>% select(ymd, ym, year, code, addr_1, apt_nm,
                                  juso_jibun, price, con_year, area, floor, py, cnt)
head(apt_price, 2)

# 2단계: 칼럼 추출 및 저장
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
dir.create("./04_pre_process")
save(apt_price, file = "./04_pre_process/04_pre_process.rdata")
write.csv(apt_price, "./04_pre_process/04_pre_process.csv")
