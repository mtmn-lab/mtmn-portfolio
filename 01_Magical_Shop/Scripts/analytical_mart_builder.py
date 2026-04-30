import pandas as pd

# 1. 使うデータの場所（パス）を指定
CLEANED_SALES = '02_Cleaned/sales_cleaned.csv'
MASTER_ITEMS = 'Master/m_items.csv'
MASTER_STAFFS = 'Master/m_staffs.csv'
MASTER_STORES = 'Master/m_stores.csv'
OUTPUT_PATH = '03_Curated/analytical_mart.csv'

def main():
    # 各データの読み込み（電子台帳にコピー）
    df_sales = pd.read_csv(CLEANED_SALES)
    df_items = pd.read_csv(MASTER_ITEMS)
    df_staffs = pd.read_csv(MASTER_STAFFS)
    df_stores = pd.read_csv(MASTER_STORES)

    print("--- 分析用テーブルの構築（ガッチャンコ）を開始します！ ---")

    # 処理①：商品情報をくっつける（item_idを目印にする）
    # item_name（名前）と category（カテゴリ）を持ってくる
    df_mart = pd.merge(df_sales, df_items[['item_id', 'item_name', 'category']], on='item_id', how='left')

    # 処理②：店員情報をくっつける（staff_idを目印にする）
    # staff_name（名前）と store_id（店ID）を持ってくる
    df_mart = pd.merge(df_mart, df_staffs[['staff_id', 'staff_name', 'store_id']], on='staff_id', how='left')

    # 処理③：店舗情報をくっつける（store_idを目印にする）
    # store_name（店名）と area（地域）を持ってくる
    df_mart = pd.merge(df_mart, df_stores[['store_id', 'store_name', 'area']], on='store_id', how='left')

    # 最後に、分析しやすいように列の順番を並べ替える
    columns_order = [
        'timestamp', 'store_name', 'area', 'staff_name', 
        'item_name', 'category', 'quantity', 'unit_price', 'amount'
    ]
    df_final = df_mart[columns_order]

    # 3層目「03_Curated」フォルダへ保存！
    df_final.to_csv(OUTPUT_PATH, index=False)
    
    print(f"--- 構築完了！ {OUTPUT_PATH} を確認してください ---")

if __name__ == "__main__":
    main()
