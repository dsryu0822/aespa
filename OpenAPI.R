# install.packages("httr") # HTTP통신을 위한 패키지 설치
# install.packages("rjson")

library(httr)
library(rjson)

# 결과코드	resultCode	2	필수	00	결과코드
# 결과메시지	resultMsg	50	필수	OK	결과메시지
# 한 페이지 결과 수	numOfRows	4	필수	10	한 페이지 결과 수
# 페이지 번호	pageNo	4	필수	1	페이지번호
# 전체 결과 수	totalCount	4	필수	3	전체 결과 수
# 게시글번호(국내 시도별 발생현황 고유값)	SEQ	30	필수	130	게시글번호(국내 시도별 발생현황 고유값)
# 등록일시분초	CREATE_DT	30		2020-04-10 11:15:59.026	등록일시분초
# 사망자 수	DEATH_CNT	15		204	사망자 수
# 시도명(한글)	GUBUN	30		부산	시도명(한글)
# 시도명(중국어)	GUBUN_CN	30		null	시도명(중국어)
# 시도명(영어)	gubunEn	30		null	시도명(영어)
# 전일대비 증감 수	INC_DEC	15		39	전일대비 증감 수
# 격리 해제 수	ISOL_CLEAR_CNT	15		6973	격리 해제 수
# 10만명당 발생률	QUR_RATE	30		20.10	10만명당 발생률
# 기준일시	STD_DAY	30		2020년 3월 13일 00시	기준일시
# 수정일시분초	UPDATE_DT	30		null	수정일시분초
# 확진자 수	DEF_CNT	15	옵션	13561	확진자 수
# 격리중 환자수	ISOL_ING_CNT	15	옵션	9	격리중 환자수
# 해외유입 수	OVER_FLOW_CNT	15	옵션	14	해외유입 수
# 지역발생 수	LOCAL_OCC_CNT	15	옵션	7	지역발생 수

ServiceKetemp= "0BJn5q6inVyTwBNkIUraw_data06W2zgc3TVyEuCZMYlULu0qmW9tLwMd0Zg0fcfKCM7%2BWMdrQLmp08B0pdPWraw_dataYe0eU7A%3D%3D"
# ServiceKetemp= "0BJn5q6inVyTwBNkIUraw_data06W2zgc3TVyEuCZMYlULu0qmW9tLwMd0Zg0fcfKCM7+WMdrQLmp08B0pdPWraw_dataYe0eU7A=="

OpenAPI_url = paste0("http://openapi.data.go.kr/openapi/service/rest/Covid19/getCovid19SidoInfStateJson?ServiceKey=", ServiceKey)

query= paste0(
    OpenAPI_url,
    "&pageNo=1",
    "&numOfRows=10",
    "&startCreateDt=20200304",
    "&endCreateDt=20210825"
)
raw_data = GET(query); raw_data
str(raw_data)

ITEM <- content(raw_data)$response$body$items$item
temp <- data.frame("stdDay", "gubun", "defCnt")
colnames(temp) <- c("stdDay", "gubun", "defCnt")
# temp<- rbind(temp, unlist(ITEM[[1]]))
# colnames(temp) <- names(unlist(ITEM[[1]]))
# for(i in 1:10){
for(i in 1:length(ITEM)){
    try(temp[i,] <- data.frame(ITEM[[i]]$stdDay,ITEM[[i]]$gubun,ITEM[[i]]$defCnt))
}
# temp<-temp[c("stdDay", "gubun", "defCnt")]

write.csv(temp, "korea.csv", row.names = FALSE, fileEncoding = "UTF-8")