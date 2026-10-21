USE london_property;

WITH ranked AS ( 
    SELECT period, price,
    ROW_NUMBER() OVER (PARTITION BY period ORDER BY price) AS rn,
    COUNT(*) OVER(PARTITION BY period) AS n
    FROM sales_v
)
SELECT period, MAX(n) AS sales,
AVG(price) AS median_price
FROM ranked
WHERE rn IN (FLOOR((n+1) / 2), CEIL((n+1) / 2))
GROUP BY period
ORDER BY period;