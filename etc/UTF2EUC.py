import pandas as pd

source = pd.read_csv("누적확진자.csv", encoding = "UTF-8")
source.to_csv("누적확진자.csv", encoding="EUC-KR")

source = pd.read_csv("일일확진자.csv", encoding = "UTF-8")
source.to_csv("일일확진자.csv", encoding="EUC-KR")