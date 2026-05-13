import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

# 1. マスタデータの定義
staffs_data = [
    ["ST01", "看板娘", "聖母", 1.3],
    ["ST02", "ポコ", "スーパードジっ子", 0.5],
    ["ST03", "おっちゃん", "自称酒豪", 1.1]
]
m_staffs = pd.DataFrame(staffs_data, columns=['staff_id', 'staff_name', 'staff_type', 'base_eff'])

# 仕入れ単価マスタ（ポコの「神の目」で見つかる格安品）
procurement_master = {
    "Normal": 1000,  # 通常の仕入れ値
    "Poco_God": 500  # ポコが見つけてくる格安ルート
}

# 2. 実績データ生成（2026年1月〜6月）
start_date = datetime(2026, 1, 1)
end_date = datetime(2026, 6, 30)
current_date = start_date

fact_records = []

while current_date <= end_date:
    for _, staff in m_staffs.iterrows():
        sid = staff['staff_id']
        sname = staff['staff_name']
        eff = staff['base_eff']
        
        # --- ロジック適用 ---
        sales_amount = 20000 * eff * random.uniform(0.8, 1.2) # 基本売上
        procure_cost = procurement_master["Normal"] # 基本仕入れ値
        
        if sid == "ST03": # おっちゃん
            if current_date.weekday() == 0: # 月曜日
                if random.random() < 0.7: # 70%で二日酔い
                    sales_amount *= 0.5
                    
        elif sid == "ST02": # ポコ
            if random.random() < 0.2: # 20%で寝坊
                sales_amount = 0
            # ポコだけが使える格安仕入れルート（隠しバフ）
            procure_cost = procurement_master["Poco_God"]
            
        # 3. レコード作成（売上と仕入れをセットで）
        # 売上レコード
        fact_records.append([current_date, sid, sname, "Sales", round(sales_amount)])
        # 仕入れレコード（売上の分だけ仕入れたと仮定）
        if sales_amount > 0:
            fact_records.append([current_date, sid, sname, "Procurement", round(procure_cost)])
            
    current_date += timedelta(days=1)

# 4. CSV出力
df_fact = pd.DataFrame(fact_records, columns=['date', 'staff_id', 'staff_name', 'type', 'amount'])
df_fact.to_csv("fact_magical_logs.csv", index=False, encoding='utf_8_sig')
m_staffs.to_csv("m_staffs.csv", index=False, encoding='utf_8_sig')

print("✨ マジカル実績ログ(fact_magical_logs.csv)の錬成に成功しました！")
print("✨ スタッフマスタ(m_staffs.csv)も更新完了です。")
