USE london_property;

-- Sales boroughs with no earnings match
WITH sales_boroughs AS (
    SELECT DISTINCT district
    FROM sales
)
SELECT s.district
FROM sales_boroughs s
LEFT JOIN (SELECT DISTINCT district FROM earnings) e
    ON s.district = e.district
WHERE e.district IS NULL;

-- Earnings boroughs with no sales match
SELECT DISTINCT e.district
FROM earnings e
LEFT JOIN (SELECT DISTINCT district FROM sales) s
    ON e.district = s.district
WHERE s.district IS NULL;