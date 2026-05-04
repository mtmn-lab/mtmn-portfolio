import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

# 1. マスタの読み込み（パスの修正済み）
try:
    # Scriptsから見て一つ上のMasterフォルダ内のCSVを指定
    m_staffs = pd.read_csv("../Master/m_staffs.csv")
    print("✅ 最新のスタッフマスタを読み込みました。")
except FileNotFoundError:
    print("❌ m_staffs.csv が見つかりません。パスを確認してください。")
    exit()

# 2. 実績データ生成
start_date = datetime(2026, 1, 1)
end_date = datetime(2026, 6, 30)
current_date = start_date

fact_records = []

while current_date <= end_date:
    # 日曜定休
    if current_date.weekday() == 6: 
        current_date += timedelta(days=1)
        continue

    for _, staff in m_staffs.iterrows():
        sid = staff['staff_id']
        sname = staff['staff_name']
        eff = staff['base_efficiency']
        p_skill = staff['procurement_skill']
        
        # 基本の売上計算
        base_market_sales = 25000
        sales_amount = base_market_sales * eff * random.uniform(0.8, 1.2)
        
        # 基本の原価率計算
        cost_ratio = 0.4 * p_skill * random.uniform(0.9, 1.1)
        
        # --- 【修正】個別ロジック：おっちゃんの二日酔い強化 ---
        if sid == "ST03": # Occhan
            # 月曜日（weekday == 0）かつ 70%の確率で発動
            if current_date.weekday() == 0:
                if random.random() < 0.7:
                    # 50%に落とすだけでは弱かったので、20〜40%まで叩き落とします
                    sales_amount *= random.uniform(0.2, 0.4)
                    
        # --- 個別ロジック：ポコのまだら欠勤 ---
        elif sid == "ST02": # Poco
            if random.random() < 0.18:
                sales_amount = 0
        
        # --- 【修正】カラム名を log_date に変更 ---
        fact_records.append([current_date.strftime('%Y-%m-%d'), sid, sname, "Sales", round(sales_amount)])
        
        if sales_amount > 0:
            procure_cost = sales_amount * cost_ratio
            fact_records.append([current_date.strftime('%Y-%m-%d'), sid, sname, "Procurement", round(procure_cost)])
            
    current_date += timedelta(days=1)

# CSV出力
# ここでもカラム名を log_date にして保存
df_fact = pd.DataFrame(fact_records, columns=['log_date', 'staff_id', 'staff_name', 'type', 'amount'])
df_fact.to_csv("fact_magical_logs.csv", index=False, encoding='utf_8_sig')

print("✨ 真・暗黒期ログ(おっちゃん弱体化・log_date版)の錬成に成功しました！")
