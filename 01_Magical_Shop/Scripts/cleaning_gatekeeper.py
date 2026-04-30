import pandas as pd
from datetime import datetime
import os

# フォルダパスの設定
RAW_PATH = '01_Raw/20260430_raw_sales.csv'
MASTER_PATH = 'Master/m_items.csv'
OUTPUT_PATH = '02_Cleaned/sales_cleaned.csv'

def main():
# データの読み込み
    df_sales = pd.read_csv(RAW_PATH)
    df_items = pd.read_csv(MASTER_PATH)

    print("--- ゲートキーパー、処理を開始します！ ---")

    # 処理①：文字列の前後にある余計なスペースを消し去る
    df_sales['item_id'] = df_sales['item_id'].str.strip()

    # 処理②：単価0円をマスタから復元する
    # 一旦マスタと結合して、正しい価格(price)を持ってくる
    df_merged = pd.merge(df_sales, df_items[['item_id', 'price']], on='item_id', how='left')

    # もしunit_priceが0なら、マスタのpriceを採用する
    df_merged['unit_price'] = df_merged.apply(
        lambda x: x['price'] if x['unit_price'] == 0 else x['unit_price'], axis=1
    )

    # 処理③：売上金額(amount)を計算する
    df_merged['amount'] = df_merged['quantity'] * df_merged['unit_price']

    # 処理④：監査列（処理日時）を追加
    df_merged['updated_at'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # 不要な列を整理して保存
    final_columns = ['sales_id', 'timestamp', 'staff_id', 'item_id', 'quantity', 'unit_price', 'amount', 'updated_at']
    df_cleaned = df_merged[final_columns]

    # Cleanedフォルダへ出力（上書き保存）
    df_cleaned.to_csv(OUTPUT_PATH, index=False)

    print(f"--- クレンジング完了！ {OUTPUT_PATH} を確認してください ---")

if __name__ == "__main__":
    main()