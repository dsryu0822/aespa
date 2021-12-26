import requests
import json
import pandas as pd
from pandas import json_normalize

response = requests.request("GET", "https://api.covid19api.com/countries", headers={}, data={})

Country_ = json_normalize(json.loads(response.text))["Country"]
Province_ = ["Tokyo"]

# url = "https://api.covid19api.com/live/country/" + Country_[0]
url = "https://api.covid19api.com/live/province/" + Province_[0]

payload={}
headers = {}

response = requests.request("GET", url, headers=headers, data=payload)
info = json.loads(response.text)
df = json_normalize(info); df

df.Active