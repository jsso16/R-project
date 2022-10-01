# R-project - 602277119 전소진
Open data R with Shiny 2022

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

  region_nm <-subset(loc, code == str_sub(url_list[i], 115, 119))$addr_1  # 지역명
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