USE london_property;

CREATE OR REPLACE VIEW affordability_v AS
WITH ranked AS (
    SELECT district, home_type, sale_year, price,
        ROW_NUMBER() OVER (PARTITION BY district, home_type, sale_year ORDER BY price) AS rn,
        COUNT(*)     OVER (PARTITION BY district, home_type, sale_year)                AS n
    FROM sales_v
    -- no 2026 earnings yet, and 2026 sales are incomplete
    WHERE sale_year <= 2025
),
yearly AS (
    SELECT district, home_type, sale_year,
        MAX(n)               AS sales,
        ROUND(AVG(price), 0) AS median_price
    FROM ranked
    WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
    GROUP BY district, home_type, sale_year
)
SELECT
    y.district,
    y.home_type,
    y.sale_year,
    y.sales,
    y.median_price,
    e.median_earnings,
    ROUND(y.median_price / e.median_earnings, 1) AS price_to_earnings,
    -- most lenders cap loans at 4.5x income, so this is what a median earner would need as a deposit
    ROUND(y.median_price - 4.5 * e.median_earnings, 0) AS deposit_gap
FROM yearly y
LEFT JOIN earnings e
    ON  y.district  = e.district
    AND y.sale_year = e.year
WHERE y.sales >= 30;

-- Most affordable in 2025
-- City of London has no earnings data, so it has no ratio
SELECT *
FROM affordability_v
WHERE sale_year = 2025
  AND price_to_earnings IS NOT NULL
ORDER BY price_to_earnings ASC
LIMIT 15;

-- Change in affordability, 2018 vs 2025
SELECT
    a.district,
    a.home_type,
    a.price_to_earnings AS ratio_2018,
    b.price_to_earnings AS ratio_2025,
    ROUND(b.price_to_earnings - a.price_to_earnings, 1) AS ratio_change
FROM affordability_v a
JOIN affordability_v b
    ON  a.district  = b.district
    AND a.home_type = b.home_type
WHERE a.sale_year = 2018
  AND b.sale_year = 2025
  AND a.price_to_earnings IS NOT NULL
  AND b.price_to_earnings IS NOT NULL
ORDER BY ratio_change ASC;