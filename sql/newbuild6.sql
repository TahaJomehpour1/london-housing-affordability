USE london_property;

WITH th AS (
    SELECT sale_year, old_new, price
    FROM sales_v
    WHERE district = 'TOWER HAMLETS'
      AND home_type = 'Flat'
      AND sale_year <= 2025
),
ranked AS (
    SELECT sale_year, old_new, price,
        ROW_NUMBER() OVER (PARTITION BY sale_year, old_new ORDER BY price) AS rn,
        COUNT(*) OVER (PARTITION BY sale_year, old_new) AS n
    FROM th
),
medians AS (
    SELECT sale_year, old_new,
        MAX(n) AS sales,
        ROUND(AVG(price), 0) AS median_price
    FROM ranked
    WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
    GROUP BY sale_year, old_new
)
SELECT
    sale_year,
    SUM(sales) AS total_sales,
    MAX(CASE WHEN old_new = 'Y' THEN sales END) AS new_sales,
    ROUND(100 * MAX(CASE WHEN old_new = 'Y' THEN sales END) / SUM(sales), 1) AS new_share_pct,
    MAX(CASE WHEN old_new = 'Y' THEN median_price END) AS new_median,
    MAX(CASE WHEN old_new = 'N' THEN median_price END) AS existing_median
FROM medians
GROUP BY sale_year
ORDER BY sale_year;