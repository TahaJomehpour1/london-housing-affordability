USE london_property;

CREATE OR REPLACE VIEW sales_v AS
SELECT
    s.*,
    YEAR(s.date_of_transfer) AS sale_year,
    CASE
        WHEN YEAR(s.date_of_transfer) BETWEEN 2018 AND 2019 THEN '1. Pre-COVID'
        WHEN YEAR(s.date_of_transfer) BETWEEN 2020 AND 2021 THEN '2. Pandemic'
        WHEN YEAR(s.date_of_transfer) BETWEEN 2022 AND 2026 THEN '3. Post-pandemic'
        ELSE 'Out of range'
    END AS period
FROM sales AS s;

SELECT period, MIN(sale_year) AS first_yr, MAX(sale_year) AS last_yr,
       COUNT(*) AS sales
FROM sales_v
GROUP BY period
ORDER BY period;