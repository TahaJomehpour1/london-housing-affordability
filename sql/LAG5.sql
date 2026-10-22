USE london_property;

WITH ranked AS (
    SELECT district, home_type, sale_year, price,
        ROW_NUMBER() OVER (PARTITION BY district, home_type, sale_year ORDER BY price) AS rn,
        COUNT(*) OVER (PARTITION BY district, home_type, sale_year) AS n
    FROM sales_v
    -- 2026 is incomplete because of registration lag, so comparing it to a full year would mislead
    WHERE sale_year <= 2025
),
yearly AS (
    SELECT district, home_type, sale_year,
        MAX(n) AS sales,
        ROUND(AVG(price), 0) AS median_price
    FROM ranked
    WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
    GROUP BY district, home_type, sale_year
),
growth AS (
    SELECT district, home_type, sale_year, sales, median_price,
        LAG(median_price) OVER w AS prev_median,
        LAG(sales) OVER w AS prev_sales
    FROM yearly
    WINDOW w AS (PARTITION BY district, home_type ORDER BY sale_year)
)
SELECT district, home_type, sale_year, sales, median_price, prev_median,
    ROUND(100 * (median_price / prev_median - 1), 1) AS yoy_pct
FROM growth
-- both years need 30+ sales, otherwise the change is mostly noise
WHERE sales >= 30 AND prev_sales >= 30
ORDER BY district, home_type, sale_year;