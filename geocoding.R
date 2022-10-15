# 1단계: 카카오 로컬 API 키 발급

# 2단계: 고유한 주소만 추출
setwd(dirname(rstudioapi::getSourceEditorContext()$path))
load("./04_pre_process/04_pre_process.rdata")
apt_juso <- data.frame(apt_price$juso_jibun)
apt_juso <- data.frame(apt_juso[!duplicated(apt_juso), ])
head(apt_juso, 2)

#---

# 1단계: 지오 코딩 준비
add_list <- list()
cnt <- 0
kakao_key = "REST API 키"

# 라이브러리 불러오기
# install.packages("httr")
# install.packages("RJSONIO")
# install.packages("data.table")
# install.packages("dplyr")
library(httr)
library(RJSONIO)
library(data.table)
library(dplyr)

# for 반복문과 예외 처리 시작
for (i in 1:nrow(apt_juso)) {
  tryCatch (
    {
      # 주소 요청
      lon_lat <- GET(url = 'https://dapi.kakao.com/v2/local/search/address.json',
                     query = list(query = apt_juso[i,]),
                     add_headers(Authorization = paste0("KakaoAK ", kakao_key)))
      # 위경도 정보 추출
      coordxy <- lon_lat %>% content(as = 'text') %>% RJSONIO::fromJSON()
      # 위경도 정보 저장
      cnt = cnt + 1
      add_list[[cnt]] <- data.table(apt_juso = apt_juso[i,],
                                    coord_x = coordxy$documents[[1]]$x,
                                    coord_y = coordxy$documents[[1]]$y)
      # 진행 상황 알림 메시지 출력
      message <- paste0("[", i, "/", nrow(apt_juso), "] 번째 (",
                        round(i/nrow(apt_juso) * 100, 2), " %) [", apt_juso[i,], "] 지오 코딩 중입니다: X= ", 
                        add_list[[cnt]]$coord_x, " / Y= ", add_list[[cnt]]$coord_y)
      cat(message, "\n\n")
    # for 반복문과 예외 처리 종료
    }, error = function(e){cat("ERROR: ", conditionMessage(e), "\n")}
  )
}

# 2단계: 지오 코딩 결과 저장
juso_geocoding <- rbindlist(add_list)  
juso_geocoding$coord_x <- as.numeric(juso_geocoding$coord_x)  
juso_geocoding$coord_y <- as.numeric(juso_geocoding$coord_y)
juso_geocoding <- na.omit(juso_geocoding) 
dir.create("./05_geocoding")  
save(juso_geocoding, file="./05_geocoding/05_juso_geocoding.rdata")
write.csv(juso_geocoding, "./05_geocoding/05_juso_geocoding.csv")
