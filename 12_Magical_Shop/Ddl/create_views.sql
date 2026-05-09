-- magical_shop.v_break_even_analysis source

CREATE OR REPLACE VIEW magical_shop.v_break_even_analysis
AS WITH monthly_metrics AS (
         SELECT to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text) AS month,
            sum(
                CASE
                    WHEN f_magical_logs.type::text ~~* 'sales'::text THEN f_magical_logs.amount
                    ELSE 0
                END) AS total_sales,
            sum(
                CASE
                    WHEN f_magical_logs.type::text ~~* 'procurement'::text THEN f_magical_logs.amount
                    ELSE 0
                END) AS total_cost,
                CASE
                    WHEN sum(
                    CASE
                        WHEN f_magical_logs.type::text ~~* 'sales'::text THEN f_magical_logs.amount
                        ELSE 0
                    END) = 0 THEN 0::double precision
                    ELSE (sum(
                    CASE
                        WHEN f_magical_logs.type::text ~~* 'sales'::text THEN f_magical_logs.amount
                        ELSE 0
                    END) - sum(
                    CASE
                        WHEN f_magical_logs.type::text ~~* 'procurement'::text THEN f_magical_logs.amount
                        ELSE 0
                    END))::double precision / sum(
                    CASE
                        WHEN f_magical_logs.type::text ~~* 'sales'::text THEN f_magical_logs.amount
                        ELSE 0
                    END)::double precision
                END AS contribution_margin_ratio,
            900000 + count(DISTINCT f_magical_logs.log_date) FILTER (WHERE f_magical_logs.staff_name::text ~~* 'poco'::text AND f_magical_logs.type::text ~~* 'sales'::text AND f_magical_logs.amount > 0) * 8000 AS total_fixed_costs
           FROM magical_shop.f_magical_logs
          GROUP BY (to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text))
        )
 SELECT month,
    round(total_sales::double precision) AS "実際の売上",
    round(total_fixed_costs::double precision) AS "全固定費",
    round(total_fixed_costs::double precision / NULLIF(contribution_margin_ratio, 0::double precision)) AS "損益分岐点売上",
    round(total_sales::double precision - total_fixed_costs::double precision / NULLIF(contribution_margin_ratio, 0::double precision)) AS "目標との差額"
   FROM monthly_metrics
  ORDER BY month;


-- magical_shop.v_operational_risk_indicator source

CREATE OR REPLACE VIEW magical_shop.v_operational_risk_indicator
AS WITH monthly_pnl_calc AS (
         SELECT to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text) AS month,
            sum(
                CASE
                    WHEN f_magical_logs.type::text ~~* 'Sales'::text THEN f_magical_logs.amount
                    ELSE 0
                END) - sum(
                CASE
                    WHEN f_magical_logs.type::text ~~* 'Procurement'::text THEN f_magical_logs.amount
                    ELSE 0
                END) - 900000 - count(DISTINCT f_magical_logs.log_date) FILTER (WHERE f_magical_logs.staff_name::text ~~* 'Poco'::text AND f_magical_logs.type::text ~~* 'Sales'::text AND f_magical_logs.amount > 0) * 8000 AS real_monthly_profit
           FROM magical_shop.f_magical_logs
          GROUP BY (to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text))
        ), average_burn AS (
         SELECT avg(monthly_pnl_calc.real_monthly_profit) AS avg_profit
           FROM monthly_pnl_calc
        )
 SELECT 1000000 AS "手元資金（仮）",
    round(avg_profit) AS "平均月間収支（今度こそ真実）",
        CASE
            WHEN avg_profit >= 0::numeric THEN '奇跡の生存（本当に黒字？）'::text
            ELSE round(1000000::numeric / abs(avg_profit) * 30::numeric)::text
        END AS "残り日数",
        CASE
            WHEN avg_profit >= 0::numeric THEN NULL::date
            ELSE CURRENT_DATE + round(1000000::numeric / abs(avg_profit) * 30::numeric)::integer
        END AS "運命の日"
   FROM average_burn;


-- magical_shop.v_monthly_pnl_trend source

CREATE OR REPLACE VIEW magical_shop.v_monthly_pnl_trend
AS WITH staff_performance AS (
         SELECT to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text) AS target_month,
            count(DISTINCT f_magical_logs.log_date) FILTER (WHERE f_magical_logs.staff_name::text ~~* 'poco'::text AND f_magical_logs.type::text ~~* 'sales'::text AND f_magical_logs.amount > 0) AS poco_work_days
           FROM magical_shop.f_magical_logs
          GROUP BY (to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text))
        ), monthly_raw AS (
         SELECT to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text) AS target_month,
            sum(
                CASE
                    WHEN f_magical_logs.type::text ~~* 'sales'::text THEN f_magical_logs.amount
                    ELSE 0
                END) AS total_sales,
            sum(
                CASE
                    WHEN f_magical_logs.type::text ~~* 'procurement'::text THEN f_magical_logs.amount
                    ELSE 0
                END) AS total_cost
           FROM magical_shop.f_magical_logs
          GROUP BY (to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text))
        )
 SELECT r.target_month,
    r.total_sales AS "売上",
    r.total_cost AS "原価",
    r.total_sales - r.total_cost AS "売上総利益",
    250000 AS "社長生活費",
    250000 + 200000 + COALESCE(s.poco_work_days, 0::bigint) * 8 * 1000 AS "スタッフ人件費",
    150000 AS "家賃・光熱費",
    50000 AS "雑費",
    r.total_sales - r.total_cost - 250000 - (250000 + 200000 + COALESCE(s.poco_work_days, 0::bigint) * 8 * 1000) - 150000 - 50000 AS "営業利益"
   FROM monthly_raw r
     LEFT JOIN staff_performance s ON r.target_month = s.target_month
  ORDER BY r.target_month;


-- magical_shop.v_resource_performance_gap source

CREATE OR REPLACE VIEW magical_shop.v_resource_performance_gap
AS WITH daily_summary AS (
         SELECT f_magical_logs.log_date,
            EXTRACT(isodow FROM f_magical_logs.log_date) AS dow_num,
            to_char(f_magical_logs.log_date::timestamp with time zone, 'Day'::text) AS day_name,
            max(
                CASE
                    WHEN TRIM(BOTH FROM lower(f_magical_logs.staff_name::text)) = 'poco'::text AND f_magical_logs.amount > 0 THEN 1
                    ELSE 0
                END) AS is_poco_present,
            sum(f_magical_logs.amount) AS daily_total_sales,
            sum(
                CASE
                    WHEN TRIM(BOTH FROM lower(f_magical_logs.staff_name::text)) = ANY (ARRAY['lina'::text, 'occhan'::text]) THEN f_magical_logs.amount
                    ELSE 0
                END) AS duo_sales
           FROM magical_shop.f_magical_logs
          WHERE f_magical_logs.type::text = 'Sales'::text
          GROUP BY f_magical_logs.log_date, (EXTRACT(isodow FROM f_magical_logs.log_date)), (to_char(f_magical_logs.log_date::timestamp with time zone, 'Day'::text))
        )
 SELECT day_name AS "曜日",
    count(*) AS "総サンプル日数",
    round(avg(
        CASE
            WHEN is_poco_present = 1 THEN daily_total_sales
            ELSE NULL::bigint
        END)) AS "ポコ出勤時_店平均売上",
    round(avg(
        CASE
            WHEN is_poco_present = 0 THEN duo_sales
            ELSE NULL::bigint
        END)) AS "ポコ不在時_二人平均売上",
    round(avg(
        CASE
            WHEN is_poco_present = 1 THEN daily_total_sales
            ELSE NULL::bigint
        END)) - round(avg(
        CASE
            WHEN is_poco_present = 0 THEN duo_sales
            ELSE NULL::bigint
        END)) AS "ポコ不在による売上減少額",
    round(avg(daily_total_sales)) AS "曜日別全体平均"
   FROM daily_summary
  GROUP BY dow_num, day_name
  ORDER BY dow_num;


-- magical_shop.v_staff_net_profit_contribution source

CREATE OR REPLACE VIEW magical_shop.v_staff_net_profit_contribution
AS WITH monthly_raw_data AS (
         SELECT to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text) AS month,
            f_magical_logs.staff_name,
            sum(
                CASE
                    WHEN f_magical_logs.type::text ~~* 'sales'::text THEN f_magical_logs.amount
                    ELSE 0
                END) AS total_sales,
            sum(
                CASE
                    WHEN f_magical_logs.type::text ~~* 'procurement'::text THEN f_magical_logs.amount
                    ELSE 0
                END) AS total_procurement
           FROM magical_shop.f_magical_logs
          WHERE f_magical_logs.staff_name IS NOT NULL
          GROUP BY (to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text)), f_magical_logs.staff_name
        )
 SELECT month,
    staff_name,
    total_sales AS "売上高",
    total_procurement AS "実際仕入れ高",
    total_sales - total_procurement AS "個人粗利",
        CASE
            WHEN total_sales = 0 THEN 0::numeric
            ELSE round((total_procurement::double precision / total_sales::double precision * 100::double precision)::numeric, 1)
        END AS "実際原価率％",
        CASE
            WHEN staff_name::text ~~* 'lina'::text THEN 250000::bigint
            WHEN staff_name::text ~~* 'occhan'::text THEN 200000::bigint
            WHEN staff_name::text ~~* 'poco'::text THEN ( SELECT count(DISTINCT f_magical_logs.log_date) * 8000
               FROM magical_shop.f_magical_logs
              WHERE f_magical_logs.staff_name::text ~~* 'poco'::text AND f_magical_logs.type::text ~~* 'sales'::text AND f_magical_logs.amount > 0 AND to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text) = monthly_raw_data.month)
            ELSE 0::bigint
        END AS "人件費",
    total_sales - total_procurement -
        CASE
            WHEN staff_name::text ~~* 'lina'::text THEN 250000::bigint
            WHEN staff_name::text ~~* 'occhan'::text THEN 200000::bigint
            WHEN staff_name::text ~~* 'poco'::text THEN ( SELECT count(DISTINCT f_magical_logs.log_date) * 8000
               FROM magical_shop.f_magical_logs
              WHERE f_magical_logs.staff_name::text ~~* 'poco'::text AND f_magical_logs.type::text ~~* 'sales'::text AND f_magical_logs.amount > 0 AND to_char(f_magical_logs.log_date::timestamp with time zone, 'YYYY-MM'::text) = monthly_raw_data.month)
            ELSE 0::bigint
        END AS "真の利益貢献額"
   FROM monthly_raw_data
  WHERE total_sales > 0 OR total_procurement > 0;