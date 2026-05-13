import pandas as pd

# レジ実績データを読み込む
df = pd.read_csv("../data/raw/fact_magical_logs_v2.csv")

# 最初の5行を確認
print(df.head())

# 型確認
print(df.info())

# 日付型変換
#df["log_data"] = pd.to_datetime(df["log_data"])

# amount数値化
df["amount"] = pd.to_numeric(df["amount"])

# type確認
print(df["type"].unique())

# 整形後csvデータ出力
print("csv export sutart")
df.to_csv("../data/processed/fact_magical_logs_clean.csv", index = False )
print("csv export finished")