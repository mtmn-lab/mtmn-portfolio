from pathlib import Path
import pandas as pd
import shutil
from datetime import datetime

# ==============================
# フォルダ設定
# ==============================

BASE_DIR = Path(__file__).resolve().parents[2]

input_dir = BASE_DIR / "data/01_input"
output_dir = BASE_DIR / "data/02_output"

print(input_dir)




# # inputフォルダ
# input_dir = Path("../clean_logs/01_input/")

# # CSV一覧取得
# csv_files = list(input_dir.glob("*.csv"))

# #最新CSV一覧取得
# latest_files = max(csv_files, key=lambda f: f.stat().st_mtime)

# print(f"読み込みファイル:{latest_files.name}")

# #CSV読み込み
# df = pd.read_csv(latest_files)

# # 最初の5行を確認
# print(df.head())



# # レジ実績データを読み込む
# df = pd.read_csv("../data/raw/fact_magical_logs_v2.csv")



# # 型確認
# print(df.info())

# # 日付型変換
# #df["log_data"] = pd.to_datetime(df["log_data"])

# # amount数値化
# df["amount"] = pd.to_numeric(df["amount"])

# # type確認
# print(df["type"].unique())

# # 整形後csvデータ出力
# print("csv export sutart")
# df.to_csv("../data/processed/fact_magical_logs_clean.csv", index = False )
# print("csv export finished")