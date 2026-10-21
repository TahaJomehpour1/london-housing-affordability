USE london_property;
WITH ranked AS (
    SELECT district, home_type, period, price,
    ROW_NUMBER() OVER (PARTITION BY district, home_type, period ORDER BY price) AS rn,
    COUNT(*) OVER (PARTITION BY district, home_type, period) AS n
    FROM sales_v
),
medians AS (
    SELECT district, home_type, period, 
    MAX(n) AS sales,
    ROUND(AVG(price), 0) AS median_price
    FROM ranked
    WHERE rn IN (FLOOR((n+1) / 2), CEIL((n+1) / 2))
    GROUP BY district, home_type, period
),
pivoted AS (
    SELECT district,
    home_type,
    MAX(CASE WHEN period = '1. Pre-COVID' THEN median_price END) AS pre_covid,
    MAX(CASE WHEN period = '2. Pandemic' THEN median_price END) AS pandemic,
    MAX(CASE WHEN period = '3. Post-pandemic' THEN median_price END) AS post_pandemic,
    MIN(sales) AS smallest_period_sales
    FROM medians
    GROUP BY district, home_type
)
SELECT 
district, home_type, pre_covid, pandemic, post_pandemic,
ROUND(100*(post_pandemic / pre_covid - 1),1) AS pct_change,
smallest_period_sales
FROM pivoted 
-- fewer than 30 sales would make the boroughs median unreliable
WHERE smallest_period_sales >=30
ORDER BY home_type, pct_change DESC;